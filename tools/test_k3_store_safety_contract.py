#!/usr/bin/env python3
"""Source-only regression checks for release review; no credentials or API calls."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class PatientStoreSafetyContract(unittest.TestCase):
    def read(self, name):
        return (ROOT / name).read_text(encoding="utf-8")

    def test_release_bundle_keeps_existing_identity_and_targets_android_16(self):
        gradle = self.read("android/app/build.gradle")
        self.assertIn('applicationId "com.cnu.patient"', gradle)
        self.assertIn("compileSdk 36", gradle)
        self.assertIn("targetSdk 36", gradle)
        self.assertIn("K3_ANDROID_MAPS_API_KEY", gradle)

    def test_patient_does_not_request_background_location(self):
        manifest = self.read("android/app/src/main/AndroidManifest.xml")
        self.assertNotIn("ACCESS_BACKGROUND_LOCATION", manifest)
        self.assertIn('android:maxSdkVersion="32"', manifest)
        self.assertIn('android:maxSdkVersion="28"', manifest)
        self.assertIn('android:value="${k3GoogleMapsApiKey}"', manifest)

    def test_ios_permissions_are_contextual_and_native_tokens_not_logged(self):
        delegate = self.read("ios/Runner/AppDelegate.swift")
        self.assertNotIn("requestAuthorization(", delegate)
        self.assertNotIn("deviceToken.map", delegate)
        self.assertNotIn("print(\"APNs token", delegate)
        entry = self.read("lib/main.dart")
        sign_in = self.read("lib/Screen/Authentication/SignIn.dart")
        settings = self.read("lib/Screen/Screens/Setting.dart")
        self.assertNotIn("OneSignal.Notifications.requestPermission(true)", entry)
        self.assertNotIn("OneSignal.Notifications.requestPermission(true)", sign_in)
        self.assertIn("OneSignal.Notifications.requestPermission(true)", settings)
        self.assertIn("patient-enable-notifications", settings)

    def test_account_deletion_and_privacy_recovery_are_visible(self):
        settings = self.read("lib/Screen/Screens/Setting.dart")
        privacy = self.read("lib/Screen/Setting/PrivacyPolicy.dart")
        self.assertIn("showDeleteAccountDialog", settings)
        self.assertIn("PrivacyPolicy", settings)
        self.assertIn("loading = false;", privacy)
        self.assertIn("TextButton.icon(", privacy)
        self.assertIn("onPressed: loading ? null : appAllDetail", privacy)

    def test_app_store_release_push_environment_is_production(self):
        proj = self.read("ios/Runner.xcodeproj/project.pbxproj")
        release = self.read("ios/Runner/RunnerRelease.entitlements")
        self.assertIn("CODE_SIGN_ENTITLEMENTS = Runner/RunnerRelease.entitlements", proj)
        self.assertIn("<string>production</string>", release)
        self.assertEqual(proj.count("PRODUCT_BUNDLE_IDENTIFIER = com.cnu.patient;"), 3)


if __name__ == "__main__":
    unittest.main()
