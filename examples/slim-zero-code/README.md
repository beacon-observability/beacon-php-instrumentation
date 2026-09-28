# Beacon PHP Slim zero-code example

This example verifies zero-code instrumentation for a Slim server route and a
PSR-18 outbound HTTP request.

## Requirements

- PHP 8.2, 8.3, or 8.4
- Composer
- The matching Beacon `opentelemetry` extension candidate from this repository
- An OTLP/HTTP receiver

## Install

```shell
composer install
```

## Run

The following configuration sends traces to a DataKit instance on the same
host:

```shell
export OTEL_PHP_AUTOLOAD_ENABLED=true
export OTEL_SERVICE_NAME=php-slim-zero-code-demo
export OTEL_SERVICE_VERSION=1.0.0
export OTEL_RESOURCE_ATTRIBUTES=deployment.environment.name=test
export OTEL_TRACES_EXPORTER=otlp
export OTEL_METRICS_EXPORTER=none
export OTEL_LOGS_EXPORTER=none
export OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
export OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=http://127.0.0.1:9529/otel/v1/traces
export OTEL_PROPAGATORS=baggage,tracecontext

php -S 0.0.0.0:8080 -t public
```

## Verify

Generate a server span:

```shell
curl http://127.0.0.1:8080/
```

Generate a server span and a PSR-18 client span:

```shell
curl http://127.0.0.1:8080/upstream
```

When using DataKit, confirm that its built-in metrics contain successful trace
requests:

```shell
curl -s http://127.0.0.1:9529/metrics \
  | grep 'datakit_http_api_total{api="/otel/v1/traces",method="POST",status="OK"}'
```

## Automated DataKit verification

On a Linux Docker host with DataKit listening on local HTTP port `9529`, run:

```shell
./verify-http.sh
```

The script downloads and verifies the released Beacon extension, installs this
example in a temporary directory, runs PHP in an isolated container, and sends
a request to the unmodified application. It passes only when DataKit's
`/metrics` endpoint reports both a new successful `POST /otel/v1/traces` and a
positive received-byte delta. No manual span creation is used.

The defaults can be overridden when needed:

```shell
BEACON_VERSION=1.0.0 \
PHP_VERSION=8.4 \
APP_PORT=18082 \
OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=http://127.0.0.1:9529/otel/v1/traces \
DATAKIT_METRICS_URL=http://127.0.0.1:9529/metrics \
./verify-http.sh
```
