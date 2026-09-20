# TruMarkZ — Organization Flutter App Integration Notes

**Scope of this document: ORGANIZATION-SIDE only.** SuperAdmin-only functionality
(e.g. the rejected-list send action) is deliberately excluded — see
`trumarkz_changes.md` for the complete backend change log covering SuperAdmin,
Human, Product, and Warranty.

This document covers the organization-visible surface of the six recently
implemented backend changes, verified against current source.

---

## What changed, from the organization app's point of view

Two existing endpoints the organization app already calls now return additional
fields. **No existing field was removed or renamed, and no new authentication
requirement was added.**

### 1. `GET /verification/batches/{batch_id}` — Auth: Bearer token (organization or super_admin)

Each entry in the existing `users[]` array gains one new top-level field, and each
type inside the existing `verification_type_status` object may gain up to two new
keys:

```json
{
  "users": [
    {
      "user_id": "...",
      "full_name": "Rahul",
      "verification_status": "rejected",
      "overall_status_label": "partially_verified",
      "verification_type_status": {
        "Police Verification": {
          "status": "approved",
          "label": "manual",
          "report_url": "https://.../verification/manual/reports/<request_id>/view/1"
        },
        "Driving License Verification": {
          "status": "rejected",
          "label": "automatic",
          "detail": "No licence record found for these details",
          "rejection_reason": "No licence record found for these details"
        }
      }
    }
  ]
}
```

**New field: `overall_status_label`** (also present on `users[]` in the batch-detail
response, and on `BatchUserDetail` from `GET /verification/all` and
`GET /verification/user/{user_id}`). One of:
- `"verified"` — every verification type for this user is approved.
- `"partially_verified"` — at least one type is approved, but not all of them
  (whether the rest are still pending, or one was rejected).
- `"rejected"` — nothing is approved, and at least one type is rejected.
- `"pending"` — nothing approved and nothing rejected yet (or no verification
  types at all).

**Which field to use for what:**
- Use **`overall_status_label`** for the new user-facing overall status display
  (`verified` / `partially_verified` / `rejected` / `pending`) — this is the field
  intended for showing a person the outcome of their verification.
- Continue using **`verification_status`** (`pending` / `approved` / `rejected` —
  already documented, already what the app reads today) for any existing logic
  that depends on it — it is **unchanged** and still present; nothing about its
  values or meaning was altered.

**This is a backend-only change — no Flutter code or UI has been modified as part
of implementing it.** This document describes the API contract only; whether and
how the organization app's UI adopts `overall_status_label` (e.g. a distinct
"Partially Verified" chip) is a frontend implementation task still to be done.

**New key inside `verification_type_status[type]`: `rejection_reason`** — present
only when that specific type's `status` is `"rejected"` and there is real reason
text to show. Sourced from whichever underlying field already existed for that
verification path:
- Manual/third-party rejections: same text as the existing `reason` key (still
  present, unchanged).
- Automatic rejections (Driving License / Photo Verification / Criminal
  Background Check): same text as the existing `detail` key (still present,
  unchanged).

If the app was already reading `reason`/`detail` for a rejection message, no
change is required — `rejection_reason` is simply a second, consistently-named
place to find the same text, useful if the UI wants one code path instead of
branching on verification label ("manual" vs "automatic").

**New key inside `verification_type_status[type]`: `report_url`** — present only
once a manual/third-party verification decision has been made **and** a report was
actually uploaded for it. **Two different shapes exist — check which one you're
looking at:**
- **Automatic verification types** (Driving License, Photo Verification, Criminal
  Background Check): `report_url` is a raw `gs://...` path — a private storage
  identifier, not a web URL. **Flutter must NOT attempt to open this directly**
  (no HTTP scheme, not publicly reachable, no credentials attached — it will not
  load in a browser/webview). This is pre-existing behavior, not new — it was
  already there before these six changes. If the app needs to display this
  report, it needs the proxy mechanism the backend already uses internally
  (`GET /verification/documents/{document_id}/view`) rather than the raw path
  itself — but as of this writing there is no API that hands the app that
  document's id directly from this field, so **automatic reports are not yet
  safely viewable from `verification_type_status` alone.** (Flag this if the org
  app needs to link out to automatic reports — it would need a small additional
  backend change to expose the underlying document id or a proxy URL here.)
- **Manual/third-party verification types**: `report_url` is a ready-to-use public
  HTTPS link — `PUBLIC_API_BASE/verification/manual/reports/{request_id}/view/{n}`
  — safe to open directly (e.g. in a webview or external browser), no auth token
  needed.

**Per-user correctness:** when a manual verification request covered more than one
user and the verifier's upload explicitly tagged each file to its user (a backend
capability, not something the app currently has to do anything for), each user's
`report_url` points at their own file. If no explicit tagging was done, every user
covered by that request shares the same report link — this was already true before
these changes and still is; it is not a bug.

**What this does NOT cover — do not assume these are the same field:**
- **Product QR reports** (`custom_fields["third+party+qr1"]` through `qr4`) are a
  **separate** mechanism, unrelated to `verification_type_status.report_url`. If
  the app displays Product verification reports today via `custom_fields`, that
  code path is completely unaffected and unchanged by any of these six changes.
- **Warranty documents** (`custom_fields["warrenty_report"]` and
  `custom_fields["product_details"]`) are likewise a **separate, unrelated**
  mechanism — see the Warranty section below. Not touched by `report_url` in
  `verification_type_status` at all, for the normal Warranty upload flow.

### 2. Manual verification upload — verified as **verifier-facing, not organization-facing**

`POST /verification/manual/upload/{token}` (where the verifier's file(s) are
submitted) gained an optional `batch_user_ids` form field. **This endpoint is
called by the third-party verifier via their emailed upload link, not by the
organization Flutter app** — confirmed from source, this route takes no
organization/user auth at all (token-only). It is documented here only so the
organization app's engineers understand *why* `report_url` can now be precise
per-user in the batch-detail response above — there is nothing for the
organization app itself to call or change here.

---

## Organization-Side API Table (verified endpoints only)

| Method | Endpoint | Auth | Purpose | What's new for the org app |
|---|---|---|---|---|
| GET | `/verification/batches/{batch_id}` | Bearer (organization; scoped to own batch, 404 for another org's) | Full batch detail | `overall_status_label` per user; `report_url`/`rejection_reason` inside `verification_type_status[type]` |
| GET | `/verification/all` | Bearer (any authenticated user; org callers are scoped to their own org via `scope_org_filter`) | List verifications with filters | `BatchUserDetail.overall_status_label` |
| GET | `/verification/user/{user_id}` | Bearer | Single user verification detail | `BatchUserDetail.overall_status_label` |
| GET | `/verification/manual/reports/{request_id}/view/{file_index}` | **None — intentionally public** (unguessable UUID + index; designed so Dhiway/certificate viewers can open it with no login) | Open a manual-verification report inline | Unchanged by these six changes — documented here only because it's the shape `report_url` now points to |
| GET | `/verification/manual/reports/{request_id}/download/{file_index}` | Bearer (organization; own batch only, or super_admin) | Download a manual-verification report file | Unchanged |

**Nothing else needed to be added here.** No new organization-facing endpoint was
created by these six changes — both org-relevant response changes ride on
endpoints the app already calls.

---

## Human / Product / Warranty — what the organization app should know

### Human
- `report_url` for a manual (third-party) verification type is a proxy link, safe
  to open directly.
- `report_url` for an automatic verification type (Driving License, Photo
  Verification, Criminal Background Check) is a raw `gs://` storage path — **must
  NOT be opened directly**; it is not yet safely linkable from the app without an
  additional backend change (see above).
- `overall_status_label` behaves the same for Human as everywhere else.
- Nothing about Human Excel upload, OCR upload, or single-user creation changed.

### Product
- Product's existing QR report display mechanism (`custom_fields["third+party+qr1..4"]`)
  is **completely separate** from `verification_type_status.report_url` and was
  **not** changed. If the app already reads QR reports from `custom_fields`, no
  change is needed there.
- `overall_status_label`/`rejection_reason` apply to Product verification types
  the same way as Human.

### Warranty — read this carefully, it is easy to conflate with the manual-verification changes above
- The organization app's **normal** Warranty document display should continue
  reading `custom_fields["warrenty_report"]` and `custom_fields["product_details"]`
  — **exact field names, verified from source** (note `warrenty_report` is spelled
  to match Dhiway's own schema field, with only one "n"). These are **not**
  affected by any of these six changes and do **not** appear inside
  `verification_type_status`.
- These two fields are populated by the organization itself uploading documents
  (via the existing product/warranty document upload endpoints — unrelated to the
  verifier-upload flow described above), each scoped unambiguously to one specific
  product (`batch_user_id`) or by that product's unique `serial_no`. Nothing here
  changed.
- `overall_status_label`/`rejection_reason`/manual `report_url` only become
  relevant for a Warranty batch **if** it additionally uses the optional
  `"Warranty Verification"` verification type sent to a third-party reviewer — a
  separate, optional feature layered on top of the normal document workflow, not
  the default path. If the organization app doesn't use that optional flow today,
  none of the Change 2/4/6 fields will ever appear for that batch's Warranty
  products.

---

## SuperAdmin-only functionality — intentionally excluded from this document

The following were implemented as part of these six changes but are **SuperAdmin-only**
and are **not** part of the organization Flutter app's contract. See
`trumarkz_changes.md` for full details:
- `POST /verification/batches/{batch_id}/send-rejected-list` (SuperAdmin-only,
  `require_super_admin`) — emails a rejected-user Excel to the organization; there
  is no organization-side trigger or view for this action.
- Any internal database structures (`manual_verification_request_users`,
  `manual_verification_request_files`) — these are backend implementation detail
  with no direct API shape of their own; their *effect* (more precise
  `report_url`/status scoping) is what reaches the app through the endpoints
  above.

---

## Verification checklist for this document

- Every endpoint listed above was confirmed to exist in `api/routers/verification.py`
  at its stated path, method, and auth dependency.
- Every field name (`overall_status_label`, `rejection_reason`, `report_url`,
  `custom_fields["warrenty_report"]`, `custom_fields["product_details"]`,
  `custom_fields["third+party+qr1..4"]`) was confirmed against the actual source,
  not assumed from naming convention.
- No new Flutter-side screen, widget, or code change is claimed anywhere in this
  document — everything above is a backend/API contract change only. Whether the
  organization app's UI is updated to consume any of these new fields is a
  separate, not-yet-verified frontend task.
