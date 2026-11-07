# Care360 Patient — visual-first startup and onboarding review
Date: 7 November 2026
Status: DRAFT source for visual approval. No new APK generated.

## Implemented design
- First install: native Android/iOS splash -> Care360 first-language selection -> existing three official-photo welcome slides -> existing secure sign-in -> dashboard.
- Returning/previously onboarded users are routed exactly as before, to Home if logged in or SignIn otherwise. Their logged-in state, profile, medical records, patient/doctor session token, bookings and payments are **not** wiped or migrated.
- The first-language selector offers English, Hausa, Igbo, Yoruba and French, persists selection using the existing `care360_locale.setLocale` mechanism and rebuilds the app locale using the existing state. It displays a truthful note that some untranslated text stays in English. It does not invent translations or claim clinical/medical terminology is complete.
- Uses existing, actual checked-in `assets/images/care360_master_logo.webp` and `assets/images/care360_clinician_team.webp` instead of replacing either with AI-generated imagery. Existing African family and appointments photos remain in all three onboarding slides, and the sign-in screen retains the Care360AuthShell and language picker.
- Navy `#123E4D`, clinical teal `#087D76` and light neutral `#F5F8F7`, readable tiles, 48+ px touch areas, narrow-screen scroll and reduced text reliance on images.
- The existing `assets/images/appicon.png` showed a generic blue heart, **not** the same full wordmark as `care360_master_logo.webp`. Native splash configuration now points to `care360_splash_brand.png`, created from the checked-in real master by `python3 tools/k3_prepare_launch_brand.py`. The final build must run `dart run flutter_native_splash:create` before assembling APK/AAB. The manual encrypted staging builder is updated to do this. The launcher icon still requires separate approved high-resolution original artwork; **no unverified app icon redesign** is included.
- Android 12's OS-controlled splash layout cannot display a long scrolling collage; the complete branded image/language UI appears in Flutter after that native icon splash.

## Review sequence
1. Confirm the real full Care360 logo (and sharper master if possible) on first-language screen and the three welcome cards; no new artificial logo.
2. Check English, Hausa, Igbo, Yoruba and French remain selected when moving to sign-in; changing in Settings still works without red-screen Flutter exceptions. Text not yet translated uses English fallback.
3. Test language choice on 320 px and 430 px phones and larger font settings, with the software keyboard open on sign-in.
4. Skip/Continue of all three onboarding screens; verify no unexpected requests for GPS during sign-in. Opening existing sessions must bypass first-run setup.
5. Preserve Home: Hospitals, Doctors, Providers, Pharmacies, Labs, Workforce; plus Nearby Care, sponsor, AI Guide, teleconsultations, medicines, payments, medical records, and original routes.
6. Work with synthetic accounts only. Feature-flagged Workforce still remains OFF without server approval; candidate chat/hiring is not represented as a launched feature.
7. Do NOT generate repeated APKs for design review. Obtain owner visual approval first; then run source/tests, encrypted staged build and a **single consolidated Android APK acceptance** in BlueStacks before developer handover.

## Build configuration
```sh
python3 -m pip install Pillow
python3 tools/k3_prepare_launch_brand.py
flutter pub get
dart run flutter_native_splash:create
flutter test test/care360_first_launch_visual_flow_test.dart
```

The native brand conversion preserves the original image; it cannot create extra source detail. A high-resolution official export may be required for crisp print/app-store assets. Final production signing/App Store/Play Store builds belong to the original developer.

## QA evidence
- Synthetic Flutter tests added at `test/care360_first_launch_visual_flow_test.dart`.
- Public builder: `feat/patient-first-entry-visual-qa-20261107` runs these plus existing Patient, language, Nearby Care, sponsor, Workforce, Map/address and security source tests.
- These tests do not certify clinical correctness, real-device visuals, native splash asset sharpness, or live Laravel data flows.

Keep this UI draft stacked on Patient Workforce PR #39 and base Patient PR #35; don't merge directly to `main` until all dependencies and security release gates are signed off.
