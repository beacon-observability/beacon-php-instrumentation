# Beacon PHP Instrumentation

Beacon PHP Instrumentation is the native auto-instrumentation extension used by Beacon PHP, maintained as a downstream of [OpenTelemetry PHP Instrumentation](https://github.com/open-telemetry/opentelemetry-php-instrumentation).

This repository is a downstream repository containing the complete source tree, rather than a GitHub fork. It preserves the official Git history and incorporates existing experience with cross-platform builds and artifacts.

## Repository Scope

- Provide the native `opentelemetry` extension for hooking PHP runtime functions and methods.
- Build Linux and Windows binaries and PECL-compatible source artifacts.
- Track a pinned official extension baseline and maintain the necessary Beacon-specific downstream changes.
- Keep framework, database, and client span creation logic in official OpenTelemetry Composer instrumentation packages. [`beacon-php`](https://github.com/beacon-observability/beacon-php) handles Agent orchestration and installs those packages directly.

Manual instrumentation requires only the OpenTelemetry PHP API/SDK and does not require loading this extension. Auto-instrumentation requires this extension, the `beacon-php` Agent package, and the official Composer instrumentation packages for the components used by the application. Beacon does not maintain a complete downstream mirror of PHP Contrib.

## Current Baseline

- Official extension version: `1.4.2`
- Beacon version: `1.0.1`
- PHP versions covered by validation and binary artifacts: `8.2`, `8.3`, and `8.4`

| Platform | Architecture | PHP Mode | Release Artifacts |
| --- | --- | --- | --- |
| Linux | x86_64, arm64 | NTS | PHP 8.2, 8.3, 8.4 |
| macOS | arm64 | NTS | PHP 8.2, 8.3, 8.4 |
| Windows | x86_64 | NTS, TS | PHP 8.2, 8.3, 8.4 |

For other platforms or combinations, build from the PECL-compatible source package. Binary extensions must match the PHP major and minor version, thread-safety mode, operating system, and CPU architecture.

See [`beacon/upstream.lock.json`](beacon/upstream.lock.json) for the exact official baseline commit.

## Development Validation

```shell
python3 beacon/scripts/check-project.py
cd ext
phpize
./configure
make
make test TESTS=--show-diff
```

After loading the extension, verify its distribution:

```shell
php --ri opentelemetry
php -r 'echo constant("OpenTelemetry\\Instrumentation\\BEACON_DISTRIBUTION"), PHP_EOL;'
```

Official artifacts are available from [GitHub Releases](https://github.com/beacon-observability/beacon-php-instrumentation/releases). Before installing a binary, match the PHP version, thread-safety mode, operating system, and architecture, and verify it against the `SHA256SUMS` file provided with the release.

## Development Documentation

- [Project Scope](beacon/README.md)
- [Upstream Synchronization](beacon/UPSTREAM.md)
- [Release Preparation](beacon/RELEASING.md)

## Beacon Contributors

<a href="https://github.com/lrwh"><img src="https://github.com/lrwh.png" width="64" height="64" alt="lrwh"><br>lrwh</a>

## License

Apache License 2.0. See [LICENSE](LICENSE) for details.
