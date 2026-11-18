#!/usr/bin/env python3
"""Temporary Android CI fix for Agora iris_method_channel 2.0.0-dev.4.

Modify only the disposable GitHub runner's pub cache (not repository app source).
Matched against upstream tag 2.0.0-dev.4, whose Gradle file declares
'minSdkVersion 16'. Fail closed if upstream package layout differs.
"""
import os
from pathlib import Path
import re
import sys
import json

config = Path(__file__).resolve().parents[1] / '.dart_tool/package_config.json'
if config.is_file():
    active = json.loads(config.read_text()).get('packages', [])
    if any(p.get('name') == 'iris_method_channel' and p.get('rootUri', '').rstrip('/').endswith(('iris_method_channel-2.2.4', 'iris_method_channel-2.2.7')) for p in active):
        print('Modern Iris bridge is active; obsolete dev.4 cache patch is not needed.')
        sys.exit(0)

cache = Path(os.environ.get("PUB_CACHE") or (Path.home() / ".pub-cache"))
gradle = (cache / "hosted" / "pub.dev" / "iris_method_channel-2.0.0-dev.4"
          / "android" / "build.gradle")
if not gradle.is_file():
    sys.exit("Expected iris_method_channel 2.0.0-dev.4 Android Gradle file missing")
original = gradle.read_text(encoding="utf-8")
if "group 'com.agora.iris_method_channel'" not in original:
    sys.exit("Unexpected iris_method_channel Gradle group; manual review required")
pattern = re.compile(r"(?m)^(\s*minSdkVersion\s+)16(\s*)$")
modified, replacements = pattern.subn(lambda m: m.group(1) + "21" + m.group(2), original)
if replacements == 0 and len(re.findall(r"(?m)^\s*minSdkVersion\s+21\s*$", original)) == 1:
    print('CI-ONLY: iris_method_channel minSdkVersion is already 21 in the disposable cache.')
    sys.exit(0)
if replacements != 1:
    sys.exit(f"Expected exactly one iris_method_channel minSdkVersion 16; found {replacements}")
gradle.write_text(modified, encoding="utf-8")
print("CI-ONLY: iris_method_channel minSdkVersion 16 -> 21; original K3 app minSdk remains 24")
