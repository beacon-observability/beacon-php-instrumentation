#!/usr/bin/env bash

set -euo pipefail

example_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
beacon_version="${BEACON_VERSION:-1.0.0}"
php_version="${PHP_VERSION:-8.4}"
app_port="${APP_PORT:-18082}"
otlp_traces_endpoint="${OTEL_EXPORTER_OTLP_TRACES_ENDPOINT:-http://127.0.0.1:9529/otel/v1/traces}"
datakit_metrics_url="${DATAKIT_METRICS_URL:-http://127.0.0.1:9529/metrics}"
container_name="beacon-zero-code-e2e-$$"
work_dir="$(mktemp -d "${TMPDIR:-/tmp}/beacon-zero-code-e2e.XXXXXX")"
asset="beacon-php-instrumentation-${beacon_version}-php${php_version}-nts-linux-x86_64.tar.gz"
release_url="https://github.com/beacon-observability/beacon-php-instrumentation/releases/download/v${beacon_version}"

cleanup() {
  docker rm -f "${container_name}" >/dev/null 2>&1 || true
  rm -rf -- "${work_dir}"
}
trap cleanup EXIT

for command_name in curl docker sha256sum tar; do
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "Required command not found: ${command_name}" >&2
    exit 1
  fi
done

metric_value() {
  local metric_name="$1"
  curl --fail --silent --show-error "${datakit_metrics_url}" |
    awk -v metric_name="${metric_name}" \
      '$1 == metric_name "{api=\"/otel/v1/traces\",method=\"POST\",status=\"OK\"}" {print int($2)}'
}

curl --fail --location --retry 3 --silent --show-error --output "${work_dir}/${asset}" "${release_url}/${asset}"
curl --fail --location --retry 3 --silent --show-error --output "${work_dir}/SHA256SUMS" "${release_url}/SHA256SUMS"
(
  cd "${work_dir}"
  grep -F "  ${asset}" SHA256SUMS | sha256sum --check
  tar -xzf "${asset}"
)

cp -a "${example_dir}" "${work_dir}/app"
docker run --rm \
  --user "$(id -u):$(id -g)" \
  --env HOME=/tmp \
  --env COMPOSER_HOME=/tmp/composer \
  --volume "${work_dir}/app:/app" \
  --workdir /app \
  composer:2 install --no-interaction --prefer-dist --no-progress --quiet --ignore-platform-req=ext-opentelemetry

extension_path="${work_dir}/${asset%.tar.gz}/opentelemetry.so"
docker run --rm \
  --volume "${extension_path}:/opt/opentelemetry.so:ro" \
  "php:${php_version}-cli" \
  php -d extension=/opt/opentelemetry.so \
    -r 'exit(OpenTelemetry\Instrumentation\BEACON_DISTRIBUTION === "Beacon" ? 0 : 1);'

docker run --detach --name "${container_name}" --network host \
  --volume "${work_dir}/app:/app:ro" \
  --volume "${extension_path}:/opt/opentelemetry.so:ro" \
  --workdir /app \
  --env OTEL_PHP_AUTOLOAD_ENABLED=true \
  --env OTEL_SERVICE_NAME=beacon-zero-code-e2e \
  --env OTEL_SERVICE_VERSION="${beacon_version}" \
  --env OTEL_RESOURCE_ATTRIBUTES=deployment.environment.name=test \
  --env OTEL_TRACES_EXPORTER=otlp \
  --env OTEL_METRICS_EXPORTER=none \
  --env OTEL_LOGS_EXPORTER=none \
  --env OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf \
  --env OTEL_EXPORTER_OTLP_TRACES_ENDPOINT="${otlp_traces_endpoint}" \
  --env OTEL_PROPAGATORS=baggage,tracecontext \
  "php:${php_version}-cli" \
  php -d extension=/opt/opentelemetry.so -S "127.0.0.1:${app_port}" -t public >/dev/null

for attempt in $(seq 1 30); do
  if curl --fail --silent "http://127.0.0.1:${app_port}/" >/dev/null; then
    break
  fi
  if [[ "${attempt}" -eq 30 ]]; then
    docker logs "${container_name}" >&2
    echo "Slim example did not become ready." >&2
    exit 1
  fi
  sleep 1
done

before_count="$(metric_value datakit_http_api_total)"
before_bytes="$(metric_value datakit_http_api_req_size_bytes_sum)"
response="$(curl --fail --silent --show-error "http://127.0.0.1:${app_port}/")"

for attempt in $(seq 1 20); do
  after_count="$(metric_value datakit_http_api_total)"
  after_bytes="$(metric_value datakit_http_api_req_size_bytes_sum)"
  if ((after_count > before_count && after_bytes > before_bytes)); then
    break
  fi
  if [[ "${attempt}" -eq 20 ]]; then
    docker logs "${container_name}" >&2
    echo "DataKit did not record a successful OTLP/HTTP trace request." >&2
    exit 1
  fi
  sleep 1
done

printf 'response=%s\n' "${response}"
printf 'otlp_http_success_count_delta=%d\n' "$((after_count - before_count))"
printf 'otlp_http_received_byte_delta=%d\n' "$((after_bytes - before_bytes))"
echo "Beacon PHP zero-code OTLP/HTTP verification passed."
