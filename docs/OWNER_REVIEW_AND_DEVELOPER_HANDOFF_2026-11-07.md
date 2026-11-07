# Care360 Patient — Owner review and developer handoff
Date: 7 November 2026
Status: DRAFT / NOT FOR PLAY STORE OR APP STORE PUBLISHING

## Responsibility

**Owner / product review:** Approve Care360 Patient screens, navigation,
language switching, curated AI Guide, accessibility and stable existing
clinical functions using an isolated BlueStacks synthetic APK, followed
by a connected staging APK.

**Original developer / publisher:** Review and integrate approved changes,
configure correct production backend/Firebase, sign Android AAB and iOS IPA
using existing app/store identities and keys, run real-device regression
tests, deliver to Play internal test and TestFlight, then submit store updates.

## Recommended PR integration order

1. Patient diagnostics/offline preview PR #27. This review branch descends
   from its fixed SHA; avoid duplicate imports/cherry-picks.
2. Patient AI/language UI PR #29. Five-language selection on login/registration
   and synthetic preview; opt-in nonclinical Guide. **AI generation disabled
   by default**; backend draft AI PR #8 requires staging and privacy review.
3. Patient stacked PR #31 (this branch). Faster initial Home, cached/saved
   location before GPS, avoids permission prompt on launch, deduplicates
   appointment refresh, cancels polling on leaving Home, masks error logs,
   10/20/20 second Dio timeouts. No automatic retry of payments or bookings.
4. Patient store preparation PR #28 is independent; selectively reconcile
   signing/notification/privacy fixes after actual app/clinical QA, not
   wholesale and not blindly.
5. Backend payment integrity PR #21 and account deletion POST PR #20
   need isolated testing/deployment before compatible mobile release.
6. Backend private clinical document PR #24 only adds a **phase-1 route**.
   Old medical files remain exposed under public paths until the backend,
   client and server migration is completed; track issues #22 and #23.

## BlueStacks checklist (isolated synthetic only)

- [ ] APK package `com.cnu.patient.k3sandbox` opens without red/black screen.
- [ ] App icon and front-page branding correct.
- [ ] Sign-in language dropdown and sign-up language dropdown both work.
- [ ] Language label for gender is translated but backend value stays
      `Male` or `Female` in connected staging.
- [ ] Preview dashboard Home, Explore, Bookings and Profile navigation works.
- [ ] Care360 Guide opens, offers four curated nonclinical topics,
      never requests symptom history, and works with network disabled.
- [ ] No private customer records, Firebase tokens, live API or payment
      transactions appear in preview.

## Staging functionality and performance checklist (not yet verified)

- [ ] Backend and Firebase **isolated** from production; synthetic test
      users and patients only.
- [ ] Patient registration/OTP/sign-in/logout/recovery, 401 refresh and role
      isolation; no token or private data in logs.
- [ ] Doctor/provider discovery, pharmacy, prescription, appointment
      booking/cancellation/completion, payment sandbox, Agora/Zoom.
- [ ] Home renders with denied location permission; current location
      only requested where needed and after a user action.
- [ ] Saved/default location immediately populates nearby services.
- [ ] Appointment refresh never duplicates entries; no polling after Home
      disposal or sign-out.
- [ ] Measure cold-start to first usable screen and p50/p95 API latency
      on BlueStacks, physical Android and an iPhone with strong Wi-Fi,
      slow connection and denied network. Do **not** claim an unmeasured
      speed increase.
- [ ] Screens remain responsive while call/API errors appear; screen
      readers and large text support retained.
- [ ] Medical images/PDFs accessible only to authorized owner/assigned
      clinician; no public URL downloads before final release.
- [ ] Existing production credentials previously shared in handover
      securely rotated by authorized Namecheap administrator, with
      backups, re-encryption plan and session revocation.
- [ ] Security retest against October audit and current GitHub matrix.
- [ ] Android physical-device upgrade/install and iOS/TestFlight tests.

## Handoff contents

- Source PR URLs and the **final tested immutable commit SHA**
- Screenshots from owner-approved synthetic and staging Android/iOS tests
- Change log and known defects; tests/actions with outcomes
- Integration test data generation instructions, without real medical data
- App package identities, dependencies and build versions
- A release checklist for existing store signing and distribution
- Documented rollback and server contract requirements

**Do not provide passwords, provider tokens, patient records, private
Firebase service keys or a production database copy to a public build runner
or a shared document.**

No live backend deployment, Apple/TestFlight upload or Google Play upload
is represented as completed by this plan.
