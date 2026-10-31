# Care360 Patient — Android and iOS upgrade gates

Scope: **upgrade the existing Care360 Patient listings**, not create another app. Branding:
"Nigeria to the World" and "A product of CNU Medical Institute."
This is institutional attribution and product origin, **not** a claim that services are licensed or accessible worldwide.

## Identifiers already found in the repository

| Platform | Source identifier | Other source details |
| --- | --- | --- |
| Android | `com.cnu.patient` | Gradle release requires `android/key.properties` and private keystore |
| iOS Runner | `com.cnu.patient` | Apple signing team configured; Runner display name Care360 |
| iOS OneSignal extension | `com.cnu.patient.OneSignalNotificationServiceExtension` | Source extension deployment target iOS 17.2 |
| Flutter | Single `lib/` design and business-logic codebase | Both platforms use shared Dart screens |

These are **source settings**, not independent evidence of the live Apple App Store Connect app record.
Confirm the exact **Bundle ID** and version/build values in App Store Connect before attempting an update.
Do not mistake similarly named unrelated apps for this project's listing.

## Visual and navigation acceptance

- Verify compact Android portrait (320 × 568 and taller), dynamic text sizes, landscape/tablet behavior.
- Verify iPhone simulator build on macOS and an actual iPhone through TestFlight.
- Verify all three onboarding screens, Skip and Get started, local translations, accessibility semantics.
- Verify authentication, password reset, verification, session persistence, account deletion, and location denial.
- Verify provider discovery, appointments, pharmacy, lab, hospitals, payments, notifications, calls, chat, prescriptions.
- Verify original app users keep access to their accounts and data when upgrading; run migrations only through controlled backend change management.

## Security and clinical readiness

- **Never** use synthetic offline Android APK or iOS simulator app for user, clinical, or payment acceptance testing.
- Separate staging Firebase and API and rotate any previously exposed service credentials.
- Verify iOS entitlements, APNs configuration, OneSignal extension and signing provisioning before TestFlight.
- Confirm Apple privacy nutrition labels and Google Play Data Safety reflect actual processing, including AI if enabled.
- Audit user consent, encryption, access controls, incident reporting, and health information retention.
- AI features require server-side model credentials, clinician supervision of draft notes and restrictions on patient data.

## Release checklist

### Google Play (existing Care360 Patient app)
- [ ] Play Console package ID matches `com.cnu.patient`.
- [ ] Upload signing certificate and Play App Signing arrangements verified.
- [ ] `versionCode` strictly greater than any version previously uploaded.
- [ ] Signed release **AAB** produced with production configuration; target-SDK policy verified.
- [ ] Internal/closed testing and controlled production rollout approved.

### Apple (existing Care360 Patient app)
- [ ] Existing App Store Connect app record Bundle ID confirmed as `com.cnu.patient`; if different, stop and reconcile **before** any archive.
- [ ] Current App Store version and build number obtained; choose higher identifiers for new archive.
- [ ] Correct Apple Developer team, signing certificates and provisioning profiles verified.
- [ ] iOS main app + OneSignal extension signing, minimum OS and push capabilities validated.
- [ ] Release **IPA** archived and uploaded to **the existing app** in App Store Connect.
- [ ] TestFlight tested on real iPhone before App Review.

**Current status:** Design source and isolated preview are under review. A passing synthetic build
proves compilation only. Neither production signing, store updates, nor end-to-end clinical
workflows have been verified.
