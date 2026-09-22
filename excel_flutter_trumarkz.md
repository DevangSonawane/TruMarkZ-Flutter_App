# TruMarkZ Flutter — Rejected List Excel Integration

This document covers **only** the organization-side (Flutter app) changes
for the rejected-list Excel feature. SuperAdmin-side implementation is
mentioned only where needed to explain why these organization APIs become
available — see `trumarkzmd.md` for the full picture, including the
SuperAdmin action.

## 1. Organization Flow

```
Organization opens a batch
  → GET /verification/batches/{batch_id}
  → check rejected_list in the response
  → if rejected_list != null and rejected_list.available:
        show View / Download
  → tapping View or Download calls the corresponding
    authenticated endpoint below
```

## 2. Batch API

### `GET /verification/batches/{batch_id}`

Existing endpoint — the response now additionally includes a
`rejected_list` field. Read from `api/schemas/verification.py`
(`BatchDetailResponse.rejected_list`, type `RejectedListInfo | null`):

```json
{
  "...": "...",
  "rejected_list": {
    "available": true,
    "filename": "rejected_users_Batch_Name.xlsx",
    "generated_at": "2026-01-01T12:00:00+00:00",
    "total_rejected_users": 3,
    "rejected_by_type": [
      {"verification_type_name": "Police Verification", "rejected_count": 2}
    ],
    "view_url": "https://.../verification/batches/{batch_id}/rejected-list/view",
    "download_url": "https://.../verification/batches/{batch_id}/rejected-list/download"
  }
}
```

- **Detecting availability:** `rejected_list != null` (it is `null`, not
  an object with `available: false`, when no list has ever been
  generated). When present, `available` is always `true`.
- **Safe fields only:** `available`, `filename`, `generated_at`,
  `total_rejected_users`, `rejected_by_type`, `view_url`, `download_url`.
  There is **no** raw storage path/URL anywhere in this object — do not
  look for one.
- `view_url`/`download_url` are full, absolute URLs to the two
  authenticated endpoints below — use them as-is (they already include
  the correct batch id), but the call must still carry the app's normal
  authenticated-request headers (see §6).

## 3. View API

### `GET /verification/batches/{batch_id}/rejected-list/view`

- Streams the Excel file with `Content-Disposition: inline`.
- Requires the organization's normal authenticated request (same
  mechanism as every other `GET /verification/batches/...` call already
  in the app).
- Flutter should fetch this through its existing authenticated HTTP
  client, then either open the returned bytes with a spreadsheet
  viewer/share sheet, or use it however the app already handles other
  in-app document previews — there is no special-case handling needed
  beyond making an authenticated GET request and using the response body.

## 4. Download API

### `GET /verification/batches/{batch_id}/rejected-list/download`

- Identical to the view endpoint except the response header is
  `Content-Disposition: attachment; filename="<name>.xlsx"` — use this
  filename when saving.
- Content-Type is
  `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`.
- Flutter should fetch this through its existing authenticated HTTP
  client and save the response bytes to a file using the app's normal
  save/download mechanism.

## 5. UI Behavior

- If `rejected_list` is `null` → do not show a View/Download action for
  this batch at all.
- If `rejected_list` exists (`available: true`) → show View and/or
  Download.
- **View** should open the Excel using the app's authenticated request
  mechanism against `rejected_list.view_url` (or the equivalent
  `/rejected-list/view` route) — not a plain unauthenticated link.
- **Download** should save the file using the app's authenticated request
  mechanism against `rejected_list.download_url` — not a plain
  unauthenticated link.
- **Do not** expose or display the raw GCS URL anywhere — it is never sent
  to the app in the first place.
- **Do not** construct a GCS URL manually from any field on this response.
- **Do not** call the generic `GET /verification/documents/{document_id}/view`
  endpoint for this Excel — the rejected list has its own dedicated
  endpoints and no `document_id` is ever provided for it.

## 6. Authentication

Use the exact same authentication convention the app already uses for
every other `/verification/...` organization-facing call in this backend
(the standard bearer-token/session mechanism already wired up for
`GET /verification/batches/{batch_id}` and similar endpoints) — nothing
new or different is required for the two rejected-list endpoints. Both
are gated by the backend's existing organization-ownership check: the app
will only ever see its own organization's batches succeed.

## 7. Error States

| Status | When |
|---|---|
| 404 | No rejected list has been generated for this batch yet (`rejected_list` was already `null` on the batch response, so the app should not have shown a View/Download action in the first place — but handle it defensively if called anyway) |
| 404 | The batch does not belong to the calling organization (the backend never distinguishes "not found" from "not yours" — treat both the same in the UI) |
| 502 | The stored file could not be retrieved from storage on the backend's side — a genuine backend/storage error, not an authorization issue |

Do not treat any other status code as a documented behavior of this
feature.

## 8. API Quick Reference

| API | Method | Purpose |
|---|---|---|
| `/verification/batches/{batch_id}` | GET | Read `rejected_list` to know whether a list is available |
| `/verification/batches/{batch_id}/rejected-list/view` | GET | Open/view the Excel |
| `/verification/batches/{batch_id}/rejected-list/download` | GET | Download the Excel |

## 9. What Flutter Does NOT Need To Implement

- No email handling — this feature has no email component at all.
- No GCS access — the app never talks to storage directly.
- No rejected-Excel generation — the backend builds the file.
- No rejection filtering/business logic — the backend decides who
  qualifies as "rejected."
- No SuperAdmin API call — `send-rejected-list` is a SuperAdmin-only
  action, never called from this app.
- No raw bucket/GCS URL handling of any kind — the app only ever sees
  `view_url`/`download_url`, both pointing at this backend's own
  authenticated endpoints.
