# Beacon PHP Instrumentation Project Guide

This repository maintains the native hook extension required for PHP auto-instrumentation. [`beacon-php`](https://github.com/beacon-observability/beacon-php) handles the Agent, dependency orchestration, and diagnostics. Component-level span creation logic comes directly from official OpenTelemetry Composer packages.

## Maintenance Model

- Official upstream source: `open-telemetry/opentelemetry-php-instrumentation`.
- Beacon mainline: a downstream repository built on the complete official history, rather than a GitHub fork.

The initial development branch uses official version `1.4.2` as its code baseline. Cross-platform builds, validation, and examples have been adapted to the current official code.

## Usage Boundaries

- Manual instrumentation: applications use the OpenTelemetry PHP API/SDK directly; this extension is not required.
- Auto-instrumentation: this extension provides hooks, and Composer instrumentation packages create spans.
- Beacon distribution identity: the extension retains the upstream module name `opentelemetry` and compatible version, and exposes the `OpenTelemetry\\Instrumentation\\BEACON_DISTRIBUTION` constant and distribution information in phpinfo.

Official artifacts are published through [GitHub Releases](https://github.com/beacon-observability/beacon-php-instrumentation/releases). Binary extensions must exactly match the PHP version, thread-safety mode, operating system, and architecture.
