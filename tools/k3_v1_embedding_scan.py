#!/usr/bin/env python3
"""Preflight old Flutter Android v1 embedding references in active plugins.

Read the Flutter-generated plugin list so that only build-included plugins
are examined; do not scan the whole pub cache or private application code.
No network access and no modifications. The build should fail before its
expensive Gradle stage if a plugin still uses removed Android embedding APIs.
"""
import json
from pathlib import Path
import re
import sys

manifest = Path(".flutter-plugins-dependencies")
if not manifest.is_file():
    sys.exit("Missing .flutter-plugins-dependencies; run flutter pub get first")

plugins = json.loads(manifest.read_text(encoding="utf-8")).get("plugins", {}).get("android", [])
if not plugins:
    sys.exit("Flutter Android plugin list is unexpectedly empty")

patterns = [
    re.compile(r"\bPluginRegistry\s*\.\s*Registrar\b"),
    re.compile(r"\bimport\s+io\.flutter\.plugin\.common\.PluginRegistry\.Registrar\s*;"),
    re.compile(r"\b(?:public\s+)?static\s+void\s+registerWith\s*\([^)]*\bRegistrar\b", re.S),
    re.compile(r"\bio\.flutter\.view\.FlutterMain\b"),
    re.compile(r"\bio\.flutter\.app\.(?:FlutterActivity|FlutterApplication|FlutterFragmentActivity)\b"),
]
findings = []
for plugin in plugins:
    name = plugin["name"]
    plugin_root = Path(plugin["path"])
    src = plugin_root / "android" / "src" / "main"
    if not src.is_dir():
        continue
    for file in list(src.rglob("*.java")) + list(src.rglob("*.kt")):
        text = file.read_text(encoding="utf-8", errors="replace")
        if any(p.search(text) for p in patterns):
            findings.append(f"{name}: {file.relative_to(plugin_root)}")

if findings:
    print("FAIL: Android plugins still reference Flutter's deleted v1 embedding APIs:")
    for finding in sorted(set(findings)):
        print("  " + finding)
    print("Upgrade each reported plugin to a compatible version before Android compilation.")
    sys.exit(1)

print(f"PASS: no known deleted Flutter Android v1 embedding references in {len(plugins)} active plugins")
