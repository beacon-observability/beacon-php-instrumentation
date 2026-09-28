#!/usr/bin/env python3

import json
import os
from pathlib import Path
import re
import subprocess
import sys
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[2]
LOCK_FILE = ROOT / "beacon" / "upstream.lock.json"
PROPERTIES_FILE = ROOT / "beacon" / "version.properties"
HEADER_FILE = ROOT / "ext" / "php_opentelemetry.h"
PACKAGE_FILE = ROOT / "ext" / "package.xml"


def fail(message: str) -> None:
    raise RuntimeError(message)


def load_properties() -> dict[str, str]:
    properties: dict[str, str] = {}
    for raw_line in PROPERTIES_FILE.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            fail(f"Invalid property line: {raw_line}")
        key, value = line.split("=", 1)
        properties[key] = value
    return properties


def require_match(pattern: str, text: str, label: str) -> str:
    match = re.search(pattern, text)
    if not match:
        fail(f"Unable to find {label}")
    return match.group(1)


def git_is_ancestor(commit: str) -> bool:
    result = subprocess.run(
        ["git", "merge-base", "--is-ancestor", commit, "HEAD"],
        cwd=ROOT,
        check=False,
    )
    return result.returncode == 0


def main() -> int:
    lock = json.loads(LOCK_FILE.read_text(encoding="utf-8"))
    properties = load_properties()

    if lock.get("schema_version") != 1:
        fail("Unsupported upstream lock schema")

    beacon_version = properties.get("BEACON_VERSION", "")
    upstream_version = properties.get("UPSTREAM_EXTENSION_VERSION", "")
    if not re.fullmatch(r"\d+\.\d+\.\d+(?:-dev)?", beacon_version):
        fail(f"Invalid BEACON_VERSION: {beacon_version}")
    if not re.fullmatch(r"\d+\.\d+\.\d+", upstream_version):
        fail(f"Invalid UPSTREAM_EXTENSION_VERSION: {upstream_version}")
    if lock.get("beacon_version") != beacon_version:
        fail("Beacon version differs between version.properties and upstream.lock.json")
    if lock.get("upstream", {}).get("extension_version") != upstream_version:
        fail("Upstream extension version differs between version.properties and upstream.lock.json")

    header = HEADER_FILE.read_text(encoding="utf-8")
    header_version = require_match(
        r'#define\s+PHP_OPENTELEMETRY_VERSION\s+"([^"]+)"',
        header,
        "PHP_OPENTELEMETRY_VERSION",
    )
    distribution = require_match(
        r'#define\s+PHP_OPENTELEMETRY_DISTRIBUTION\s+"([^"]+)"',
        header,
        "PHP_OPENTELEMETRY_DISTRIBUTION",
    )
    if header_version != upstream_version:
        fail("Extension header version does not match the locked upstream baseline")
    if distribution != lock.get("distribution") or distribution != "Beacon":
        fail("Extension distribution must be Beacon")

    namespace = {"pkg": "http://pear.php.net/dtd/package-2.0"}
    package_root = ET.parse(PACKAGE_FILE).getroot()
    package_version = package_root.findtext("pkg:version/pkg:release", namespaces=namespace)
    if package_version != upstream_version:
        fail("package.xml release does not match the locked upstream baseline")
    description = package_root.findtext("pkg:description", namespaces=namespace) or ""
    if "beacon-observability/beacon-php-instrumentation" not in description:
        fail("package.xml does not identify the Beacon repository")

    workflows = sorted(path.name for path in (ROOT / ".github" / "workflows").glob("*.yml"))
    if workflows != ["beacon-ci.yml"]:
        fail(f"Expected exactly one Beacon workflow, found: {workflows}")

    for source in ("upstream", "legacy"):
        commit = lock.get(source, {}).get("commit", "")
        if not re.fullmatch(r"[0-9a-f]{40}", commit):
            fail(f"Invalid {source} commit: {commit}")
        if not git_is_ancestor(commit):
            fail(f"Locked {source} commit is not an ancestor of HEAD: {commit}")

    github_ref_type = os.environ.get("GITHUB_REF_TYPE")
    github_ref_name = os.environ.get("GITHUB_REF_NAME", "")
    if github_ref_type == "tag":
        if beacon_version.endswith("-dev"):
            fail("Development versions cannot be released")
        if github_ref_name != f"v{beacon_version}":
            fail(f"Tag {github_ref_name} does not match v{beacon_version}")

    print(
        "Beacon PHP Instrumentation metadata is valid "
        f"(beacon={beacon_version}, upstream={upstream_version}, distribution={distribution})."
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, json.JSONDecodeError, ET.ParseError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        raise SystemExit(1)
