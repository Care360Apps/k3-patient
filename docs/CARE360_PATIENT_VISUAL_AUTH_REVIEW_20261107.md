# Care360 Patient — visual-first welcome, sign-in and registration review

Status: **DRAFT. No new APK built.**

## Visual and interaction changes
- Uses Care360's actual checked-in wordmark and clinician/family care photos; no generated replacement logo.
- Unified medical navy (#123E4D), teal (#087D76), soft neutral backdrop (#F5F8F7) for three onboarding slides, patient sign-in card and patient registration.
- Sign-in's existing email/password controls use 48px+ touch targets, labeled Material form fields, visible focus indicators, screen-reader-friendly password show/hide control, email/password autofill and a scrollable form for narrow phones and large text.
- Password recovery and account registration use the original named routes: `ForgotPasswordScreen`, `SignUp`; the actual existing `callForLogin`, Firebase custom token, backend auth token and OTP/phone verification logic remain intact.
- Signup still uses its existing Date of Birth, gender, phone-country selector, patient registration API and phone-verification route. Its prefix hint now shows Nigeria (+234) instead of India (+91); users still choose their own country code. This is a visual hint, not a hardcoded country-code default.
- Registration failures and optional settings failures no longer print full upstream exception and stack trace details that might include request metadata.
- Onboarding remains three images, three steps, Skip/Continue/Get Started with `Preferences.onboarding_seen` tracking. Previous returning-user session route is unchanged.
- CNU Medical Institute attribution is preserved on auth surfaces.

## Required visual acceptance
1. Splash uses approved actual Care360 master image; 160x160 master is low-res and needs higher-resolution official export before store release.
2. Device sizes 320x568, ~390x844 and 430x932; font scaling at 1.0, 1.4 and 1.6; keyboard open/closed; TalkBack labels and 48px+ controls.
3. Switch English/Hausa/Igbo/Yoruba/French from first-launch screen and existing sign-in/register language control without Flutter red screen or loss of form values.
4. Synthetic registered and returning patients can sign in, recover password, complete phone verification and navigate to Home without losing appointments, clinical records, pharmacy/doctor/Workforce/Maps links.
5. Network failures must not prompt for GPS or expose upstream exceptions, API credentials or real patient data in logs.
6. Do not claim full translation coverage or a functioning Workforce hiring/chat service—both remain separately gated.

## QA
Synthetic Flutter widget/source test: `test/care360_patient_auth_visual_review_test.dart`. Public runner branch `feat/patient-first-entry-visual-qa-20261107` includes all previous Patient tests.

**Keep this branch stacked on** first-language PR #40, which itself is stacked on Patient Workforce PR #39 and integrated Patient PR #35. Do not merge directly into production without complete security and backend readiness. Final staged Android APK should be built **once** after all visual approvals and integration testing.
