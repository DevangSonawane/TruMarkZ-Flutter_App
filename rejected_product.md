# TruMarkZ Flutter — Recent Organization Changes

## 1. Scope

This document covers what the **Organization** Flutter app needs to know
about the recent Human + Product manual/third-party verification workflow
changes. It does **not** include SuperAdmin-only actions, the verifier's
own token-based endpoints, database details, or backend implementation
internals — see `trumarkz_changes.md` for those.

**Bottom line up front:** the organization-facing API **contract did not
change** in this most recent phase of work (the Product per-product SDC
fix, and the verifier's new independent-decision endpoints, are both
either purely internal to certificate generation or reachable only via a
verifier's token — not something the Organization app calls). What follows
is the current, verified state of the org-facing endpoints the app already
integrates against.

---

## 2. Human Organization Flow

The organization does not interact with individual verifier
upload/decision steps directly — those happen on the verifier's own
token-linked page (a separate flow, not part of this app). What the
organization app does is **read the results** of that process:
- Poll/refresh `GET /verification/batches/{batch_id}` to see each Human's
  current `verification_type_status` (status, rejection reason, report
  link) and `overall_status_label`.
- Optionally use `GET /verification/batches/{batch_id}/submitted-reports`
  to see which reports have been uploaded and, now, which exact user each
  one belongs to (`assigned_users` — see §4).

## 3. Product Organization Flow

Identical shape to Human — the same two endpoints, the same response
fields. The only difference is *what* appears in `custom_fields` (Product
has `sku_no`, `model_no`, `brand`, etc. instead of Human's DOB/address
fields) — the verification-related fields (`verification_type_status`,
`overall_status_label`) are the same shape for both.

---

## 4. APIs Organization Must Call

| Method | Path | Purpose | Request | Key response fields | Auth |
|---|---|---|---|---|---|
| GET | `/verification/batches/{batch_id}` | Full batch detail — the primary screen | none | `users[]`, each with `verification_type_status` (per type: `status`, `reason`, `detail`, `rejection_reason`, `report_url`) and `overall_status_label` | Bearer (organization; own batch only) |
| GET | `/verification/all` | List/filter verifications across batches | query filters | `users[]` as `BatchUserDetail`, each with `overall_status_label` | Bearer |
| GET | `/verification/user/{user_id}` | Single user/product detail | none | `BatchUserDetail` with `overall_status_label` | Bearer |
| GET | `/verification/batches/{batch_id}/submitted-reports` | Review uploaded reports per request | optional `submitted_only` query flag | `reports[]`, each with `assigned_users[]` (per-user report attribution — see §4a) | Bearer (organization; own batch only) |
| GET | `/verification/manual/reports/{request_id}/view/{file_index}` | Open a manual/third-party report inline | none | the file itself | **None — intentionally public** (unguessable UUID; same design Dhiway/certificate viewers rely on) |
| GET | `/verification/manual/reports/{request_id}/download/{file_index}` | Download a manual/third-party report file | none | the file itself | Bearer (organization; own batch only) |

None of these paths, methods, or auth requirements changed in this phase
— all were already in place; what's new is only the **data now flowing
through them** (§5).

### 4a. New field on `submitted-reports`: `assigned_users`
Each entry in `reports[]` now additionally includes:
```json
"assigned_users": [
  {
    "batch_user_id": "...",
    "full_name": "Rahul",
    "status": "approved",
    "reason": null,
    "rejection_reason": null,
    "report_url": "https://.../verification/manual/reports/<request_id>/view/1",
    "file_index": 1
  }
]
```
Use this to show **which exact user/product** an uploaded file belongs to,
instead of an undifferentiated file list.

---

## 5. Response Fields

Per verification type, inside `verification_type_status`:
```json
{
  "status": "approved | rejected | pending",
  "label": "manual | automatic",
  "reason": "...",           // manual path only, when set
  "detail": "...",           // automatic path only, when set
  "rejection_reason": "...", // present only when status == "rejected" and text exists
  "report_url": "..."        // present once a report exists for this type
}
```
Overall, on each user/product entry: `overall_status_label`
(`verified`/`partially_verified`/`rejected`/`pending`) alongside the
existing `verification_status` (`approved`/`rejected`/`pending` — still
present, unchanged, still what any existing logic in the app should keep
using if it already reads it).

---

## 6. Status Display

**Use `overall_status_label` for the new user-facing overall status
display.** It is computed and provided by the backend — do not
recalculate it client-side:
- `"verified"` — every verification type approved.
- `"partially_verified"` — at least one approved, but not all (whether the
  rest are pending or rejected).
- `"rejected"` — nothing approved, at least one rejected.
- `"pending"` — nothing approved and nothing rejected yet.

The older `verification_status` field (`approved`/`rejected`/`pending`) is
still present and unchanged — keep using it anywhere existing app logic
already depends on it; it was not replaced or renamed.

---

## 7. Rejection Reason Display

Read `verification_type_status[type].rejection_reason` — this is the
canonical field for "why was this rejected," populated consistently
whether the rejection came from a verifier's manual decision or an
automatic check. The legacy `reason` (manual) and `detail` (automatic)
fields are still present too, for any code that already reads them, but
`rejection_reason` is the single field to use for new display work since
it doesn't require branching on `label` to know which legacy field to
read.

---

## 8. Report URL Handling

Two shapes exist — check which one you have before opening it:

- **Manual/third-party report** — `PUBLIC_API_BASE/verification/manual/reports/{request_id}/view/{index}`.
  A ready-to-use public HTTPS link. Safe to open directly (webview or
  external browser), no auth token needed.
- **Automatic verification report** — still a raw `gs://...` path (this
  did not change). **Flutter must NOT attempt to open this directly** — it
  is not a fetchable web URL. Verified: the codebase has a proxy pattern
  for stored documents (`GET /verification/documents/{document_id}/view`,
  same unguessable-id-based public design as the manual report viewer),
  but there is currently no field that hands the app the underlying
  document id for an automatic report directly from `verification_type_status`
  — so an automatic report is not yet safely linkable from this API alone.
  No new proxy endpoint should be invented to work around this; flag it if
  the app needs automatic-report links.

**Product reports:** delivered through the exact same
`verification_type_status[type].report_url` field as Human — same shape,
same handling. (Separately, Product's Dhiway certificate QR fields are
populated server-side from this same per-user data at certificate
generation time — nothing the app needs to do differently for that.)

**Human reports:** same field, same handling — no difference from Product
at the API level.

---

## 9. Human vs Product Differences

At the API level the organization app consumes, **there is no
Human/Product branching** — the same fields (`verification_type_status`,
`overall_status_label`, `report_url`, `assigned_users`) appear in the same
shape for both. The only practical difference is which `custom_fields`
keys are populated (Product: `sku_no`/`model_no`/`brand`/etc.; Human:
address/DOB/etc.) — unrelated to verification status/report display.

---

## 10. Flutter UI Changes Required

**Backend contract verified; Flutter UI implementation could not be
verified because the Flutter source was not available** — this repository
contains backend code only. Based on the verified backend contract above,
the following are the changes the app would need if it does not already
implement them (not confirmed present or absent in the app itself):
- Display `overall_status_label` as the primary status indicator (§6).
- Display `rejection_reason` wherever a rejected verification type is
  shown (§7).
- Show/open `report_url` per verification type, respecting the
  manual-vs-automatic distinction in §8.
- If displaying `submitted-reports`, attribute each report using the new
  `assigned_users` field instead of a flat file list (§4a).
- Refresh batch details after a verifier completes their review, to pick
  up updated `verification_type_status`/`overall_status_label` — no new
  endpoint is needed for this, re-calling `GET /verification/batches/{batch_id}`
  is sufficient.

---

## 11. What Does NOT Change

- No existing field was removed or renamed.
- No new authentication requirement was added to any endpoint the
  organization app calls.
- `verification_status` keeps its exact existing meaning and values.
- The verifier's own upload/decision flow is a separate, token-authenticated
  process the organization app does not participate in or call.
- SuperAdmin-only actions (e.g. sending the rejected-users Excel) are not
  part of this app's contract at all — see `trumarkz_changes.md` if that
  context is ever needed.
