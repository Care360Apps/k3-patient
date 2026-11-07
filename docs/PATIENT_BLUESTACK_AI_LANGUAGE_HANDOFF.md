# Care360 Patient — BlueStacks first, developer handoff (7 Nov 2026)

This is **Patient-only** visual/functionality work. The publisher/developer
owns store signing, release builds and submissions. Do **not** replace existing
clinical workflows with the design-review screens.

## Safe preview: exactly what can be inspected now

This branch begins at the Patient red-screen/offline-preview PR #27, pinned to
`4a68463897435261d3341001700f80dc845fc58b`, then adds:

- An accessible **five-language selector** on sign-in and sign-up:
  English, Hausa, Igbo, Yorùbá and French. It uses the existing Flutter
  localization and persists changes in the real app.
- The same selector in the offline dashboard. Select a language and watch
  navigation/dashboard headings change. **The offline preview does not save a
  patient account or clinical language preference.** The preview wording is
  only a sample for native-speaker review.
- A new Care360 Guide service card in the **sample dashboard**. It opens a
  standalone curated, nonclinical navigation guide with four safe categories:
  getting started, appointments, account/settings and partner services.
- The **authenticated real Home** page keeps its existing clinical
  navigation; its partner section now opens the same controlled guide instead
  of the previous static help bottom sheet. Existing MindCheck external link
  stays separate and never receives Care360 identifiers.
- App-wide live language switch is still present on connected screens; it is
  excluded from the disconnected sandbox specifically to avoid the previous
  Flutter overlay crash. The sandbox itself has its own visible selector.

## AI activation — implemented wiring versus live generation

**Working now:** curated guidance cards and a clear nonclinical disclaimer
(usable offline, no API, no patient records). A Patient who taps **Show guide**
receives a selected, vetted navigation response.

**Implemented but NOT enabled:** optional server-assisted answer:
`K3_AI_GUIDE_PILOT=true` at compile time, signed-in Patient, explicit
opt-in on guide screen, and verified HTTPS Care360 Laravel API required.
Only `{topic, language}` is posted to `POST /api/ai/guide` with the
existing Care360 auth token; there is no freeform text input and no symptoms,
medical history, prescription, consultation, contacts or payment data sent to
the model. If the request fails, the curated answer remains.

The server route/feature flag lives in **unmerged backend PR #8**:
`https://github.com/Care360Apps/k3-backend/pull/8`.
By default, its `K3_AI_GUIDE_ENABLED=false`; real Gemini generation is
NOT live. No AI secret should ever be placed in Flutter, Google Drive shared
handoff, screenshots, APK artifacts or chat. Verify backend authentication,
isolated staging, data-processing/privacy notices, usage costs, consent,
content testing, supported languages and abuse handling before activation.

**Not a medical AI:** no diagnosis, symptom analysis, emergency triage,
treatment, prescriptions or autonomous clinical decisions.

## BlueStacks review path

1. Use the public **encrypted synthetic Patient APK builder** pinned to this
   branch's reviewed commit. Download the encrypted APK, then decrypt locally
   with the existing personal password using the Windows decryptor. Do not
   upload plaintext APKs, Firebase config or password.
2. Install the distinct `com.cnu.patient.k3sandbox` APK into BlueStacks
   Android Pie 64-bit. It coexists with the production app, has deliberately
   invalid backend and synthetic Firebase, and must never be uploaded to Play.
3. On Sign In choose a language, then select **Preview patient dashboard**.
4. Review Home/Explore/Bookings/Profile, language selector, Doctors/Hospitals/
   Pharmacies/Care Providers/MindCheck and **Care360 Guide**.
5. Try all four guide categories; no real patient login or booking is possible.
6. Record screenshot/observations for each page. Once the visual layout is
   approved, repeat the same screens on the real app using isolated staging,
   not synthetic production data.

## Handoff package to the original developer

- Patient GitHub repo/branch and reviewed commit SHA, with PR diff and test
  status; do not copy the synthetic/offline APK into a store release.
- A clear changelog: visual assets, language work, AI Guide UX and pending
  live-feature flags. Keep Doctor/Plus and HMS identities/release numbers
  separate.
- Existing API/Firestore contracts must remain intact; generate Retrofit
  code from source and use proper production/staging Firebase setups.
- Provide full acceptance testing: login, registration/OTP, logout,
  appointment/consultation/doctor/provider/hospital/pharmacy flows,
  MindCheck external link, language persistence, no patient data to AI,
  permission denial, low-bandwidth, Android phone and iPhone tests.
- Developer independently restores **existing store signing**, confirms
  version codes/bundle IDs, builds release AAB and IPA and distributes through
  Google Play internal testing and Apple TestFlight, then submits the apps.

## Sign-off blockers

- Real authenticated screens and API data are **not available** in this
  offline preview; do not report them as validated from BlueStacks alone.
- Translations are **partial**, and medical/safety language must receive
  qualified human review before being advertised as fully multilingual.
- The earlier premium UI PR #4, diagnosis/debug PR #27, store PR #28,
  partner-carousel PR #24 and backend AI PR #8 should be reconciled
  individually, with CI and manual tests, not merged blindly.
- No production or live-store deployment is authorized by this review build.
