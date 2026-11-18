# Care360 Patient — Nearby Care marketplace architecture
Owner product direction: 7 November 2026. Scope: Care360 Patient + doctor/provider onboarding.
**Do not replace working care workflows or use private production medical data to demo maps.**

## Product principle

Care360 should match a patient to **the closest suitable, qualified, actually available**
doctor/provider/health facility—not merely show every registered profile or an arbitrary
shortest straight-line distance. Uber/Bolt supply the interaction pattern; healthcare
requires extra privacy, qualification, scope-of-practice and clinical safeguards.

## Current code and current map PR

Source baseline: Patient PR #31 and current Google Map screen `lib/Screen/Screens/MapView.dart`.
Already present: Google Maps, patient-position marker, distinct doctor/provider/hospital/lab
markers, distance calculations, doctor/provider profile navigation, backend doctor/provider
search endpoints and provider service capabilities.

This draft adds:
- Provider count/legend on the map (previously present in data but not represented correctly).
- Doctor/provider map and nearest profile discovery ordered by approximate distance.
- Filters All / Doctors / Providers / Hospitals / Labs.
- A nearest-professional swipe row that opens the **existing real** Doctor/Provider detail
  routes, rather than demo booking or synthetic records.
- Provider `limit=50` request matching backend max=50 (prior `100` was rejected by API).
- GPS dot enabled only when device location permission is already granted.
- No false 'available now', drive-time ETA, live tracking, price estimate or booking guarantee.
- Safe empty-location guidance and avoidance of late async setState after page disposal.

Backend provider-discovery draft **PR #25** makes Patient Provider list/detail honor
existing approval/fill/subscription/status gates. It also prevents missing provider
coordinates from appearing as 0,0. **Deploy backend changes only after staging QA**.

## Required roles and service catalog

**Doctor:** verified professional credentials, public practice/clinic details and
available virtual consultation slots. Preserve the current rule excluding home
visits for doctors unless the product owner and clinical compliance lead approve
an explicitly new capability.

**Care provider:** verified provider identity/qualification, supported services
(home visit, video, audio, chat as enabled), fees, on-duty state, service radius,
and optional place of work.

**Hospital, pharmacy and lab:** verified facility address and relevant opening
hours/service capabilities. Do not call a closed pharmacy or lab 'available now'.

**Patient:** opt-in location or manually selected area; select category/service,
compare suitable professionals and request care using existing authentication,
appointments and payment methods.

## Availability is not the same as map proximity

Model three distinct states explicitly:
- **Listed:** identity verified, active, approved, published practice/service area.
- **Accepting requests:** provider opted in; correct scope/service type; open slot
  or on-duty state; capacity and subscription/current eligibility checked on server.
- **Booked / on the way / in service:** request accepted and currently active;
  live location (where needed) is consented, purpose-limited and expires.

**No server-side availability feed or request/accept dispatch is proven live yet.**
Never label every pinned professional as 'Available now'.

## Core discovery and dispatch phases

### Phase A — review-ready map (this PR)

Show permitted registered service locations and actual nearby options. Use
straight-line km clearly labelled approximate, then open working professional
profiles. Manual address choice works without GPS permission.

### Phase B — true availability and relevance

Design backend-owned, indexed query
`GET /api/nearby-care?lat=...&lng=...&radius_km=...&type=...&service=...`
(or matching existing app convention):
- Filter on **admin approval + verified credentials**, active account, service offered,
  allowed clinic/home/virtual role, effective on-duty/working-hours/time-slot
  state, service radius and actual business/service-area coordinates.
- Return only minimal public fields, publication-approved location, approximate
  distance, allowed services, rates and snapshot timestamp. No DOB, government ID,
  phone number, clinical data, raw device GPS or private residence.
- Use indexed geo bounding-box / spatial query before exact distance ordering;
  paginate; don't load all providers for every map pan or call a distance
  calculation on every DB row. Bound radius and results at server.
- Distinguish approximate straight-line distance from **routing/driving ETA**
  computed using a provider maps/routes service, when correctly configured.
- Reject stale states and revalidate availability transactionally during booking.

### Phase C — Uber-style service request and lifecycle

Request -> professional notified -> accept/reject/expiry -> confirmed booking
and payment authorization -> home-visit dispatch (when supported) ->
professional traveling -> arrived -> care completed -> billing/receipt ->
verified post-service review.

State transitions must be idempotent and authorized. Patient cancellation
and provider unavailability need timeouts, cancellation rules and dispute
support; payment is never marked paid just because an appointment is complete.
Keep live clinical data out of location/push payloads.

### Phase D — live arrival tracking, only when necessary

Do not publish raw home addresses or continuous doctor/provider movement
for browsing users. The provider explicitly publishes a clinic/public
service location or coarse service area. During an accepted home visit only,
the assigned patient and provider may opt into short-lived route/location
updates; stop and delete tracking on completion, cancellation, timeout or
consent withdrawal. Never publicly map a professional's precise personal
whereabouts.

For virtual consultations, no travel tracking or patient GPS should be
required.

## Test acceptance on staging

1. Seed **synthetic** patients, approved/unapproved doctors and providers,
   registered office locations, home-service radii and slot availability.
2. Different patients near and far see appropriately ranked, permitted
   professionals; no registered-but-unapproved listing appears.
3. `0,0`, missing/invalid coordinates and location denial don't show false
   nearby results or crash; manual location works.
4. Nearest profile card opens the correct Doctor or Provider detail page.
5. No claim of 'available now' until actual availability is queried and
   revalidated during booking.
6. Map marker count, legend, filters and screen reader labels work at
   360px width; test BlueStacks Android Pie 64-bit, a physical Android,
   and iOS/TestFlight.
7. Basic performance: bounded requests, result pagination, cancel stale
   map queries, no extra automatic GPS prompts or exposing access tokens
   in logs.
8. Security: patients cannot see live/precise provider home addresses,
   access unapproved profiles, spoof accepted jobs or view another
   patient's booking/tracking; precise tracking is opt-in and time-limited.

## Developer handoff dependencies

The owner's approved Patient review branch remains PR #31; this map draft
is a stacked follow-up. Backend provider visibility is draft PR #25.
Secure medical file migration (backend issue #22), payment integrity,
auth and previous security report are **independent release blockers**.

The original developer retains ownership of Play Store and Apple App Store
signing and publishing. This source update is **not yet an app-store release**.
