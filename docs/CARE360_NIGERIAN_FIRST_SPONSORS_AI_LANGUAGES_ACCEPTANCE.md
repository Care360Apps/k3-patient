# Care360 Nigerian-first UI, sponsorship, AI and language — acceptance plan
Status: implementation baseline and design/QA specification on a draft stacked Patient branch. No production rollout authorized.
Owner goal: professionally polished, culturally familiar Patient and Plus apps before developer handover.

## Product identities and design
- Care360 is a healthcare product, independent of the SpeakOut Mental Health nonprofit. Patient and Plus share a coherent visual system but different clinical workflows. SpeakOut/MindCheck is an identified, separately operated external partner in **Patient only**.
- Use a consistent professional medical palette: high-contrast navy/teal, neutral white/grey, restrained success/warning/error colors. Establish spacing/typography/button/icon/card tokens rather than replacing clinical screens with disconnected mockups.
- Prioritize real, licensed, consented Nigerian and African healthcare photography: diverse doctors, nurses, pharmacists, technicians, patients, age groups and hospital/clinic contexts; realistic Keffi/Abuja and wider Nigeria/Africa rather than foreign-only or stereotypical stock scenes. Avoid implying specific photographed persons are licensed Care360 providers without consent.
- Keep photo treatments quiet behind text, no image-based critical instructions, graceful offline/error placeholders, 200% text sizing, tap targets >= 44/48 points, screen-reader labels, strong contrast, keyboard navigation and reduced-motion behavior.
- Patient: simple Find Care / Appointments / Care360 Guide / Profile, clear Nearby Care controls and privacy messages. Doctor: clinical notes, e-prescriptions, virtual visits, history and review. Provider: permitted virtual and home-visit availability. No sponsored material on consultation, prescription, results, consent, emergency or payment screens.

## Sponsor and partner placements
- Patient Home alone: a discoverable compact "Featured partners" carousel, **10-second default per slide**, manual swipe, next/previous arrows, current/total indicator, pause on accessibility reduced motion or background, never navigate automatically. Avoid persistent motion elsewhere.
- Labels distinguish **Sponsored** paid placements from **Partner** nonpaid recommendations. All sponsor creatives and links are approved; users always know a link leaves Care360; never assume a placement is a medical endorsement.
- Reuse the existing banner API and the separate backend campaign administration review PR #18. Administrator must approve/edit/disable/upload creatives, start/end date, and secure HTTPS URLs; expiry must hide campaigns; avoid duplicate banners; empty/error states must not crash Home. Do not deploy the backend PR without staging migration and regression QA.
- Sponsor creative sizing: design responsive aspect ratios and safe text areas, compress images, require meaningful alt text, subtitles/translations, validate external URLs, avoid collecting/sharing patient ID, search history, location, diagnosis, appointment history or any clinical signal with sponsors. Analytics: aggregate nonidentifying impressions only after privacy review; no health-based targeting.
- Exclude misleading medical claims, unlicensed providers, pharmaceutical claims lacking approval, unsafe supplements, and exploitative ads. Keep MindCheck's source and ownership transparent; do not misrepresent it as a Care360 medical diagnostic tool.
- Prior to commercial ad publication, have compliance review the applicable ARCON advertising/vetting requirements, including digital advertisements, any medical/product-specific approvals, and proof of clearance where required. Official references: https://www.advertcouncil.gov.ng/_adverts_vetting.php and https://advertcouncil.gov.ng/documents/Vetting%20Guidelines.pdf. Do not accept payment or guarantee campaign launch until terms and required approvals are clear.
- This integrated review branch is **stacked on the newest Patient Nearby Care draft PR #33**, and ports the ten-second carousel plus sponsored flag from the older PRs #24/#34. It replaces the old banner slider while preserving the existing Care360 Guide, language controls and Nearby Care. It remains unmerged; developer handoff requires QA and backend campaign administration review.

## AI delivery tiers
- Current: vetted, offline **nonclinical navigation guide** can answer fixed app-help topics. Its presence is not proof that generative AI is running.
- Pilot only: Patient AI Guide calls an authenticated, rate-limited, opt-in **server** route over verified HTTPS and sends only a fixed topic + language, never raw symptoms, notes, prescriptions, patient files or access tokens to an AI provider. The AI API key is server-side only. On failure, show the curated answer.
- Backend AI feature is draft PR #8 and disabled by default. The LAN debug API is HTTP and must NOT turn on the remote AI pilot. Verify privacy notices, operator cost caps, fraud/abuse limits, consent, language quality, response citation if appropriate, safety disclaimers and human escalation in isolated HTTPS staging before activating.
- No automatic diagnosis, prescribing, clinical triage, or replacement of care professionals. Clinical AI features, if later considered, require a distinct clinical governance and regulatory/security review.

## Localization
- Target consistently across Patient and Plus: English, Hausa, Igbo, Yoruba and French. Controls visible on sign-in/sign-up and accessible after login on every screen; selected locale persists on relaunch. Plus professional terminology and patient-facing clinical terminology need separately reviewed glossaries.
- Prefer source-authored translations; incomplete strings must fall back clearly to English, not synthetic/automatic medical translations. Review sign-up, consent, doctor/provider search, booking, map, error states, prescriptions, notifications and accessibility labels with native speakers.
- Verify longer strings do not clip at mobile screen widths or larger system fonts, and language changes do not reset authentication, lose unsaved work or trigger repeated API mutations. Preserve original API data, medication names and medical record correctness.

## Acceptance gates
1. Build both connected staging-debug APKs pinned to reviewed commits; no production credentials/clinical patients. Check Patient/Doctor/Provider login and role permissions, Firebase and isolated Laravel backend.
2. For Patient, run Flutter widget tests then BlueStacks: test sponsor carousel at 9 seconds (still visible), 10 seconds (advances), reduced motion, manual swipe, external HTTPS controls, 0/1/multiple active campaigns, expiry, invalid image, offline data and no clinical tracking.
3. Verify Patient language switching on sign-in and all selected screens, persistence after restart, each of five languages, accessibility and medical terminology review.
4. Verify Plus language switching across Doctor/Provider screens; ensure no patient-only MindCheck/ads leak into Plus. Verify role-specific clinical and home-visit controls.
5. AI: curated guide works offline; generative disabled in LAN. Validate later HTTPS staging opt-in flow, auth, rate limits, no PHI to model, safe fallback and actual response.
6. End-to-end functional acceptance: maps/address display with restricted signing and Maps key, Nearby Care eligibility, appointments, teleconsultation, doctor notes, prescriptions, pharmacy, provider visits, notifications and privacy/security blockers.
7. Record screenshots, accessibility observations, tests, blocked items and reviewed commit SHAs. No production readiness, developer handoff or store upload until outstanding data-access, secret and security gates have been independently verified.

Developer owns store signing/upload. Care360 operational expenses and sponsor receipts must remain separate from SpeakOut NGO finances.
