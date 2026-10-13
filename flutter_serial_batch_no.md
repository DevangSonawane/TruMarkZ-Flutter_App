# Batch Serial Number — Flutter (Organization-Side) Integration Guide

**Audience:** Flutter developer(s) working on the organization-side app.
**Scope:** Organization batch-details screen only. Verifier-page, Superadmin-UI, filename-matching internals, Product QR internals, Human template changes, and Warranty are out of scope for this document — see `web_serial_batch_no.md` if you need those.

This document was written by reading the actual backend source in `api/routers/verification.py`, `api/schemas/verification.py`, and `api/services/verification_service.py`, plus their existing tests. No endpoint, field, or behavior described here is assumed — every claim below is traceable to that code.

---

## 1. Purpose and scope

TruMarkZ batches (Human or Product) can now show each batch user a short, human-readable **batch serial** — e.g. `SM-01`, `SM-02`, `SM-03` — built from the organization's initials plus a sequential number.

**What it's for:** when a third-party verifier is sent a batch's users to check, they come back with a report file per person. The serial gives a short, typeable label the verifier can put in their report's filename (e.g. `SM-01.pdf`) so the backend can automatically match the file to the right person — instead of the verifier needing to know or copy-paste a UUID.

**Important — this is NOT a permanent ID:**
- The batch serial is **not stored anywhere in the database**. It is recalculated on every API call from the batch's current user list.
- It is **scoped to one batch** — numbering restarts at `-01` for every new batch, even for the same organization.
- It can **change** if the batch's user population or ordering changes between two calls (see §4).
- `BatchUser.id` (the UUID) remains the real, permanent identifier for a person. The serial is a display/matching convenience layered on top — never use it as a database key or store it anywhere persistent in the app.

---

## 2. Organization-side changes

### Endpoint

```
GET /verification/batches/{batch_id}
```

- **Method:** GET
- **Auth:** organization bearer token (existing `require_org` dependency) — same as before, nothing new to configure.
- **Path parameter:** `batch_id` (string, UUID) — the batch to load. Same as the existing call.

This is an **existing endpoint** — no new endpoint was added. The only change is one additive field per user in the response.

### Response field

Each entry in the response's `users` array now has an additional field:

```json
"batch_serial": "SM-01"
```

- **Type:** string or `null`.
- **Position:** top-level key inside each object in `users[]`, immediately after `full_name`.
- **Nullability:** `null` only in the rare case the backend couldn't resolve the batch/organization internally (a defensive fallback, not an expected case in normal operation) — the field is always present as a key, but its value can be `null`. Always null-check before displaying.

### Realistic response example

```json
{
  "batch_id": "b2f8e3a0-1111-4a2b-9c3d-abcdef123456",
  "batch_name": "October Field Verification",
  "batch_type": "human",
  "description": "Field staff verification batch",
  "industry_type": ["Logistics"],
  "verification_types": [
    { "id": "...", "name": "Police Verification", "label": "manual" }
  ],
  "credential_visibility": "private",
  "total_users": 2,
  "verification_progress": {},
  "excel_storage_path": "org_.../batch_excels/...",
  "users": [
    {
      "user_id": "a1b2c3d4-0000-4000-8000-000000000001",
      "full_name": "Shivam",
      "batch_serial": "SM-01",
      "email": "shivam@example.com",
      "phone_number": "9999999999",
      "document_type": "aadhaar",
      "documents": [],
      "dob": "01-01-1995",
      "license_number": null,
      "aadhar_number": "XXXXXXXXXXXX",
      "pan_number": null,
      "address_line1": null,
      "address_line2": null,
      "address_line3": null,
      "pincode": null,
      "state": null,
      "country": null,
      "photo_url": "https://.../photo.jpg",
      "custom_fields": {},
      "verification_status": "pending",
      "verification_reason": null,
      "verification_type_status": {}
    },
    {
      "user_id": "a1b2c3d4-0000-4000-8000-000000000002",
      "full_name": "Siddhesh",
      "batch_serial": "SM-02",
      "email": "siddhesh@example.com",
      "...": "..."
    }
  ]
}
```

*(Field list above is the actual, current shape of each user object — not abbreviated for this example; some fields are omitted from the second entry with `"..."` purely for document brevity.)*

### UI change needed

The organization batch-details screen should display `batch_serial` next to the user's `full_name` — e.g. `"Shivam SM-01"` or `"Shivam · SM-01"` — so the organization can tell a verifier (by phone, email, chat, etc.) which serial corresponds to which person. **This UI change has not been made** — it is not part of the backend and must be implemented in the Flutter app.

---

## 3. API integration instructions

- **Continue using the existing `GET /verification/batches/{batch_id}` call.** No new endpoint exists for this feature, and none should be added — the backend already returns everything needed.
- **Every other existing field and behavior of this endpoint is unchanged.** `batch_serial` is purely additive; nothing was renamed, removed, or restructured.
- If your app currently deserializes this response into a typed model, add one new optional/nullable `String? batchSerial` field (or your project's naming convention) mapped from `batch_serial`. No other model changes are required for this feature.

---

## 4. Serial numbering behavior (as actually implemented)

- **Organization initials:** derived from the organization's name.
  - Multi-word name → first letter of the first two words (e.g. "Sunrise Manufacturing" → `SM`).
  - Single-word name → first two letters of that word (e.g. "Sunrise" → `SU`).
  - A blank/unreadable name falls back to `XX`.
- **Numbering:** sequential within the batch, zero-padded to at least two digits — `SM-01`, `SM-02`, ... `SM-10`, `SM-11`, etc.
- **Restarts per batch:** yes — a different batch for the same organization starts again at `-01`.
- **Ordering source:** the batch's users in their original creation order (oldest first), the same order the batch-details screen already lists them in — the serial is just that position, numbered.
- **Existing (older) batches:** get serials too, computed the same way, the first time anyone requests `GET /verification/batches/{batch_id}` for them — nothing needs to be backfilled or migrated.
- **Not stored:** confirmed — there is no database column or table for this. It is recalculated from the current user list on every request.
- **If the batch's user list changes:** since the serial is just "this person's position in the list," adding a new user to the end doesn't change anyone else's serial. If a user were ever removed from the batch (not part of this app's normal workflow — individual users aren't deleted here; a whole batch is deleted instead), the serials of users after the removed one would shift. The Flutter app does not need to handle this case specially — just always display whatever `batch_serial` the current API response says, never cache or recompute it yourself.

**Rule for Flutter: always read `batch_serial` fresh from this response. Never generate it client-side, never persist it, and never assume yesterday's value is still correct — reload the batch if you need an up-to-date serial.**

---

## 5. Organization workflow (example)

1. Organization opens the batch details screen → calls `GET /verification/batches/{batch_id}`.
2. Screen lists each user with their name and serial, e.g.:
   - **Shivam** — `SM-01`
   - **Siddhesh** — `SM-02`
   - **Priya** — `SM-03`
3. Organization sends the batch to a verifier (via the existing send-to-verifier flow — unchanged by this feature) and tells the verifier, informally or via the generated Excel attachment, "Shivam is SM-01, Siddhesh is SM-02, Priya is SM-03."
4. The verifier later uploads reports named `SM-01.pdf`, `SM-02.pdf`, `SM-03.pdf` through their own one-time link page (a separate, verifier-facing flow — not part of this Flutter integration).
5. Organization later reloads the batch details screen and sees each person's verification status update as the verifier's reports are processed — same existing flow as before, just now correctly attributed per person via the serial.

---

## 6. Compatibility and integration checklist

**Confirmed backend behavior (you can rely on this):**
- [x] `GET /verification/batches/{batch_id}` returns `batch_serial` per user, additive, backward compatible.
- [x] No new endpoint, no new auth requirement.
- [x] Serial is stable for the duration of a batch's unchanged user list.
- [x] Serial numbering restarts per batch.
- [x] Works for existing (already-created) batches with no migration needed.

**Frontend action required (not yet done — your work):**
- [ ] Add `batchSerial` (nullable string) to whatever model class deserializes this response.
- [ ] Display the serial next to each user's name on the batch-details screen.
- [ ] Null-check `batch_serial` before display (show nothing, or a neutral placeholder, if null — never show the literal string `"null"`).
- [ ] Do not cache `batch_serial` across screen reloads as if it were permanent — always use the latest response.
- [ ] Do not build any client-side logic that tries to compute or guess a serial — it must always come from this API response.
