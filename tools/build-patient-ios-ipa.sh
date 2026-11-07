#!/usr/bin/env bash
# Care360 Patient: signed TestFlight/App Store IPA on an authorised macOS machine.
# Does not upload or publish. Private keys and provisioning stay in Keychain.
# Example: K3_IOS_NEXT_BUILD_NUMBER=90 K3_IOS_APP_VERSION=7.3.0 bash tools/build-patient-ios-ipa.sh
set -euo pipefail

cd "$(dirname "$0")/.."
: "${K3_IOS_APP_VERSION:?Set verified App Store version, e.g. 7.3.0}"
: "${K3_IOS_NEXT_BUILD_NUMBER:?Read and increment existing App Store Connect build number}"
: "${K3_IOS_LATEST_BUILD_NUMBER:?Read existing App Store Connect build number}"
: "${K3_API_BASE_URL:?Set verified production HTTPS API base URL}"
: "${K3_PRODUCTION_FIREBASE_PROJECT_ID:?Verify production Firebase project ID}"
: "${K3_IOS_GOOGLE_MAPS_API_KEY:?Set restricted iOS Maps key privately}"
: "${K3_IOS_DEVELOPMENT_TEAM:?Verify the Apple Developer Team ID}"
: "${K3_IOS_FIREBASE_PLIST_PATH:?Set private production GoogleService-Info.plist path}"
if [[ "${K3_OFFLINE_TEST:-false}" == "true" ]]; then
  echo 'Synthetic/offline flags cannot be used for App Store releases.' >&2
  exit 1
fi
if [[ ! "${K3_IOS_APP_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo 'Invalid app version; confirm the version in App Store Connect.' >&2
  exit 1
fi
export K3_BUILD_ENV=production

# Never print sensitive build variables; run with normal shell tracing disabled.
set +x
private_dir="$(mktemp -d)"
private_json="$private_dir/patient-production-ios.json"
cleanup() {
  rm -f -- "$private_json"
  rmdir -- "$private_dir" 2>/dev/null || true
}
trap cleanup EXIT

python3 tools/k3_ios_release_preflight.py
python3 tools/k3_production_config.py \
  --platform ios \
  --firebase "$K3_IOS_FIREBASE_PLIST_PATH" \
  --out "$private_json"
flutter pub get
dart run build_runner build --delete-conflicting-outputs
python3 tools/k3_rewrite_generated_url.py
flutter test --no-pub test/k3_startup_gate_test.dart test/k3_startup_diagnostics_test.dart test/k3_entry_brand_test.dart
(cd ios && pod install --deployment)
flutter build ipa --release \
  --build-name="$K3_IOS_APP_VERSION" \
  --build-number="$K3_IOS_NEXT_BUILD_NUMBER" \
  --dart-define=K3_BUILD_ENV=production \
  --dart-define-from-file="$private_json"
shopt -s nullglob
outputs=(build/ios/ipa/*.ipa)
if (("${#outputs[@]}" != 1)); then
  echo 'Expected one signed IPA. Check Xcode distribution profiles and build export settings.' >&2
  exit 1
fi
echo "Local signed IPA prepared: ${outputs[0]}"
echo 'STOP: Inspect entitlement/APNs signing, real API/Firebase configuration, release role flows, App Store age/privacy forms and TestFlight acceptance before upload.'
