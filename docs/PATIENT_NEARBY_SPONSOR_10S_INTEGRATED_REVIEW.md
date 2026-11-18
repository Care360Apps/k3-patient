# Care360 Patient — integrated 10-second sponsor and healthcare UX acceptance

**Status:** draft source integration for isolated staging only. No cloud Flutter compilation, connected BlueStacks review or production approval yet.

## Why this branch exists
The newer Patient PR #33 (Nearby Care and patient-home privacy) and earlier Patient sponsor PR #24/#34 were separate overlapping Home designs. This branch starts **from Patient PR #33's reviewed head** and ports the improved sponsor widget while retaining its Nearby Care and AI/language features. It is not an automatic replacement for either PR and must be conflict-reviewed before merging.

## What is implemented in this branch
- One partner/sponsor area on authenticated Patient Home; the duplicate raw Laravel banner slider is removed.
- Default **10 seconds** between slides, manual swipe, previous/next buttons, position indicator, pause when the app is backgrounded or accessibility animation is reduced.
- Sponsor labels distinguish **Sponsored** from non-paid **Partner** placements. Built-in MindCheck is identified as a separate SpeakOut service; partner links open externally with HTTPS-only validation and no appended patient information.
- Existing backend banner-response model now reads optional `is_sponsored` metadata. Missing description/title has a neutral fallback; disabled status and unsafe links are excluded. Server refresh **replaces** rather than appending duplicate slides. Existing valid banners remain on temporary network failures.
- AI Guide button still opens the existing curated navigation interface. **Generative remote AI remains OFF** in LAN; this code does not activate the draft backend PR #8 or transmit medical details.
- Existing Patient language switching, login, Nearby Care and appointment workflows are preserved at source level, not yet re-tested in the new APK.
- Focused widget/source tests check sponsored labels, 9/10-second behavior, safe URLs, no old duplicate slider, preserved AI Guide and five-language fallback.

## Visual acceptance for Nigerian and African patients
- Authentic locally resonant Nigerian/African healthcare photography (with image rights, subject consent, clear roles and accurate clinical setting). Proposed imagery: Nigerian nurse with patient at local clinic, female/male clinicians, pharmacy, lab technician, home-care provider, family consultation; varied ages and communities.
- Unified care identity: deep medical navy `#123E4D`, accessible teal `#087D76`, off-white `#F5F8F7`, white surfaces and restrained error/success colours. Avoid busy gradients, decorative text over faces, and long unstructured screens.
- Patient: clear Find Care / Nearby Care / Appointments / Profile navigation, obvious verified-provider distinction, low-bandwidth fallbacks, strong text contrast, minimum 48dp touch targets and adjustable font scaling.
- Keep commercial ads **outside medical consultation, diagnosis, test results, prescription, emergency, consent and payment views**. Sponsor approval is independent of clinical credentials.
- Care360 branding and finances stay separate from the SpeakOut nonprofit; MindCheck remains an attributed external partner in **Patient only**. Care360 Plus must have no Patient sponsorship banners.

## Required staging integration and external governance
1. **Backend:** sponsor scheduling and administration depends on **Care360Apps/k3-backend PR #18**. It is not verified/live. Administrator can approve image+copy+HTTPS destination, specify dates, mark Sponsored vs Partner and disable immediately; API returns only eligible active campaigns. Review migrations on the disposable local database before staging.
2. **Healthcare claims:** do not publish paid placements until an authorized admin checks health claims, professional credentials, relevant Nigerian advertising/ARCON requirements, consumer transparency and other sector rules. No sponsor targeting from symptoms, diagnoses, visits or geolocation; only anonymous aggregate counts if consent/privacy review permits.
3. **AI:** backend fixed-topic AI pilot **PR #8** remains disabled and requires dedicated HTTPS staging, consent and server key, multilingual/safety review, use limits and privacy assessment; no medical decision support in this phase.
4. **Translation:** English, Hausa, Igbo, Yoruba and French controls already exist in Patient; some strings fall back to English. Review medical terminology and errors with fluent reviewers. **Plus app** global language work exists separately; requires its own BlueStacks QA.
5. **Maps:** standalone public builder draft **PR #3** addresses staging Maps Android key and stable signing; the installed original APK's missing-map error remains until it compiles and is verified.
6. **Security:** backend privacy / old public medical file issues, live secret handling, payment and clinical workflow acceptance remain handover blockers.

## BlueStacks acceptance tests
| Scenario | Expected behaviour |
| --- | --- |
| Patient launches/signs in using fictional user | Dashboard appears without crash, Nearby Care and booked appointments remain reachable |
| Sponsor 10-second timer | Same first card at 9 s, next card after 10 s; no duplicate area lower on home |
| Manual control | Swipe, previous/next and numbered dots work; no unexpected auto-navigation |
| Accessibility | Reduced motion stops autoplay; screen-reader announces Sponsored vs Partner |
| External link | HTTPS only, warns/clearly marks leaving Care360; never shares account or health state |
| No eligible sponsor | Built-in attributed partner appears; no blank or endlessly loading cards |
| Bad banner image/URL | Placeholder image or banner excluded; no app crash |
| Backend refresh | Updated campaigns replace old records, not repeat them |
| Patient languages | Switch all five across sign-in, Home, maps, settings, booking and relaunch; persist choice |
| AI navigation | Offline curated help works; no generative call on LAN, no tokens or medical details sent |
| Plus | Separately verify Doctor and Provider roles, no sponsor banner/MindCheck, language controls |
| Clinical QA | Appointments, teleconsultation, notes, pharmacy, privacy/consent and role controls still work |

**Do not merge/deploy or deliver to publisher** until the above tests and original Care360 security blockers have been independently signed off. Developer, not this review branch, owns Play Store signing and submission.
