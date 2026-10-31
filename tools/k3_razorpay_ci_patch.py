#!/usr/bin/env python3
"""Temporary AGP namespace migration for Razorpay Flutter 1.3.6 in sandbox CI.

Matches tagged upstream Razorpay Flutter v1.3.6. Modifies ONLY pub-cache on
a disposable runner; app sources, version lock and live payment code untouched.
Fail closed if plugin metadata/layout changes. NOT a production migration.
"""
import os
from pathlib import Path
import re
import sys

cache = Path(os.environ.get("PUB_CACHE") or (Path.home() / ".pub-cache"))
plugin = cache / "hosted" / "pub.dev" / "razorpay_flutter-1.3.6" / "android"
gradle = plugin / "build.gradle"
manifest = plugin / "src" / "main" / "AndroidManifest.xml"
if not gradle.is_file() or not manifest.is_file():
    sys.exit("Expected razorpay_flutter 1.3.6 Android files not found")
source = gradle.read_text(encoding="utf-8")
xml = manifest.read_text(encoding="utf-8")
package = "com.razorpay.razorpay_flutter"
if "group '" + package + "'" not in source:
    sys.exit("Unexpected Razorpay Gradle group; refusing to patch")
if re.search(r"(?m)^\s*namespace\s", source):
    sys.exit("Razorpay namespace already exists; refusing to patch")
gradle_pattern = re.compile(r"(?m)^(android\s*\{)$")
new_source, count_gradle = gradle_pattern.subn(
    lambda m: m.group(1) + "\n    namespace '" + package + "'",
    source,
)
manifest_pattern = re.compile(r'(?<=\s)package="com\.razorpay\.razorpay_flutter"')
new_xml, count_manifest = manifest_pattern.subn("", xml)
if count_gradle != 1 or count_manifest != 1:
    sys.exit(
        f"Unexpected Razorpay layout (gradle={count_gradle}, manifest={count_manifest}); "
        "no files changed"
    )
gradle.write_text(new_source, encoding="utf-8")
manifest.write_text(new_xml, encoding="utf-8")
print("CI-ONLY: migrated razorpay_flutter 1.3.6 Android namespace in disposable pub cache")
print("No K3 source, release signature, payment configuration, or prod data changed")
