# Care360 Patient — Workforce recruitment privacy release gate

Date: 2026-11-08  
State: draft code, disabled pilot, **no real applicant collection**.

## Finding
Workforce candidate/employer registration previously requested acceptance of a "recruitment privacy notice" without an independently reviewed Workforce-specific notice linked from the registration screen. The generic Care360 Patient PrivacyPolicy widget loads a clinical Patient privacy-policy response and cannot be presumed sufficient for graduate/employer recruitment.

## Changes in this branch
1. A separate `WorkforceNoticeGate` requires an explicitly configured, dedicated HTTPS Care360-hosted recruitment notice URL (`K3_WORKFORCE_PRIVACY_NOTICE_URL`) before the app permits registration. It rejects plaintext HTTP, other organizations' domains, URLs with embedded credentials, query/fragment tokens and a generic homepage.
2. `WorkforceDataUseNotice` describes candidate profile collection, independently approved employer access, separate candidate listing consent, employer organization verification, no access to clinical records, and no promise of a placement. It does not replace the formal published notice.
3. The registration screen disables the consent checkbox and account creation when no notice is configured. A secure sign-in route remains available for existing records.
4. The API also checks the requirement before transmitting an applicant's name, email and password. The previous mandatory Workforce HTTPS check and separate Workforce login token remain in place.
5. The app-wide and backend Workforce pilot flags remain **OFF by default**; this URL guard does not open the pilot.

## What deployment must still obtain
- A separately approved recruitment privacy notice, hosted at a durable Care360 HTTPS URL, covering candidate/employer processing purposes, lawful basis, independently verified qualifications, data fields, access, retention/deletion, consent withdrawal, contact details, cross-border processing where applicable, and Nigerian data-protection and healthcare workforce obligations. Review with counsel/privacy officer.
- After publishing and verifying the notice content, configure `--dart-define=K3_WORKFORCE_PRIVACY_NOTICE_URL=https://care360apps.com/<reviewed-notice-path>`. **This is an instruction format, not a claim that the URL exists now.** Build/testing with fictional accounts only, then check user-visible consent and browser accessibility before enabling enrollment.
- Server-side enforce published notice version and consent-record audit independently of the client, verify organization and candidate credentials, and require a separate positive candidate visibility opt-in.
- Keep public registration OFF until backend security, migration and healthcare/legal compliance signoffs are complete.

## Test evidence
`test/care360_workforce_privacy_notice_gate_test.dart` checks safe/unsafe notice URL handling, role-specific data summaries, disabled consent/signup and API fail-closed behavior. It is included in the pinned public synthetic Flutter suite. Tests must finish green before this draft is considered verified.

## No changes to
Patient clinical authentication, prescriptions, appointments, real healthcare service directories, language switching, maps, AI, advertising, or Doctor/Plus application. No APK build or deployment was performed.
