# Care360 five-language source audit — 7 November 2026

**Scope:** Source-level count of JSON translation keys directly inspected in connected GitHub repositories at the indicated refs. It is **not** a runtime/BlueStacks certification and not a measure of translation correctness. A language selector being visible is not evidence that all screens are translated.

| Product / source ref | English keys | Hausa keys | Igbo keys | Yoruba keys | French keys | Non-English per-locale key coverage |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Patient — `feat/patient-nearby-sponsor-10s-integrated-20261107` | 436 | 48 | 48 | 48 | 48 | 48/436 ≈ **11.0%** |
| Plus (Doctor/Provider) — `main` | 338 | 38 | 38 | 38 | 38 | 38/338 ≈ **11.2%** |

Patient JSON: `lib/localization/languages/{en,ha,ig,yo,fr}.json`.
Plus JSON: `lib/localization/language/{en,ha,ig,yo,fr}.json`.

Both apps correctly use **English fallback** when a string has not been translated; that prevents broken or invented translations but should never be marketed as full multilingual coverage. Native-speaker review of the existing translated strings is still required. Also review any hard-coded strings outside JSON, including sponsor disclosure, Maps/nearby, clinical workflows, verification, and legal notices.

## Translation priority

1. **Critical user safety:** emergency/urgent-care disclaimers, medication & clinical instructions, identity/verification, consent, errors, failed payment and failed booking. These require medical-language review.
2. **Core patient journey:** sign-in and OTP, service discovery, provider role, appointment booking/cancellation/fees, teleconsultation and pharmacy orders.
3. **Professional app:** provider availability and home visits, clinical notes, e-prescriptions, patient history and role-appropriate legal wording.
4. **Discovery and monetisation:** explain clearly that a sponsored slide is paid, external link opens a separate business, and neither advert nor MindCheck is Care360 clinical advice. Do not translate sponsor names/treatment claims automatically.
5. **Polish:** empty states, accessibility labels, push notifications, tooltips, settings, language persistence and onboarding.

## Production acceptance protocol

- Publish a controlled translation workbook per product (separate patient/professional terminology); each key includes English source, screen/context, risk tier, Hausa/Igbo/Yoruba/French candidates, reviewer identity/date, status.
- At least one fluent reviewer plus a qualified clinical reviewer signs off any medical, safety, consent and medication language. Do not machine-translate unsupported medical text into the released app.
- Run a UI matrix on narrow phones and BlueStacks: onboarding, login, home, Nearby Care, bookings, call, provider profiles, payments, errors, support, profile and logout. Verify no overflow, wrong direction, crash, missing placeholders or fall-through to raw key names.
- Confirm saved language persists across app relaunch and does not reset sessions, duplicate submissions or reinterpret stored clinical data. Check switching while an appointment form is partially completed.
- Test low-bandwidth and offline behavior for language files already bundled in the APK; switching language must not require new backend requests.
- Report **language selector available, translations partial** until each selected language passes review, regardless of whether the English fallback works.

Counts reflect the refs inspected; remeasure after translation changes. No clinical translation is added by this audit.
