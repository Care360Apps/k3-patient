# Care360 Patient and Plus — highest-compatible upgrade plan

Date: 7 November 2026  
Status: controlled **draft upgrade**, separate from production. No App Store/Play Store release performed.

## Definition of "highest possible"
Adopt the latest **stable, demonstrably compatible and supportable** versions, not unstable beta or major native changes that break healthcare functions. Security, medical privacy and live backend acceptance remain separate mandatory release gates.

## Verified source and platform baseline

| Component | Existing app | Target trial | Evidence and decision |
|---|---|---|---|
| Flutter framework | Both apps: 3.38.3 in the earlier CI builder | **3.47.9 stable** (Dart 3.13.7) | Patient **45/45** unit/widget/source tests passed with the new SDK on https://github.com/speakoutMentalHealth/care360-android-builder/actions/runs/42416484402. Plus test not yet run. |
| Android Gradle Plugin | Both: 8.11.1 | **8.13.2** | Native configuration staged only, not certified. |
| Kotlin Gradle Plugin | Both: 2.2.20 | **2.3.21** | Official Kotlin range supports Gradle 8.14 / AGP 8.13; full native plugin tests pending. |
| Gradle wrapper | Both: 8.14 | Keep **8.14** | Supported by proposed AGP/Kotlin combination. Jumping to 9.x here would require a separate plugin migration. |
| JDK | Both: 17 | Keep **17** | Official AGP 8.13 baseline JDK; version bump without need is wasteful and riskier. |
| App's public version | Both: 7.2.0+1 | **Do not change without developer's Play version-code history** | Original developer retains store uploads and signing continuity. |
| Minimum Android | Both: API 24 | Keep | Avoid needlessly excluding existing Nigerian users with affordable Android phones. |
| Firebase | Patient Core3/Auth5/Messaging15/Storage12; Plus Core4/Auth6/Messaging16/Storage13 | Align Patient to supported newer families **after** auth/provider upgrade tests | Firebase custom token identity, OTP and Firestore/notification delivery must not regress. |
| Agora | Both: Agora RTC 6.2.6 | Audit SDK, native calling and token-service compatibility before advancing | Booking-limited channels and audio/video on both roles must pass end-to-end. |
| Google Maps / Places | Android Maps and legacy flutter_google_places/google_api_headers dependencies | Native Maps SDK + secured backend Places API (New) | Legacy plugin emits platform metadata warnings; never expose unrestricted server Places keys in client. |
| Payments / Stripe | Both: flutter_stripe 12.3.0 | Hold until gateway amount/status verification and staging refund/cancel testing | No payments or settlement logic changes without explicit server-side QA. |

## Upgrade rules

- Android 13/14/15/16 compatibility: check target/compile SDK metadata and permissions as dictated by current Flutter / Play requirements; avoid hardcoding a target SDK merely to claim "latest".
- Avoid AGP 9 in the present release candidate: the older Flutter Gradle plugins, bundled Kotlin handling and third-party plugins require a separate full migration. Official Flutter migration notes document transitional Kotlin/DSL support.
- Do not remove Flutter packages until usages are checked in both repos and tests validate replacements. `flutter pub outdated` and `flutter pub upgrade --major-versions` must run only in an ephemeral throwaway CI checkout before committing any package upgrade.
- Preserve `AGP 8.11.1 / Kotlin 2.2.20 / Flutter 3.38.3` as an immediately reversible baseline until Android 8.13.2 / Kotlin 2.3.21 native Gradle configuration and connected APK build are verified.
- No release-signing key, staging/production Firebase credentials or backend secrets may appear in public CI, source, screenshots or diagnostic artifacts.

## Current risk gates
1. Full Patient Android Gradle native configuration (no APK) in https://github.com/speakoutMentalHealth/care360-android-builder/pull/7; successful unit tests alone are **not** proof.
2. Plus independent Flutter and Android CI is blocked by missing private source access for public runner; do not claim Plus upgrade success.
3. Clinical records stored at historical public URLs need private migration, old URL denial and server proof; production credentials and debug controls must be verified.
4. One final user-accepted encrypted Android APK per app after the source tests, realistic staged Firebase/Maps/Agora/payments, clinical/Provider roles, language switching and design sign-off.

## References
- Flutter archive: https://docs.flutter.dev/install/archive
- Android Gradle Plugin 8.13 release notes: https://developer.android.com/build/releases/agp-8-13-0-release-notes
- Kotlin Gradle compatibility: https://kotlinlang.org/docs/gradle-configure-project.html
- Flutter AGP built-in Kotlin migration: https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin

**Decision:** Stage upgrades safely, do not claim the native toolchain and all third-party plugins are production-ready until independent tests pass.
