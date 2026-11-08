# Care360 coordinated dashboard — visual-first review
Date: 8 November 2026
Status: DRAFT UI code, no new APK built or production merge.

## Common design system
- Use only approved Care360 logo and artwork from the source repository; avoid AI-created replacement logos.
- Primary navy: `#123E4D`. Care teal: `#087D76`. Soft neutral background: `#F5F8F7`.
- Two-column cards on portrait phones; three or four columns only when horizontal space genuinely permits.
- High-contrast headings and labels, 48px minimum touch controls, scrolling and dynamic text-size support.
- Meaningful icons without decorative clutter; a single identifiable card for each task.
- Maintain the global language selector, acknowledge that translation coverage is not complete.

## Patient, source `lib/Screen/Screens/Home.dart`
The main Home retains the live search box, profile/cart/drawer, existing address and location controls, Nearby Care hero, sponsored showcase (10-second cycling logic already present), appointments, pharmacy/doctor/provider results, AI Guide and the separately gated Workforce landing.

A new `Care360PatientServiceGrid` shows six navigation destinations:
| Label | Existing destination | Notes |
| --- | --- | --- |
| Hospitals | `Hospitals` | Existing hospital discovery, not new API |
| Doctors | `Treatment` | Existing specialist selection |
| Providers | `FindProviders` | Existing provider browsing |
| Pharmacies | `AllPharamacy` | Existing pharmacy catalog |
| Laboratories | `Laboratory` | Existing lab browsing |
| Appointments | `Appointment` | Authenticated only; logged-out users go to SignIn |

Workforce remains a separate visually prominent section because it is still a disabled recruitment pilot, not an available commercial service. Doctor/provider booking results remain rendered below the discovery area.

## Care360 Plus, source `lib/screens/home page/login_home.dart`
Professional dashboard hero reuses the actual existing African clinician artwork. `Care360ProfessionalQuickActions` is rendered only in the existing subscribed/professional dashboard branch, not on the subscription-blocked state.

| Card | Existing destination |
| --- | --- |
| Appointments | `AppointmentHistoryScreen` |
| Schedule | `Schedule Timings` |
| Clinical notes | `Notes` |
| Messages | `ChatHome` |

The existing live appointment data, consultation/schedule models, doctor/provider profile approval checks, chats, payment paths and Nearby Care professional availability remain in place.

## Visual review (before APK)
1. Compare startup → language → welcome → sign-in → dashboard for Patient and Plus on 320px, 390px and 430px wide phones.
2. Review spacing and font enlargement at 100%, 140% and 160%; test keyboard open and screen reader accessibility.
3. Confirm every quick-action opens the correct existing route; no route navigates to a mocked live service.
4. Check preserving signed-in state, clinician authentication, appointment data and patient chart privacy.
5. Confirm ad placements never appear inside consultations, prescriptions, clinical notes or sensitive health records.
6. Verify no automatic GPS prompt from the dashboard grid and that logged-out appointment access requires sign-in.
7. Run Patient Flutter tests and Plus Flutter tests independently; document the actual outcome, not just a screenshot of design.
8. Only after all feature and security review gates are cleared, produce **one consolidated encrypted Android test APK** for BlueStacks. The original developer handles final release signing and Play Store distribution.

## Open security gates
The 9 October 2026 handover audit is NOT closed. Payment verification, OTP/account recovery, transport certificate validation, exposed credentials, production debug configuration, role approvals, public medical file access and other items require independent remediation evidence, backend test results and deployment verification. Passing dashboard widget tests does not resolve any audit finding.

## Branches
- Patient: `feat/patient-dashboard-visual-20261108`, PR #44
- Plus: `feat/plus-dashboard-visual-20261108`, PR #32
- Patient isolated CI: `feat/care360-dashboard-visual-qa-20261108`
