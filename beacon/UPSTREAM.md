# Upstream Synchronization

## Git Remotes

- `origin`: `beacon-observability/beacon-php-instrumentation`, the Beacon downstream repository.
- `upstream`: `open-telemetry/opentelemetry-php-instrumentation`, the official read-only source.

## Synchronization Steps

1. Create a separate synchronization branch from `main` and fetch tags and commits from `upstream`.
2. Verify the target official release, full commit hash, supported PHP versions, extension ABI changes, and security fixes.
3. Merge the target official commit without overwriting directories or rewriting history.
4. Preserve and revalidate the Beacon distribution identity, project checks, artifact builds, and component integration.
5. Update the official tag, commit, and extension version in `beacon/upstream.lock.json`.
6. Run project checks, PHPT tests, cross-platform builds, and `beacon-php` auto-instrumentation integration tests.
7. Merge through a pull request; never push directly to `upstream`.
