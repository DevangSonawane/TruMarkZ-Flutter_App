# Bulk Gender / Nationality override — Web & Flutter API contract

One backend contract, used identically by Web and Flutter — same
endpoint, same field names, same semantics. This describes the backend
as implemented, verified against source; it is not a UI spec.

**Neither Gender nor Nationality has an `All` option or keyword.**
Selecting every individual value by hand is never treated as a special
`All` operation (see §6).

## 1. Endpoint & auth

```
POST /verification/bulk-upload
Content-Type: multipart/form-data
```
Existing Human Excel/CSV bulk-upload endpoint — `bulk_gender` /
`bulk_nationality` are two optional fields on it, not a new endpoint.
Auth: bearer token, organization account (`Depends(require_org)`), same
as every other field here.

## 2. Request fields

| Field | Required | Notes |
|---|---|---|
| `file` | Yes | `.xlsx` or `.csv` |
| `batch_name` | Yes | |
| `description`, `industry_type`, `verification_types`, `credential_visibility`, `template_id`, `batch_type` | No | Existing, unrelated to this feature |
| **`bulk_gender`** | No | comma-separated, see §3 |
| **`bulk_nationality`** | No | comma-separated, see §3 |

Plain multipart text fields (`Form(None)`), not JSON/array. Multiple
values = one comma-separated string, e.g. `bulk_gender=Male,Other`.
Omit the field entirely (not an empty string) for "nothing selected."

## 3. Supported values — no `All` for either field

- **Gender** (`api/constants.py`'s `GENDER_OPTIONS`): `Male`, `Female`,
  `Other`.
- **Nationality** (`NATIONALITY_OPTIONS`, same file): 195 demonyms, not
  country names (`Indian`, not `India`) — covers every UN member state
  plus Taiwan/Palestine. Not reproduced here (must stay byte-for-byte in
  sync with that file); both clients maintain their own hand-copy, no
  runtime endpoint to fetch it.
- Matching is case-insensitive, normalized to the casing above.
- `bulk_gender=All` / `bulk_nationality=All` are both **rejected** as
  unsupported values (§5) — `All` was removed from Nationality in a
  later product correction; any earlier assumption that it still expands
  there is stale.

## 4. Request examples

**Web:**
```js
const formData = new FormData();
formData.append('file', file);
formData.append('batch_name', 'Driver Verification - May 2026');
formData.append('bulk_gender', 'Male');                  // single → override
formData.append('bulk_nationality', 'Indian,American');  // 2+ → Excel preserved
await fetch('/verification/bulk-upload', {
  method: 'POST',
  headers: { Authorization: `Bearer ${token}` },
  body: formData,
});
```

**Flutter:**
```dart
final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/verification/bulk-upload'))
  ..headers['Authorization'] = 'Bearer $token'
  ..fields['batch_name'] = 'Driver Verification - May 2026'
  ..fields['bulk_gender'] = 'Male'
  ..fields['bulk_nationality'] = 'Indian,American'
  ..files.add(await http.MultipartFile.fromPath('file', excelFilePath));
final response = await request.send();
```

## 5. Selection behavior & errors

| Resolved values | Effect |
|---|---|
| 0 (field omitted/blank) | Every row keeps its Excel value. Column stays required unless a single-value override (next row) makes it optional. |
| Exactly 1 | **Hard override** — forced onto every row, replacing/filling the Excel cell. Gender and Nationality override independently. |
| 2+ (incl. selecting every option by hand) | **No override** — identical to 0. No arbitrary per-person assignment, never excludes anyone. |

Errors (verified against the actual `HTTPException` calls):
```json
400 {"detail": "Unsupported bulk gender value: '<value>'. Supported values: Male, Female, Other."}
400 {"detail": "Unsupported bulk nationality value: '<value>'. Supported values: Afghan, ... Zimbabwean."}
400 {"detail": "Missing required columns: gender, nationality"}
```
`All` produces the first/second error like any other unsupported value —
never listed as a supported option. These are the only two errors
specific to this feature; other errors on this endpoint are pre-existing.

## 6. Response

`BulkUploadResponse` — `successful_users[i]` already carries the
**final, resolved** `gender`/`nationality` (override or Excel), so no
follow-up call is needed to confirm what was saved:
```json
{
  "message": "string", "batch_id": "uuid", "entity_type": "human",
  "total_uploaded": 0, "total_skipped": 0,
  "successful_users": [
    {"id": "uuid", "full_name": "string", "email": "string", "phone_number": "string",
     "dob": "string", "gender": "Male", "nationality": "Indian",
     "photo_url": "string|null", "invite_token": "string", "invite_link": "string"}
  ],
  "skipped_users": [ {"row": 0, "reason": "string", "data": {}} ],
  "errors": [ {"row": 0, "error": "string", "data": {}} ]
}
```

Later lookups: `GET /verification/user/{user_id}` and
`GET /verification/all` return `custom_fields` on `BatchUserDetail`, so
`custom_fields.gender`/`.nationality` are readable the same way as any
other custom field (e.g. `license_number`). `GET /verification/batches/{batch_id}`
was not checked for this — verify separately if needed.

## 7. Persistence & scope

No new column, no migration — both fields live in the existing
`BatchUser.custom_fields` JSONB, same place every downstream consumer
(SDC/report generation) already reads.

Feature exists **only** on `POST /verification/bulk-upload` for **Human**
batches. Not on single-upload, the OCR bulk-upload endpoint, or any
Product/Warranty endpoint — sending these fields there has no effect.

## 8. Integration checklist

- [ ] No `All` option rendered for Gender or Nationality, anywhere.
- [ ] Multi-select otherwise fully supported — only the `All`
      keyword/shortcut is prohibited.
- [ ] Field omitted (not empty string) when nothing selected.
- [ ] Comma-join selected values, no stray commas.
- [ ] "More than one selected" is never treated as an error in the UI.
- [ ] Post-upload UI reads `successful_users[i].gender`/`.nationality`
      directly, never recomputed client-side.

## 9. Known limitations

- Excel-sourced (non-overridden) values aren't validated server-side —
  deliberate, to preserve existing free-text organizational data.
- `GET /verification/batches/{batch_id}` not checked for `custom_fields`.
- No runtime endpoint for the nationality list — both clients keep a
  hand-synced copy.
