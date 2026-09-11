# TruMarkZ Flutter — Organization Workflow (Product)

This document covers **organization-side** Flutter integration only. **There
is no Super Admin role in the Flutter application** — nothing here describes
a super-admin screen, permission, or workflow.

Every endpoint below is verified directly against the current backend
source. Where the backend's own route documentation/naming disagrees with
what the code actually enforces, this document follows the code, and the
discrepancy is called out explicitly.

---

## 1. Organization Authentication

- Login: `POST /auth/login` (see `api/routers/auth.py`).
- Every authenticated endpoint below expects a Bearer token: `Authorization: Bearer <token>`.
- The account must have `email_verified = true`, and the token's user must have `user_type = "organization"` (a `super_admin` token also passes the same check, but the Flutter app only ever authenticates as an organization).
- ⚠️ **Verified exception:** `POST /verification/manual/send-bulk` and `POST /verification/manual/smart-send` currently have **no authentication dependency at all** in the backend route — they do not require a Bearer token or any user check. Every other endpoint in this document does require the standard organization Bearer token. This is stated as the actual current behavior, not a recommendation to rely on it.

---

## 2. Organization Product Workflow (overview)

```
Download Product Excel template
        ↓
Fill in product_name / sku_no / model_no / brand
(optionally embed product_image / blow_up_image images)
        ↓
Upload the Excel/CSV
        ↓
(optional) Send verification requests to third-party verifiers
        ↓
Poll batch detail for verification status
        ↓
Generate SDC once at least one product is approved
        ↓
Poll SDC status until certificates are ready
```

---

## 3. Product Template Download

`GET /verification/products/template`
- Auth: Bearer token (organization).
- No parameters.
- Returns an `.xlsx` file.
- **Current header columns, in order:**
  ```
  product_name, sku_no, model_no, brand, product_image, blow_up_image
  ```
- There is **no** `third+party+qr1/2/3/4` column in this template. These are backend-generated verification outputs — the organization never types or selects them (see Section 5 below and `trumarkz_changes.md` Section F).

`POST /verification/products/template` (Form field `headers`, optional) generates the same canonical template when no custom headers are given.

---

## 4. Product Excel Upload

`POST /verification/bulk-upload/products`
- Auth: Bearer token (organization).
- `multipart/form-data`.

| Field | Required |
|---|---|
| `batch_name` | Yes |
| `file` | Yes (`.xlsx`, `.xls`, or `.csv`) |
| `description` | No |
| `industry_type` | No |
| `verification_types` | No |
| `batch_type` | No — defaults to `"product"` |

- Excel must have `product_name`; `sku_no` is also required when `batch_type` is `"product"`.
- Response includes `batch_id`, and `successful_users[]`, each with an `id` — **this `id` is the product's real identity for every later API call** (SDC status, correlation, etc.). Do not use `product_name` or row position for that purpose.
- Row-level problems (missing field, duplicate, image upload failure) appear in `skipped_users`/`errors` without failing the whole upload.

---

## 5. Product Image Fields (`product_image`, `blow_up_image`)

- These are **embedded Excel images**, placed via Excel's *Insert → Image → Place in Cell* under the `product_image` / `blow_up_image` header columns — **not** a text value, filename, or URL typed into the cell.
- Each image is associated with its own row **and** its own column — a row's `product_image` and `blow_up_image` are independent and never overwrite each other; different rows' images never cross-associate.
- **Both are fully optional, independently:** a product can have both, either one, or neither — an upload with no images for a row still succeeds.
- There is currently **no separate API for uploading a Product image outside of the Excel embedded-image flow** — this is the only verified path. If a UI needs a standalone image-attach control, that backend endpoint does not exist yet.
- On success, the uploaded product's `custom_fields` will contain `product_image_url` and/or `blow_up_image_url` (present only for whichever image was actually provided) — these are proxy URLs suitable for displaying the image in the app, not raw internal storage paths.

---

## 6. Product Batch Listing / Detail

`GET /verification/batches/{batch_id}` — Auth: Bearer token (organization).

Relevant response fields for Product (this same endpoint is shared with Human/Warranty; several fields in the response, like `dob` or `license_number` inside `users[]`, are Human-specific and irrelevant for Product):

```json
{
  "batch_id": "…",
  "batch_type": "product",
  "status": "processing",
  "total_users": 3,
  "verification_types": [ { "id": "…", "name": "…", "label": "manual" } ],
  "verification_checks": [ { "name": "…", "label": "manual", "status": "pending", "total_users": 3, "approved_users": 1, "is_complete": false } ],
  "can_generate_sdc": true,
  "users": [ { "user_id": "…", "full_name": "…", "custom_fields": { "sku_no": "…" }, "verification_status": "approved" } ]
}
```

**`can_generate_sdc` for a Product batch is `true` as soon as at least one product is approved** — it does not require every product in the batch to be approved first. (This is a different, less strict rule than Human batches use — do not assume the two behave the same way.)

Batch-level `status` values (derived, never invented by the client): `pending`, `processing`, `verification_in_progress`, `verification_completed`, `sdc_generated`.

---

## 7. Product Verification Status

Per-product `verification_status`: `pending` / `approved` / `rejected`, found in `users[].verification_status` in the batch-detail response above. Per-verification-type detail is in `users[].verification_type_status`, e.g.:
```json
"verification_type_status": {
  "Quality Check": { "status": "approved", "label": "manual", "report_url": "…" }
}
```

---

## 8. Manual Verifier / Email Workflow (organization side)

The organization sends verification requests to third-party verifiers — the verifier's own upload link (`/manual/upload/{token}`) is used by the verifier, not the organization app.

- `POST /verification/manual/send-bulk` — one verifier per verification type. Body: `{"batch_id": "…", "verifiers": [{"verification_type_name": "…", "verifier_email": "…", "email_subject": "…", "email_body": "…"}]}`. **No authentication is enforced on this endpoint** (see Section 1).
- `POST /verification/manual/smart-send` — multiple verifiers per verification type, with an explicit `user_ids` split per verifier. Same auth note applies.
- **Neither request lets the caller choose a QR slot.** The backend assigns `qr1`→`qr2`→`qr3`→`qr4` automatically, in the order requests are created, for Product batches only. This is not configurable from the app.
- `PATCH /verification/manual/requests/{request_id}/status` — sets the final `"approved"`/`"rejected"` outcome after a verifier has submitted a report. **Verified from code:** although this route's own summary text calls it a "Super Admin" action, its actual enforced dependency is the same organization-Bearer-token check (`require_org`) used everywhere else — it is callable by an organization user, not restricted to a separate super-admin role.

On approval, the backend writes the verifier's report URL into the assigned `third+party+qrN` field for the affected product(s) — this happens entirely server-side; there is no separate "set QR value" call.

---

## 9. Product SDC Generation

`POST /sdc/batches/{batch_id}/generate` — Auth: Bearer token (organization).
- Body: `{"publish": false, "active": false}` (both optional/default `false`).
- Only products with `verification_status == "approved"` are included. If none are approved yet, this returns `400`.
- Returns immediately with `sdc_status: "draft_created"` — this call does **not** wait for the certificate to be issued.

---

## 10. Product SDC Status / Reconciliation

`GET /sdc/batches/{batch_id}/status` — Auth: Bearer token (organization).
- Poll this after `/generate`. It automatically checks Dhiway and issues any ready draft into a signed certificate on its own — no separate "issue" call is needed in the normal flow.
- Response: `{"total": 3, "ready": 2, "pending": 1, "done": false, "sdc_status": "draft_created", "certificate_ids": [], "stalled": false, "shared_with_org": false}`.
- `done` becomes `true` once `ready == total`.
- `certificate_ids` only becomes non-empty for an organization caller **after** the batch has been explicitly shared (`shared_with_org: true`) — before that, expect an empty list even if certificates already exist.
- The backend correlates each certificate to a product using the product's `id` from the upload response (`BatchUser.id` / `product_id` on the Dhiway record) — never `product_name`, `sku_no`, or list position.

---

## 11. Error States to Handle

| Situation | What the backend returns |
|---|---|
| Upload with missing `product_name`/`sku_no` on a row | Row appears in `skipped_users`, upload itself still `200` |
| Product image fails to upload to storage | Row appears in `errors` with `"field": "product_image"`/`"blow_up_image"`; product itself still created |
| `/sdc/generate` called with zero approved products | `400` |
| `/sdc/generate` called again on an already-generated batch | Existing drafts are reused (no duplicate Dhiway records) |
| Manual verifier request for a verification type with no matching batch users | That mapping reports `"status": "failed"` in the bulk-send response, others in the same call are unaffected |

---

## 12. Exact Field Names — Quick Reference

Excel input (organization-provided): `product_name`, `sku_no`, `model_no`, `brand`, `product_image`, `blow_up_image`.

Backend/verification output (never organization input): `product_id`, `created_time`, `third+party+qr1`, `third+party+qr2`, `third+party+qr3`, `third+party+qr4`.

**`third+party+qr2` is not in the Excel template, but it is fully present and functioning in the backend Dhiway record — it has not been removed from the verification/Dhiway system, only from the downloadable Excel input template.**

---

## 13. What Changed Recently (Product only)

- New Product Dhiway Space (configuration-only; no app change required).
- Product Dhiway record gained `third+party+qr3`, `third+party+qr4`, `product_image`, `blow_up_image` (additive — existing fields unchanged).
- Product manual-verification QR slot assignment extended from 2 to 4 slots.
- `product_image` / `blow_up_image` Excel embedded-image support added (Section 5).
- `third+party+qr2` removed from the downloadable Excel template only (Section 3/12) — no change to how QR2 is assigned, stored, or sent to Dhiway.

None of the above affects Human or Warranty screens/flows.
