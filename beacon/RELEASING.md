# Release Preparation

The Beacon product version is independent of the official extension version: the product version identifies Beacon artifacts, while the official extension version identifies the compatible code baseline used.

## Before the First Release

1. Change `BEACON_VERSION` in `beacon/version.properties` from a development version to a release version, and update `beacon/upstream.lock.json` to match.
2. Confirm that the extension versions in `ext/php_opentelemetry.h` and `ext/package.xml` match the locked official baseline, and that the distribution is `Beacon`.
3. Run `python3 beacon/scripts/check-project.py` and the complete PHPT suite.
4. Validate representative Linux, Windows, and macOS environments. Record the PHP version, thread-safety mode, architecture, and known limitations.
5. Generate candidate Linux and Windows binaries and PECL-compatible source artifacts from the same commit. Verify filenames, module information, and SHA-256 checksums.
6. Run integration tests with a pinned `beacon-php` candidate package to verify auto-instrumentation and the data path to the actual receiver. Also confirm that manual instrumentation works without loading the extension.
7. Create a signed tag `v<BEACON_VERSION>` matching the product version. The workflow creates only a draft release; publish it after manual review.
8. Download the artifacts again from the public release and revalidate installation, then update the pinned version reference in the product repository.

Published tags and artifacts must not be overwritten; publish fixes as a new version. Versions with a `-dev` suffix cannot trigger an official release.

## CI build environments

The Windows matrix uses the maintained official `php/php-windows-builder`
extension action, pinned to a full commit. It selects PHP's matching compiler,
builds the checked-out extension, and runs PHPT tests before packaging. Beacon
candidate archives contain the DLL extracted from that tested package. PHP
8.2/8.3 use the `vs16` asset label; PHP 8.4 uses `vs17`, independently of the
runner's default Visual Studio installation. The macOS and Linux PHP setup
action is also pinned; macOS arm64 can use its supported cached PHP builds.
Branch and PR artifacts remain candidates, never official installation sources.
