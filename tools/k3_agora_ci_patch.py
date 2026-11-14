#!/usr/bin/env python3
"""Raise Agora 6.2.6's obsolete Android minimum only for disposable CI builds.

This does not change pubspec.lock, the K3 application minimum SDK, or any
production source. It mutates the pub-cache on a throwaway GitHub runner.
The supported permanent solution is a separately tested dependency upgrade.
"""
import os
from pathlib import Path
import re
import sys
import json

config = Path(__file__).resolve().parents[1] / '.dart_tool/package_config.json'
if config.is_file():
    active = json.loads(config.read_text()).get('packages', [])
    if any(p.get('name') == 'agora_rtc_engine' and p.get('rootUri', '').rstrip('/').endswith('agora_rtc_engine-6.5.3') for p in active):
        print('Agora 6.5.3 is active; obsolete 6.2.6 cache patch is not needed.')
        sys.exit(0)

pub_cache = Path(os.environ.get('PUB_CACHE') or (Path.home() / '.pub-cache'))
gradle = pub_cache / 'hosted' / 'pub.dev' / 'agora_rtc_engine-6.2.6' / 'android' / 'build.gradle'
if not gradle.is_file():
    sys.exit(f'Agora Android Gradle file not found: {gradle}')
text = gradle.read_text(encoding='utf-8')
# Match the verified Agora 6.2.6 fallback, not arbitrary minSdk lines.
pattern = re.compile(
    r"""(?m)^(\s*minSdkVersion\s+safeExtGet\(\s*['"]minSdkVersion['"]\s*,\s*)16(\s*\)\s*)$"""
)
updated, count = pattern.subn(lambda m: m.group(1) + '21' + m.group(2), text)
if count == 0:
    already_patched = re.compile(pattern.pattern.replace('16(', '21('))
    if len(already_patched.findall(text)) == 1:
        print('CI-ONLY: verified Agora minSdk fallback is already 21 in this disposable cache.')
        sys.exit(0)
if count != 1:
    sys.exit(f'Expected exactly one Agora minSdk=16 declaration; found {count}. Review dependency before patching.')
gradle.write_text(updated, encoding='utf-8')
print(f'CI-ONLY: Agora minSdk 16 -> 21 in {gradle}')
print('K3 app minSdk remains 24; no production file was modified.')
