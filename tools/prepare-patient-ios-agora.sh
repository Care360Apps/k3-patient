#!/usr/bin/env bash
# Resolve the targeted native SDK upgrade on an authorised Mac. No signing/upload.
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo 'This dependency preparation requires macOS and CocoaPods.' >&2
  exit 1
fi
command -v flutter >/dev/null
command -v pod >/dev/null
flutter pub get --enforce-lockfile
(cd ios && pod update agora_rtc_engine iris_method_channel AgoraIrisRTC_iOS AgoraRtcEngine_iOS)
echo 'Review ios/Podfile.lock and the native dependency changes before release builds.'
echo 'Then run the iOS release preflight and an Xcode/iPhone validation build.'
echo 'No application was signed, uploaded or published by this preparation step.'
