# Care360 Patient — Google Play update and iOS/TestFlight release gate
Date: 6 November 2026. Scope: **Care360 Patient only** (`com.cnu.patient`).
Status: **PREPARATION / NO STORE UPLOAD AUTHORISED OR PERFORMED**.

## Store identities and verified public facts
- Existing [Google Play Patient listing](https://play.google.com/store/apps/details?id=com.cnu.patient): Care360 Patient, `com.cnu.patient`, shown publicly under Official Vrailicht / VRAILICHT LTD, updated 21 July 2026. This is an **UPDATE**, not a new package. Verify the actual Play Console owner, original Google Play upload key and highest uploaded `versionCode` before preparing a release. The repo version `7.2.0+1` is **not** evidence of the last Play versionCode.
- iOS bundle ID in source: `com.cnu.patient`. TestFlight was previously described, but a public App Store Patient listing and App Store Connect team's access have **not** been verified. This may be an **initial App Store release**, rather than an update. Verify ownership, App ID, Apple Team ID and version/build history in App Store Connect.
- Care360's public ecosystem website currently labels the service as **beta, not a full production launch**. Store language and real app capability claims must reflect verified live features.
- Current public [Care360 medical privacy policy](https://medic.care360hms.com/privacy-policy) is accessible. A privacy/legal reviewer must reconcile its statements with the deployed code, backend, Firebase, retention and third-party processors. Do not infer policy compliance from the presence of a page.

## Requirements from official store documentation
- Google Play mobile **new apps and updates** submitted since 31 August 2026 must target Android **API 36** or higher. Source has been pinned to `compileSdk 36` and `targetSdk 36` on the release-prep branch. [Google Play requirements](https://support.google.com/googleplay/android-developer/answer/11926878).
- Google Play requires accurate **Health apps declaration**, **Data safety disclosure**, a publicly accessible privacy policy, and **both in-app and public-web account deletion request paths** for apps with account creation. [Health apps declaration](https://support.google.com/googleplay/android-developer/answer/14738291) · [User data policy](https://support.google.com/googleplay/android-developer/answer/10144311).
- Apple submissions since 28 April 2026 require **Xcode 26+ with iOS 26 SDK+**. iOS app platform target must be iOS 13 or newer; project is aligned to iOS 14. [Apple requirements](https://developer.apple.com/news/upcoming-requirements/).
- Apple requires truthful App Privacy data and URL, in-app account deletion, medical-data privacy and a tested app with review access. [App Privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy) · [App review](https://developer.apple.com/app-store/review/guidelines/).
- Google Play requires **16 KB page-size support** for apps targeting API 35+ on 64-bit devices. AGP 8.11.1 is sufficient for packaging, but bundled native `.so` SDKs (including Agora) still require verification via AAB/bundletool and a 16 KB device/emulator. [Android guidance](https://developer.android.com/guide/practices/page-sizes).

## Non-negotiable pre-release gates

| Area | Status / evidence required |
| --- | --- |
| Real login | NOT VERIFIED. Connect an approved production and isolated staging Laravel API, Passport, Firebase project; test Patient register → OTP → sign-in → sign-out → password reset. |
| Clinical flows | NOT VERIFIED. Test doctor/provider discovery, appointments, notes, e-prescriptions, labs, pharmacies, payment sandbox, video/audio/chat, network failures and role isolation. Do not use real patients for staging. |
| Source integration | PR #27 (red-screen/sandbox) and PR #4 (premium layout) remain open; must selectively reconcile tested real-app changes. The sandbox dashboard **is only a design preview**, not a functioning Patient Home. Do not ship the fake offline entry as a replacement for the authenticated dashboard. |
| Privacy and deletion | In-app Delete Account exists; backend has AccountErasureService, but end-to-end deletion, Firebase/Firestore chat data and lawful retention handling are unverified. Public web deletion request endpoint still requires confirmation. |
| Store ownership | Confirm VRAILICHT Play publisher authorization and upload certificate; Apple Team ID in project is not proof of access to App Store Connect. |
| Brand and store assets | Confirm latest Care360 Patient icon, launch image, phone/tablet screenshots, legal/developer name, support URLs, short/long description, and medical disclaimer. |
| Live environment | Explicit HTTPS production API ending `/api/`; approved production Firebase per platform; no staging/placeholder endpoints; production payment and push credentials only after isolated verification. |
| Platform builds | Signed Android AAB (not APK) and signed iOS IPA (not simulator ZIP) with tested upgrade paths and higher store version numbers. |
| Distribution | First Play internal test and iOS TestFlight, then review crash reports/ANRs, accessibility, low-bandwidth/denied location testing and staged rollout. |

## Android signed AAB — authorized operator on Windows or macOS

Do **not** copy passwords, Play signing certificates, raw Firebase JSON or health data into chat, GitHub commits, issue attachments or public runner artifacts.

1. Read the **highest existing Play Console `versionCode`** and select the next integer. Verify existing package ID `com.cnu.patient`, Play upload certificate SHA-256 and the correct **existing upload keystore**; if the original upload key is lost, follow Google's official upload-key reset with the account holder. Do not invent a new keystore and assume it updates the existing app.
2. Put the private production `google-services.json` in the **ignored** path `android/app/google-services.json`. It must register `com.cnu.patient`. Keep the original keystore in `android/app/` and ignored `android/key.properties` with alias/password/storeFile pointing to that private file. Check the file paths and SHA fingerprints manually.
3. Set these local/private environment variables: `K3_BUILD_ENV=production`; `K3_API_BASE_URL=https://VERIFIED-PRODUCTION-HOST/api/`; `K3_PRODUCTION_FIREBASE_PROJECT_ID`; `K3_STAGING_FIREBASE_PROJECT_ID` (to reject accidental staging reuse); `K3_PLAY_LATEST_VERSION_CODE`; `K3_ANDROID_NEXT_VERSION_CODE`.
4. Generate the private Flutter Dart defines **outside the repository** (example: `$HOME/care360-prod-android.json`) with:
   `python3 tools/k3_production_config.py --platform android --firebase android/app/google-services.json --out /PRIVATE/PATH/care360-prod-android.json`
   This operation fails if output exists; remove previous private output intentionally before creating a new one.
5. Run `python3 tools/k3_android_release_preflight.py` first. Then `flutter pub get --enforce-lockfile`, `dart run build_runner build --delete-conflicting-outputs`, and `python3 tools/k3_rewrite_generated_url.py`. Compile with Flutter 3.38.4, JDK 17, API 36:
   `flutter build appbundle --release --build-number=YOUR_NEW_PLAY_VERSION_CODE --build-name=YOUR_APPROVED_VERSION_NAME --dart-define=K3_BUILD_ENV=production --dart-define-from-file=/PRIVATE/PATH/care360-prod-android.json`
6. Inspect `build/app/outputs/bundle/release/app-release.aab`: versionCode, package, signing certificate, actual API/Firebase config and native libraries. Run `python3 tools/k3_android_native_page_alignment.py build/app/outputs/bundle/release/app-release.aab` and fail the release for any 4 KiB-aligned ARM64 ELF PT_LOAD segment. Also inspect bundletool zip page alignment (`bundletool dump config --bundle=...`), then install Play-generated APKs on a 16 KiB page-size Android device (`adb shell getconf PAGE_SIZE` must return `16384`). A passing static ELF check by itself does not prove 16 KiB packaging or runtime behavior. Test on Play internal testing before rollout.
7. **Never publish** the offline `.k3sandbox` APK, the local-LAN `.k3staging` APK or a debug-signed bundle.

## iOS signed IPA/TestFlight — authorized operator on Mac

1. Verify App Store Connect access to **Care360 Patient** under exact bundle ID `com.cnu.patient`, and the correct Apple Team ID (the checked-in Xcode project currently references `KJ5MJLJ9C9`; verify ownership). Read App Store Connect's existing build numbers and use a larger integer.
2. Install Xcode 26+ with iOS 26 SDK, CocoaPods and Flutter 3.38.4; select the correct paid Apple Developer team and **App Store distribution** signing capability. The Release scheme uses `RunnerRelease.entitlements` with production APNs; Debug/Profile retain development entitlements. Verify App ID/provisioning capabilities and OneSignal notification extension signing.
3. Place approved **production** `GoogleService-Info.plist` in the ignored `ios/Runner/` path. It must register `com.cnu.patient`; never reuse the Android Firebase client or a staging iOS plist.
4. Set private env: `K3_BUILD_ENV=production`, `K3_API_BASE_URL`, `K3_PRODUCTION_FIREBASE_PROJECT_ID`, `K3_STAGING_FIREBASE_PROJECT_ID`, `K3_IOS_LATEST_BUILD_NUMBER`, `K3_IOS_NEXT_BUILD_NUMBER`, `K3_IOS_DEVELOPMENT_TEAM`, `K3_IOS_FIREBASE_PLIST_PATH=ios/Runner/GoogleService-Info.plist`.
6. Generate private Dart defines outside Git: `python3 tools/k3_production_config.py --platform ios --firebase ios/Runner/GoogleService-Info.plist --out /PRIVATE/PATH/care360-prod-ios.json`. Run `python3 tools/k3_ios_release_preflight.py`; fix all failures before compiling.
7. Run `flutter pub get --enforce-lockfile`, `dart run build_runner build --delete-conflicting-outputs`, `python3 tools/k3_rewrite_generated_url.py`, `cd ios && pod install --deployment && cd ..`, then:
   `flutter build ipa --release --build-number=YOUR_NEW_APPLE_BUILD_NUMBER --build-name=YOUR_APPROVED_APP_VERSION --dart-define=K3_BUILD_ENV=production --dart-define-from-file=/PRIVATE/PATH/care360-prod-ios.json`
8. Archive/export with the correct **App Store** signing profile; inspect actual embedded entitlements, Firebase config, and app and notification extension bundle identifiers. Upload through Xcode Organizer/Transporter to TestFlight, run testing on physical devices, then submit to review with legitimate demo/test credentials and accurate privacy disclosures.

## Release-operator helpers and coordinated backend migration (7 November 2026)

- **Windows / Google Play:** From the checked-out, approved Patient release source, use PowerShell `./tools/build-patient-play-aab.ps1 -BuildName VERIFIED_VERSION -BuildNumber NEXT_PLAY_CODE` after supplying all private environment variables and the existing Play upload keystore. This runs source checks, creates private production Flutter defines, compiles a **signed AAB**, performs static ARM64 16 KiB ELF inspection and deletes its temporary config. It does not upload or assert Play certificate equality.
- **macOS / Apple TestFlight:** Run `bash tools/build-patient-ios-ipa.sh` on an authorised Mac with Xcode 26+, the production iOS Firebase plist, and valid App Store signing. The script checks production identity, runs selected Flutter tests and attempts a **signed IPA**, but never uploads it. macOS code signing and iOS runtime testing are still required.
- **Backend dependency:** The Patient release switches the account-deletion request from `GET /api/delete-account` to `POST /api/delete-account`. **Deploy and verify the companion Laravel [backend PR #20](https://github.com/Care360Apps/k3-backend/pull/20) on isolated staging, then production, BEFORE uploading the new Patient build.** Existing published clients temporarily retain the legacy GET route; retire it only after compatible clients have migrated. Verify appointment rules, patient-only identity checks, session invalidation, Firebase/Firestore erasure and legal retention.
- **After account deletion:** The new Patient client clears encrypted/session state and routes to Sign In instead of loading a deleted account's dashboard. This has only undergone source review and requires real-device/staging testing.
- **CI verification:** [public encrypted Android QA run #42303149356](https://github.com/speakoutMentalHealth/care360-android-builder/actions/runs/42303149356) passed against earlier source `2fcd0865d007674782247ac82e2954aaaa1eac3e`. [Follow-on static 16 KiB source run #42324584590](https://github.com/speakoutMentalHealth/care360-android-builder/actions/runs/42324584590) is a separate validation; do not assume it passed until its final result is inspected. Recent Patient/Backend changes must be built and integration-tested again before merge.

## Recommended QA acceptance gate

- Launch/upgrade without black/red screen; app icon correct; camera/microphone/location permissions are requested contextually; denial does not block login; optional push opt-in from Settings.
- Test login/sign-out and expired-token behavior, restricted Patient-only MindCheck link, doctor video only, provider home/virtual options, prescriptions, pharmacies, app account deletion and error states. Check offline/slow network and Android 9+ plus recent Android/iOS.
- Verify push payload does **not** disclose patient names, symptoms, medicines or consultation details on lock screens.
- Verify legal/clinical disclaimers, emergency options, age handling, privacy policy, public deletion URL, third-party processing disclosure and encryption. Review payment gateway restrictions before enabling live payments.
- Store assets and the final release notes must describe **tested actual features**, not the synthetic preview or unimplemented roadmap.

## Source audit and changes prepared on release branch

- Android API 36, scoped storage permissions, and no background location request.
- MapLibre uses the OpenFreeMap Liberty style by default. To use another provider, supply its public HTTPS style URL and attribution with `CARE360_MAP_STYLE_URL` and `CARE360_MAP_ATTRIBUTION` Dart defines.
- iOS: no APNs token logging or automatic launch-time native permission prompt, one-time Firebase configure, production APNs release entitlement, consistent iOS 14 minimum.
- Optional notification permission now requested from signed-in Settings; patient Privacy Policy screen stops loading and offers retry on error.
- Explicit production Android/iOS configuration generator; local fail-closed preflight scripts; offline unit/source checks.

**No build, production backend connection, signed AAB/IPA, Play Console upload or App Store Connect upload has been completed or claimed by this preparation.** Do not merge/submit until dependencies, credentials, app data and reviewer access have been verified by the authorised publisher.
