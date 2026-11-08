# Beacon PHP Instrumentation Project Guide

This repository maintains the native hook extension required for PHP auto-instrumentation. [`beacon-php`](https://github.com/beacon-observability/beacon-php) handles the Agent, dependency orchestration, and diagnostics. Component-level span creation logic comes directly from official OpenTelemetry Composer packages.

## Maintenance Model

- Official upstream source: `open-telemetry/opentelemetry-php-instrumentation`.
- Beacon mainline: a downstream repository built on the complete official history, rather than a GitHub fork.

Beacon product 1.1.0 adopts official extension 1.5.0 at commit
`dd0e147a80d0aeac15c95ec119b146c0b2bc3285`. The native module retains the
OpenTelemetry hook API and module identity, with Beacon distribution metadata.
Product and upstream extension versions are independently pinned in
`beacon/upstream.lock.json`.

## Usage Boundaries

- Manual instrumentation: applications use the OpenTelemetry PHP API/SDK directly; this extension is not required.
- Auto-instrumentation: this extension provides hooks, and Composer instrumentation packages create spans.
- Beacon distribution identity: the extension retains the upstream module name `opentelemetry` and compatible version, and exposes the `OpenTelemetry\\Instrumentation\\BEACON_DISTRIBUTION` constant and distribution information in phpinfo.

Official artifacts are published through [GitHub Releases](https://github.com/beacon-observability/beacon-php-instrumentation/releases). Binary extensions must exactly match the PHP version, thread-safety mode, operating system, and architecture.
