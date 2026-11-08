# Care360 healthcare service screens — visual-first source review

Date: 2026-11-08  
Status: **DRAFT, no APK built, no production deployment.**  
Patient branch `feat/patient-services-visual-20261108` (PR #45), stacked on Patient dashboard PR #44.  
Plus branch `feat/plus-services-visual-20261108` (PR #33), stacked on Plus dashboard PR #32.

## Corrected functional route
The Patient dashboard's Hospitals action previously navigated to `'Hospitals': (context) => HospitalsScreen()`, which renders only a 'Find Hospitals' placeholder. The source already contains `HospitalScreen` with API-backed hospital search/filtering in `lib/Screen/Screens/Laboratory.dart`. The route is now `'Hospitals': (context) => HospitalScreen()`. The old stub file remains unused pending downstream code review; no new API endpoint or device permission is introduced.

## Common Patient service design
The new `lib/brand/care360_service_intro.dart` provides one accessible, consistent introduction for real Hospital, Laboratory, Doctors/Treatments, Provider discovery and Pharmacy directories:
- Navy #123E4D, teal #087D76, pale green background, readable title, concise service description, service-specific icon.
- Keeps each old screen's actual REST client, search bar, filter selection, list/grid and existing detail/booking route.
- Does not request location, fetch medical records or use Workforce credentials.
- Does not insert advertising into clinical/appointment/medical-record flows.
- No new background network calls or permissions.

## Plus medical service design
The new `lib/brand/care360_professional_section_intro.dart` provides consistent, semantic headers in **Appointment History** and appointment-scoped **Clinical Notes**. Existing doctor-notes API, finalized-note protections, tab data, role/clinic permissions and private patient information are untouched. No sponsors are placed inside records.

## Acceptance checks
- [ ] Navigate Home > Hospitals and confirm actual results from staging rather than placeholder. Verify searching and near-me filter only when a location is available.
- [ ] Repeat lab, pharmacy, doctor-specialty and provider searches with fictional records. Confirm their existing API error states.
- [ ] Test text sizing at 320px/390px/430px widths, screen reader headings, tap targets and device rotation constraints.
- [ ] Test switch-language behavior across directories. New short intro copy is English pending reviewed Hausa, Igbo, Yoruba and French translations; do not claim translation complete.
- [ ] Confirm existing appointment detail, prescription, booking, payments and video calls continue to work; no new authorization bypass from dashboard.
- [ ] Plus Doctor/Provider: appointment history, draft/finalize notes and provider availability with separate fictional users.
- [ ] Review clinical privacy and old security audit findings. UI tests do **not** close the security audit.
- [ ] After sign-off, produce just **one** consolidated encrypted Android review build, then BlueStacks acceptance and developer source handoff.

## Code-level tests
Patient: `flutter test test/care360_service_directory_visual_test.dart` plus the existing Patient suite in public builder branch `feat/care360-services-visual-qa-20261108`.

Plus: `flutter test test/care360_plus_service_visual_test.dart` plus the existing Doctor/Provider suite. Current private Plus workflow has failed before reliable report generation; this is not a verified pass.
