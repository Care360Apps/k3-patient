# CARE360 PATIENT — Prompt 2: navigation localization & Workforce transport review

Date: 8 November 2026  
Status: DRAFT source; no APK, merge, database migration or production deployment.

## Scope and source preservation

This branch stacks on Patient private-prescription PR #46. It **does not** replace authentication, the real Hospitals/Laboratory/Doctors/Provider/Pharmacy routes, appointment logic, protected PDFs, AI Guide, Maps proxy, paid partner showcase, or separate Workforce candidate/employer backend. It uses the original official Care360 logo and checked-in healthcare images.

## Implemented in this slice

- Added **21 navigation-only keys in each of five languages** (English, Hausa, Igbo, Yoruba, French) using the existing overlay localization files.
- The six Patient dashboard service cards, section heading, descriptive copy and five service-directory headings now look up these localized strings. Missing keys continue to display English, never `null` or unreviewed machine-generated clinical claims.
- Card labels support two-line wrapping with a taller layout when system text scaling is increased; no extra hidden tabs or popup routing.
- Workforce tile remains available as an **informational preview**, not an operational verified hiring marketplace. Its subtitle clearly identifies a pilot rather than claiming already-verified candidates. No signup or employer candidate search is enabled by this change.
- Workforce's **separate** secure API client now refuses any plaintext HTTP origin before requesting pilot status, registration, login or authenticated profile data. A compile-time flag `K3_ALLOW_LOCAL_WORKFORCE_HTTP` permits **localhost/127.0.0.1/::1 only** for deliberate test builds, never LAN IP/public remote HTTP. When the server returns 401 for an authenticated Workforce call, the cached Workforce-only token is deleted. Patient clinical OAuth credentials remain separate.
- No new permissions, analytics of candidate data, salary claims, credential verification shortcuts or patient-to-Workforce data sharing.

## Verification

Patient source/widget regression suite: `test/care360_patient_prompt2_localization_workforce_test.dart` plus existing Patient tests in the public *source-only* isolated CI, branch `feat/patient-prompt2-i18n-workforce-qa-20261108`. Tests include all 21 JSON keys for all five languages; switching between Hausa and French; Yoruba small-screen text; and remote/loopback HTTP rejection before Workforce registration. **A test run is not a live app backend/institutional verification.**

## Remaining acceptance gates

1. Have Hausa, Igbo, Yoruba and French native-speaking clinical/community reviewers check vocabulary, diacritics, age/credential distinctions and accessibility. These 21 strings are navigation drafts; the broader app, prescriptions and medical consent are **not fully translated**.
2. Validate first-launch selection and live language switching on real Android, including large fonts, text overflow and route preservation. Do not replace clinical answers with speculative translation.
3. Keep Workforce server feature flag `K3_WORKFORCE_PILOT_ENABLED=false` and app build flag `K3_WORKFORCE_PILOT=false` until independent email verification, school/professional credential checks, employer vetting, labor/healthcare compliance and data retention/reporting are approved.
4. Verify the separate Workforce login token is revoked server-side, archived on logout and never sent over HTTP. Do not route Patient medical history, prescriptions or demographics into recruitment profiles.
5. Production release remains blocked by the historical public medical-file migration, credential/OTP/payment security, Plus/backend Flutter/PHP verification, and completed joint synthetic-account staging tests.

This is a **Patient-only Prompt 2** review branch and intentionally does not merge or alter the dedicated Plus or Backend repositories.
