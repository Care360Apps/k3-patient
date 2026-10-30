#!/usr/bin/env python3
"""Temporary GitHub CI compatibility fix for google_api_headers 1.6.0.

Only modifies the ephemeral GitHub runner pub-cache copy. Does not modify K3
application sources or dependency locks. Fail closed if upstream layout differs.
Long term: upgrade/remove the legacy dependency after integration testing.
"""
import os
from pathlib import Path
import re
import sys

cache = Path(os.environ.get("PUB_CACHE") or (Path.home() / ".pub-cache"))
root = cache / "hosted" / "pub.dev" / "google_api_headers-1.6.0" / "android"
gradle = root / "build.gradle"
manifest = root / "src" / "main" / "AndroidManifest.xml"
if not gradle.is_file() or not manifest.is_file():
    sys.exit("Expected google_api_headers 1.6.0 Android plugin files not found")

source = gradle.read_text(encoding="utf-8")
xml = manifest.read_text(encoding="utf-8")

# Checked against google_api_headers upstream tag v1.6.0, not guessed.
group = "group 'io.github.zeshuaro.google_api_headers'"
if group not in source:
    sys.exit("Unexpected google_api_headers Gradle group; manual review required")
if re.search(r"(?m)^\s*namespace\s", source):
    sys.exit("Namespace already defined; do not patch automatically")
gradle_pattern = re.compile(r"(?m)^(android\s*\{)$")
new_source, n_gradle = gradle_pattern.subn(
    lambda m: m.group(1) + "\n    namespace 'io.github.zeshuaro.google_api_headers'",
    source,
)
manifest_pattern = re.compile(
    r"""(?s)^\s*<manifest\s+package=["']io\.github\.zeshuaro\.google_api_headers["']\s*/>\s*$"""
)
new_xml, n_xml = manifest_pattern.subn(
    '<manifest xmlns:android="http://schemas.android.com/apk/res/android" />\n', xml
)
if n_gradle != 1 or n_xml != 1:
    sys.exit(
        f"Unexpected plugin layout: gradle declarations={n_gradle}, "
        f"manifest package declarations={n_xml}. No files changed."
    )

gradle.write_text(new_source, encoding="utf-8")
manifest.write_text(new_xml, encoding="utf-8")
print("CI-ONLY: added Android namespace for google_api_headers 1.6.0")
print("CI-ONLY: removed legacy AndroidManifest package attribute")
print("K3 app and production dependencies remain unchanged")
