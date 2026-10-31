#!/usr/bin/env python3
"""Create synthetic-only Firebase config for K3 iOS Simulator compile checks."""
import plistlib
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
pbx = (root / 'ios/Runner.xcodeproj/project.pbxproj').read_text()
ids = re.findall(r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*(com\.cnu\.(?:patient|doctor));', pbx)
if not ids or len(set(ids)) != 1:
    raise SystemExit('Unexpected or inconsistent K3 Runner bundle ID')
# Xcode's PBXFileReference resolves GoogleService-Info.plist from the
# ios/ project root, whereas the legacy staging-define reader looks in Runner/.
# Both locations need identical *synthetic* data in this ephemeral CI checkout.
xcode_plist = root / 'ios/GoogleService-Info.plist'
runner_plist = root / 'ios/Runner/GoogleService-Info.plist'
for destination in (xcode_plist, runner_plist):
    if destination.exists() or destination.is_symlink():
        raise SystemExit(f'Refusing to overwrite existing Firebase plist: {destination}')
runner_plist.parent.mkdir(parents=True, exist_ok=True)
synthetic_plist = plistlib.dumps({
    'PLIST_VERSION': '1',
    'API_KEY': 'k3-synthetic-not-a-valid-firebase-key',
    'GCM_SENDER_ID': '123456789012',
    'PROJECT_ID': 'k3-synthetic-build-invalid',
    'STORAGE_BUCKET': 'k3-synthetic-build-invalid.invalid',
    'GOOGLE_APP_ID': '1:123456789012:ios:0123456789abcdef01234567',
    'BUNDLE_ID': ids[0],
    'IS_ADS_ENABLED': False,
    'IS_ANALYTICS_ENABLED': False,
    'IS_SIGNIN_ENABLED': False,
    'IS_GCM_ENABLED': False,
})
xcode_plist.write_bytes(synthetic_plist)
runner_plist.write_bytes(synthetic_plist)
if xcode_plist.read_bytes() != runner_plist.read_bytes():
    raise SystemExit('Synthetic Firebase plist copies are not identical')
print('Synthetic Firebase plist created at Xcode and Runner paths for simulator-only compile')
