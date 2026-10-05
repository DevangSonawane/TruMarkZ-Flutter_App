# TruMarkZ OCR Human Workflow

## 1. Overview

The OCR Human workflow is a **two-stage upload flow**:

1. **Documents** — one or more Human document images are uploaded and
   OCR'd; a `BatchUser` is created per successful document.
2. **Photos** — each person's photo is uploaded **separately**, in a
   different request, and attached to the `BatchUser` created in stage 1.

The stages are intentionally independent requests:
- a successful document upload is never rolled back by a later photo
  failure;
- single and bulk photo uploads share **one** internal storage helper
  (`_store_human_photo`) — not two implementations.

Not covered here: the Excel Human bulk upload (`POST /verification/bulk-upload`,
which shares the same photo pipeline — see §4), the standalone `/ocr`
utility router (`GET /ocr/field-suggestions`, `POST /ocr/extract` — a
distinct, unrelated utility), and DL/CrimeScan/manual verification
internals beyond how they relate to the photo (§7).

---

## 2. Complete Flow

```
Documents
    ↓
POST /verification/bulk-upload/documents   (files[])
    ↓
OCR each document → BatchUser per success
    ↓
successful_users[].id   (batch_user_id, in upload order)
    ↓
Photos  —  single or bulk
    ↓
POST /verification/upload/ocr-photo          (one)
POST /verification/bulk-upload/ocr-photos    (many, paired by index)
    ↓
_normalize_excel_image → 350×350 PNG
    ↓
GCS upload  +  BatchUser.photo_url  +  UserDocument("photo")
    ↓
Existing Dhiway photo resolver → Human SDC
```

---

## 3. API Endpoints

### 3.1 Existing OCR Document Upload — `POST /verification/bulk-upload/documents`

Unchanged by the photo-upload feature described in this document.

**Auth:** organization (`require_org`).

**Request** (`multipart/form-data`):

| Field | Type | Notes |
|---|---|---|
| `batch_name` | string (Form) | required |
| `description`, `industry_type`, `verification_types`, `credential_visibility`, `doc_type`, `fields` | string (Form) | optional |
| `batch_type` | string (Form) | `human` (default) / `product` / `warranty` |
| `files` | **list[UploadFile]** (File) | **multiple files under the same field name** |

**Behavior:**
- Each document is OCR'd (Gemini) and processed **independently, in
  upload order**; a document with no extractable name is **skipped**,
  not failed.
- Extracted Human fields (`full_name`, `email`, `phone_number`, `dob`,
  `aadhar_number`, `pan_number`, address) create one `BatchUser` per
  success.
- The original document image is stored as a `UserDocument` labeled by
  document type (`driving_license` / `aadhaar` / `pan` / `document`) —
  **never** `"photo"`; the person's photo is a separate, later upload.

**Response** (`BulkUploadResponse`): `message`, `batch_id`, `entity_type`,
`total_uploaded`, `total_skipped`, `successful_users[]`, `skipped_users[]`,
`errors[]`.

Each `successful_users[]` entry includes `id`, `full_name`, `email`,
`phone_number`, `document_type`, `extracted`, `ocr_review_status`,
`document_url`, `invite_token`, `invite_link`.

> **`successful_users[].id` is the `batch_user_id`** needed for the photo
> stage — preserve it in the order returned. A skipped/failed document
> has no entry here and no `batch_user_id` — exclude it from photo
> pairing (§5).

### Multiple-document support — backend status

**The backend already supports multiple documents in one request.**
`files` is a real `list[UploadFile]` — confirmed via the generated
OpenAPI schema (`files`: array of `format: binary`) and by sending real
requests with **2, 3, and 5 files** directly to the endpoint: all files
were received and processed, **in upload order**, in a single request.
**No backend change is required for multi-document upload.**

If an application currently only allows selecting one document at a
time, that is a **frontend file-selection/upload limitation**, not a
backend API limitation — the frontend developer needs to update the
file-selection/upload UI to submit multiple files under the same
`files` field in one request (see §8).

---

### 3.2 New — Single OCR Photo Upload — `POST /verification/upload/ocr-photo`

Uploads the photo for one `BatchUser` created in §3.1.

**Auth:** organization (`require_org`) + ownership (§6).

**Request** (`multipart/form-data`): `batch_user_id` (string, Form),
`photo` (file, File).

**Response** (`PhotoUploadResponse`):
```json
{
  "message": "Photo uploaded successfully",
  "photo_url": "...",
  "batch_user_id": "...",
  "document_id": "...",
  "version": 1
}
```
(`batch_user_id`/`document_id`/`version` are populated by this endpoint
and the bulk one; the existing self-service `/upload/photo`, §3.4, never
sets them.)

A non-image `photo` (content-type not `image/*`) → `400`, before any
storage call. Processing/storage: see §4. Re-upload/versioning: see §4.

---

### 3.3 New — Bulk OCR Photo Upload — `POST /verification/bulk-upload/ocr-photos`

Uploads photos for multiple `BatchUser`s created in §3.1, in one request.

**Auth:** organization (`require_org`) + per-item ownership (§6).

**Request** (`multipart/form-data`): `batch_user_ids` (**list[string]**,
Form, repeated field), `photos` (**list[UploadFile]**, File, repeated
field). **Both lists must be the same length.**

**Positional mapping (the contract):** `batch_user_ids[i] ↔ photos[i]`.
Never by filename, name, email, document type, OCR data, or database
order — see §5.

**Validation:** `len(batch_user_ids) != len(photos)` → **HTTP 400**
(`"batch_user_ids and photos must contain the same number of items"`)
before anything is processed.

**Per-item processing:** each pair is resolved and stored
**independently** — one invalid photo or wrong-org id never blocks the
others (§5).

**Response** (`BulkOcrPhotoUploadResponse`):
```json
{
  "message": "2 photo(s) uploaded, 1 failed.",
  "total_requested": 3,
  "total_succeeded": 2,
  "total_failed": 1,
  "successful_users": [
    {"batch_user_id": "...", "photo_url": "...", "document_id": "...", "version": 1}
  ],
  "failed_users": [
    {"batch_user_id": "...", "error": "..."}
  ]
}
```
`successful_users[]` = `OcrPhotoUploadResult`; `failed_users[]` =
`OcrPhotoUploadError` (`batch_user_id`, `error`).

---

### 3.4 Existing — Self-Service Photo Upload — `POST /verification/upload/photo`

Invite-token based (no org auth) — the person being verified uploads
their own photo via a link. **Unchanged** by this feature: it does not
call `_normalize_excel_image` (stores whatever the uploader sent,
unmodified) and is entirely separate from the organization-authenticated
OCR photo APIs above. Do not mix the two flows.

---

## 4. Photo Processing & Storage

Both §3.2 and §3.3 call one shared helper (`_store_human_photo`) for the
full sequence:

```
photo bytes
    ↓
_normalize_excel_image(raw_bytes, *HUMAN_PHOTO_NORMALIZED_DIMENSIONS_PX)
    ↓
350 × 350 PNG   (image/png)
    ↓
upload_file_to_gcs(...)
    ↓
update_batch_user_photo(...)   →  BatchUser.photo_url
    ↓
create_document(document_label="photo", ...)   →  UserDocument
```

- **Same normalization as the Excel Human photo flow** — no
  OCR-specific resize implementation. Dimensions come from the
  `HUMAN_PHOTO_NORMALIZED_DIMENSIONS_PX` constant (currently `(350, 350)`),
  not a hardcoded literal — if that constant changes, both flows change
  together.
- **Stretches** to the exact square (no crop/letterbox) — a non-square
  source will be visibly distorted. Output is always re-encoded PNG
  regardless of source format.
- This normalization helper is marked in the codebase as a **temporary
  demo workaround**; the OCR flow intentionally reuses it as-is.
- **`UserDocument.document_label` is always exactly `"photo"`** — never
  `human_photo`/`profile_photo`/`ocr_photo`. The Dhiway resolver (§7)
  depends on this exact label.
- **Versioning:** `get_document_version` determines the next version
  before each upload; re-uploading **adds a new version** (prior
  versions are kept, never deleted) and updates `BatchUser.photo_url` to
  the latest. Same behavior as every other versioned document type in
  this codebase (Warranty Report, Product Details, etc.).

---

## 5. Mapping & Error Handling

| Rule | Behavior |
|---|---|
| Document → user | `successful_users[].id` (§3.1) is the `batch_user_id`; preserve order |
| Skipped/failed document | no `batch_user_id` exists — exclude from photo pairing |
| Photo → user (bulk) | `batch_user_ids[i] ↔ photos[i]`, strict positional index — never filename/name/email/order heuristics |
| `len(batch_user_ids) != len(photos)` | `400`, entire request rejected, nothing processed |
| One bad pair among valid ones (bad photo, wrong-org id, empty upload) | that pair → `failed_users[]`; all other pairs still succeed |
| Photo upload fails after documents succeeded | documents/`BatchUser`s remain untouched — stages are independent requests |

---

## 6. Security

Every request to §3.2/§3.3:
1. authenticates the organization (`require_org`);
2. resolves `batch_user_id` → `BatchUser` (`get_batch_user_by_id`);
3. checks `batch_user.org_id == org.id`.

- Not a valid id / doesn't exist → **404**.
- Exists but belongs to another organization → **403** (same
  404-then-403 pattern already used elsewhere in this router, e.g.
  `upload_warranty_document`).
- **No storage happens before ownership passes** — single endpoint
  returns the error immediately; bulk endpoint records that one item in
  `failed_users[]` and continues with the rest.

---

## 7. Dhiway / SDC Integration

**No Dhiway code was changed.** The existing resolver already finds any
photo regardless of which endpoint created it:

```
UserDocument("photo")  +  BatchUser.photo_url
        ↓
_resolve_human_photo_part   (api/routers/sdc.py)
        ↓
create_human_5qr_record → Human SDC   (map_human_5qr_user_to_record)
```

`_resolve_human_photo_part` looks up the latest `UserDocument` with
`document_label == "photo"` (falling back to `BatchUser.photo_url`) —
exactly what §4 produces. No new Dhiway API or schema change was
required for OCR-sourced photos.

**Database:** no migration required — `BatchUser.photo_url` and
`UserDocument` already covered everything needed; no `db/queries.py`
changes were necessary.

---

## 8. Frontend Integration

### Multi-document selection

The frontend must allow users to select **multiple** documents using a
multiple-file input:
```html
<input type="file" multiple>
```
All selected files must be submitted **together**, under the same
`files` field, in **one** multipart request to
`POST /verification/bulk-upload/documents`. Do not upload each document
individually when using bulk mode — the backend already supports
multiple files in one request (§3.1); only the frontend's
file-selection/upload UI needs to allow and submit a multi-file
selection.

Read `successful_users[]`; retain each `id` (= `batch_user_id`) **in the
returned order**. Exclude anything in `skipped_users[]` — it has no id.
This order must be preserved, because the returned `id` values are
subsequently used for photo pairing (§5, "Photos — bulk" below).

### Photos — bulk
```
batch_user_ids[] = [id1, id2, id3]
photos[]         = [photo1, photo2, photo3]
```
Pair **strictly by index** — never by filename/name/email/order.

### Photos — single
```
POST /verification/upload/ocr-photo
  batch_user_id
  photo
```

---

## 9. API Summary

| Endpoint | Purpose | Auth | Input | Status |
|---|---|---|---|---|
| `POST /verification/bulk-upload/documents` | OCR document upload (single or bulk) | Org | `files[]` + metadata | Existing — unchanged |
| `POST /verification/upload/ocr-photo` | Single OCR photo | Org | `batch_user_id`, `photo` | **NEW** |
| `POST /verification/bulk-upload/ocr-photos` | Bulk OCR photos | Org | `batch_user_ids[]`, `photos[]` | **NEW** |
| `POST /verification/upload/photo` | Self-service photo (invite link) | Invite token | `token`, `file` | Unchanged |

---

## 10. Status & Tests

| Item | Status |
|---|---|
| OCR document upload (single & bulk) | ✅ Existing, works as-is |
| Multiple documents in one request | ✅ Verified with 2/3/5 files |
| Single / bulk OCR photo upload | ✅ New APIs added |
| Document → user / photo → user mapping | ✅ Positional, index-based |
| 350×350 PNG normalization | ✅ Same helper as Excel flow |
| GCS storage, `BatchUser.photo_url`, `UserDocument("photo")` | ✅ |
| Versioning / re-upload | ✅ |
| Organization ownership/security | ✅ |
| Bulk length validation + partial-failure handling | ✅ |
| Existing `/upload/photo` | ✅ Unchanged |
| Dhiway/SDC compatibility | ✅ No Dhiway changes required |
| Database migration | ❌ Not required |

New OCR photo endpoint tests and the `/upload/photo` regression test all
pass, alongside the full pre-existing OCR/Human/Dhiway suites.

**Full backend suite: 880 passed, 0 failed.**
