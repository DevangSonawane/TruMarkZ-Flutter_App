# Bulk Gender / Nationality assignment — Web & Flutter API contract

**The previous Excel/CSV bulk override (`bulk_gender`/`bulk_nationality`
on `POST /verification/bulk-upload`) has been removed entirely.** This
feature now exists **only** on the Human OCR document-upload endpoint.
Any earlier documentation, integration code, or assumptions based on the
Excel-based version are stale — see `changes_trumarkz.md` for the
removal history if you need it.

One backend contract, used identically by Web and Flutter — same
endpoint, same field name, same semantics. Described as implemented,
verified against source; not a UI spec.

---

## 🚨 Frontend Migration Required — Web and Flutter

Both clients must:

1. **Remove** the old Gender/Nationality bulk override controls from the
   Excel/CSV upload flow.
2. **Stop sending** `bulk_gender` and `bulk_nationality` to
   `POST /verification/bulk-upload` — the backend now silently ignores
   them (no error, no effect; verified by test).
3. **Integrate** with the new `assignments` field on
   `POST /verification/bulk-upload/documents` (§3–§5 below).
4. Let the user select specific OCR images (by position in the upload
   batch, before any are submitted) and assign Gender and/or Nationality
   to those selections.
5. Support multiple assignment groups to different subsets, submitted
   together in the same upload request (e.g. Users 1–5 → Male, Users
   6–10 → Female, Users 1/3/8 → Indian — all in one call).
6. Submit assignments **in the same request that uploads the images** —
   there is no separate "assign after upload" call; see §4 for why.
7. Use `file_indices` (0-based position in the `files` list for that
   request) as the identifier — **never a display label like "User 1"**.
8. Read saved Gender/Nationality back from
   `successful_users[i].gender`/`.nationality` in the upload response, or
   later via `GET /verification/user/{id}` / `GET /verification/all`
   (§8).
9. Follow the exact request/response contract below.
10. Gender and Nationality remain independently assignable. **Neither has
    an `All` option or keyword** — never send the literal string `All`
    for either field.

---

## 1. Endpoint & auth

```
POST /verification/bulk-upload/documents
Content-Type: multipart/form-data
```
Existing OCR document bulk-upload endpoint (unchanged otherwise) —
`assignments` is one new optional field on it, not a new endpoint. Auth:
bearer token, organization account (`Depends(require_org)`), same as
every other field here. Assignments are only ever written to a
`BatchUser` row owned by the calling org in the batch this same call
creates — there is no mechanism by which a cross-org or cross-batch
target is even expressible, since `file_indices` only ever reference
files within this one request.

## 2. Supported Gender & Nationality values — no `All` for either

- **Gender** (`api/constants.py`'s `GENDER_OPTIONS`): `Male`, `Female`,
  `Other`.
- **Nationality** (`NATIONALITY_OPTIONS`, same file): 195 individual
  demonyms, not country names (`Indian`, not `India`). Not reproduced
  here — must stay byte-for-byte in sync with that file; both clients
  maintain their own hand-copy (no runtime endpoint to fetch it, no
  shared package between repos).
- Matching is case-insensitive, normalized to the casing above.
- **`All` is rejected as an unsupported value for both fields** — it is
  not a recognized keyword anywhere in this feature.

## 3. Why this moved from Excel to OCR, and the timing requirement

Excel rows already carry their own `gender`/`nationality` columns — the
Excel-based version of this feature solved a problem that didn't really
exist there and has been removed. OCR documents are different: **no OCR
extraction this endpoint performs ever maps to "nationality" at all**,
and only some document types (e.g. Aadhaar) occasionally yield "gender."
This feature exists so an organization can supply those values directly
when uploading, instead of relying on unreliable/absent extraction.

**Critical architectural fact, verified directly in the router:** this
endpoint already processes every uploaded file **synchronously, in one
request** — OCR runs immediately for each file in a loop, and the
`BatchUser` is created immediately after. There is no later, separate
"process" step. This means assignments **must** travel in the same
request as the files (§4) — a follow-up "update after upload" call would
by definition run after OCR has already completed for every file, which
does not satisfy "available before extraction." Instead, `assignments`
is parsed and fully validated **before the per-file OCR loop begins**,
and applied to each file's extracted data **immediately before** that
file's `BatchUser` is created — genuinely before extraction's output is
ever persisted, not after.

## 4. Request field: `assignments`

Optional multipart text field, one JSON array:
```json
[
  {"file_indices": [0, 1, 2, 3, 4], "gender": "Male"},
  {"file_indices": [5, 6, 7, 8, 9], "gender": "Female"},
  {"file_indices": [0, 2, 7], "nationality": "Indian"}
]
```
- `file_indices`: required, non-empty array of 0-based integers —
  positions into **this same request's** `files` list, in upload order.
  Not a database ID (none exists yet at upload time), not a display
  label.
- Each entry needs at least one of `gender` / `nationality` (both
  allowed in the same entry).
- A file index may appear in multiple entries — for the **same** field,
  the **last matching entry in array order wins** (simple, fixed,
  documented precedence — not derived from the people themselves).
- Omit `assignments` entirely for the unchanged, pre-feature behavior.

## 5. Request examples

**Web:**
```js
const formData = new FormData();
formData.append('batch_name', 'Driver Verification - May 2026');
files.forEach(f => formData.append('files', f));  // order defines file_indices
formData.append('assignments', JSON.stringify([
  { file_indices: [0, 1, 2, 3, 4], gender: 'Male' },
  { file_indices: [5, 6, 7, 8, 9], gender: 'Female' },
  { file_indices: [0, 2, 7], nationality: 'Indian' },
]));
await fetch('/verification/bulk-upload/documents', {
  method: 'POST',
  headers: { Authorization: `Bearer ${token}` },
  body: formData,
});
```

**Flutter:**
```dart
final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/verification/bulk-upload/documents'))
  ..headers['Authorization'] = 'Bearer $token'
  ..fields['batch_name'] = 'Driver Verification - May 2026'
  ..fields['assignments'] = jsonEncode([
    {'file_indices': [0, 1, 2, 3, 4], 'gender': 'Male'},
    {'file_indices': [5, 6, 7, 8, 9], 'gender': 'Female'},
    {'file_indices': [0, 2, 7], 'nationality': 'Indian'},
  ]);
for (final (i, path) in imagePaths.indexed) {
  request.files.add(await http.MultipartFile.fromPath('files', path)); // order == file_indices
}
final response = await request.send();
```

## 6. Validation errors (verified against the actual `HTTPException` calls)

```json
400 {"detail": "assignments must be a valid JSON array"}
400 {"detail": "assignments must be a JSON array of objects"}
400 {"detail": "Each assignments entry needs a non-empty 'file_indices' array"}
400 {"detail": "Each assignments entry needs at least one of 'gender' or 'nationality'"}
400 {"detail": "Unsupported gender value in assignments: '<value>'. Supported values: Male, Female, Other."}
400 {"detail": "Unsupported nationality value in assignments: '<value>'. Supported values: Afghan, ... Zimbabwean."}
400 {"detail": "assignments file_indices contains an out-of-range index: <n> (this request has <N> file(s), valid indices are 0..<N-1>)"}
```
`All` produces the gender/nationality "unsupported value" error above,
never a special case. An out-of-range or malformed `file_indices` entry
rejects the **entire request** before any file is processed — nothing is
ever silently assigned to the wrong person, and no `BatchUser` is created
at all on this error (verified: validation runs before the OCR loop).

## 7. Response — unchanged shape, values reflect assignments

`BulkUploadResponse`, same shape as before this feature. Each entry in
`successful_users` includes the row's **final, resolved** values:
```json
{
  "id": "uuid", "full_name": "string", "email": "string|null",
  "phone_number": "string|null", "dob": "string|null",
  "gender": "Male", "nationality": "Indian",
  "document_type": "driving_license", "extracted": { "...": "raw OCR output" },
  "ocr_review_status": "pending_review",
  "document_url": "string|null", "invite_token": "string", "invite_link": "string"
}
```
`gender`/`nationality` are `null` when neither OCR nor an assignment
produced one — unchanged from before this feature, still correctable via
the existing `PATCH /verification/batch-users/{user_id}` review flow.

## 8. Persistence & later retrieval

Written into the **existing** `BatchUser.custom_fields` JSONB —
`custom_fields.gender` / `custom_fields.nationality`, no new column, no
migration. The assignment is applied **last**, after everything OCR
itself produced, as part of the single dict passed to `create_batch_user`
— there is no separate write, and no later OCR step in this architecture
that could ever re-overwrite it. Unrelated `custom_fields` keys (e.g.
`dl_number`, `aadhar_number`) are never touched.

Later lookups: `GET /verification/user/{user_id}` and
`GET /verification/all` both return `custom_fields` on each
`BatchUserDetail` (verified in `api/schemas/verification.py`) — same
retrieval path as any other custom field. `GET /verification/batches/{batch_id}`
was not checked for this — verify separately if needed.

Subsequent edits via `PATCH /verification/batch-users/{user_id}` (the
existing review flow) are unrelated and unaffected by this feature —
that endpoint's own existing requirement that Human edits always resend
`gender`/`nationality` is pre-existing, unchanged behavior.

## 9. Scope

Exists **only** on `POST /verification/bulk-upload/documents` for
**Human** batches. Not on `POST /verification/bulk-upload` (Excel/CSV —
removed from there), `POST /verification/single/human`, or any
Product/Warranty endpoint.

## 10. Integration checklist

- [ ] No `All` option rendered for Gender or Nationality, anywhere.
- [ ] Files are ordered deterministically before upload — that order
      defines `file_indices`.
- [ ] Assignments built and attached to the **same** upload request as
      the files — never a follow-up call.
- [ ] Multiple assignment groups (different subsets, different fields)
      supported in one `assignments` array.
- [ ] Old `bulk_gender`/`bulk_nationality` fields removed from the
      Excel/CSV upload flow entirely.
- [ ] Post-upload UI reads `successful_users[i].gender`/`.nationality`
      directly from the response.

## 11. Tests (backend)

`tests/test_document_type_ocr_response.py` (extended, no new file) — 18
new tests: Users 1–5/6–10 split assignment, independent Nationality
subset, combined Gender+Nationality on one user, unselected users
unchanged, assignment overriding a conflicting OCR-extracted value,
unrelated `custom_fields` preserved, response values correct, invalid
Gender/Nationality rejected, `All` rejected for both fields, out-of-range
`file_indices` rejected with nothing created, malformed JSON rejected, an
entry with neither field rejected, omitted `assignments` behaving exactly
as before. Plus 2 regression tests confirming the Excel endpoint now
silently ignores the legacy fields and still unconditionally requires its
`gender`/`nationality` columns.

`tests/test_permission_consent_workflow.py` reverted to its exact
pre-Excel-feature state (the Excel-specific bulk-override tests removed
along with the feature itself — see `changes_trumarkz.md`).

**Results:** `python -m pytest tests/test_document_type_ocr_response.py tests/test_permission_consent_workflow.py tests/test_gst_and_auto_verification.py -q` → 191 passed, 0 failed. Full suite result in `changes_trumarkz.md`.

## 12. Known limitations

- Excel-sourced and OCR-extracted (non-assigned) values aren't validated
  server-side — unchanged, pre-existing behavior.
- `GET /verification/batches/{batch_id}` not checked for `custom_fields`
  exposure.
- No runtime endpoint for the nationality list — both clients keep a
  hand-synced copy.
- Assignment precedence for a file index targeted by multiple entries for
  the *same* field is "last in array order wins" — a fixed rule, but
  worth double-checking client-side array ordering if ever building the
  array programmatically from a UI state object (e.g. a `Set`/`Map`
  whose iteration order isn't guaranteed) rather than a literal list.
