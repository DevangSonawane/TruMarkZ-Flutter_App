# TruMarkZ — Flutter Developer Handoff (organization app)

The single Flutter handoff for every implemented backend feature that affects the
**organization** mobile app.

**Scope**
- SuperAdmin screens (bulk delete, Send to Organization, schema JSON and image upload, partial-SDC
  review, SDC generation) and the visitor and holder certificate-access pages are **Web-only** and
  are not part of this document.
- No Flutter repository was available to the backend team, so items depending on an existing
  screen are marked **"if the app has this screen"**. Do not add new screens for them unless
  product asks.

**Status.** The backend is implemented and covered by automated tests. It is **not deployed**, and
two migrations are pending (see H). Contracts below are taken from the backend code.

---

## A. Overview

- **APIs:** the same FastAPI backend (`PUBLIC_API_BASE`), with `Authorization: Bearer <organization JWT>`.
- **Errors:** `{"detail": …}`. `detail` is a string, or an object where noted.
- **What an organization can do:**
  - see its own batches, holders and their verification results;
  - create batches;
  - authorize partial SDCs;
  - read SDC status and records.
- **What an organization cannot do:** generate or issue SDCs, full or partial. Only a SuperAdmin
  does that, from the web.
- **Login and email OTP:** unchanged (section F).

---

## B. Organization batch management

- **Bulk delete** is a SuperAdmin-only web feature. **No Flutter change.**
- **Batch statuses:** unchanged (`pending`, `processing`, `verification_in_progress`,
  `verification_completed`, `sdc_generated`).
- **Batch creation** is unchanged except:
  - **Schema selection** (section C).
  - **Permission Required Human single upload** (`POST /verification/single/human`, batch
    `credential_visibility: "private"` or the organization's default): `dob` is now **required**.
    - Error: `400 {"detail": "dob is required for a Permission Required Human record"}`. Show it at
      the DOB field.
    - Email and phone rules are unchanged: both required, phone a valid mobile (10–15 digits,
      optional `+`).
  - **Excel** (`POST /verification/bulk-upload`) and **OCR** (`POST /verification/bulk-upload/documents`):
    unchanged rules. Keep showing the backend's per-row validation list and skipped files.
  - **Open Human, Product and Warranty:** no new required fields.

---

## C. Schema configuration

**Schema selection during batch creation** (if the app lets the organization choose a schema):
- List active configurations:
  `GET /auth/organizations/{own_org_id}/schema-configs?space_type=human&active_only=true` (or
  `product` / `warranty`).
- **Show** each `label` and its image. `image_url` is `null` when there is no image (use a
  placeholder). When set, it requires the bearer token: `Image.network(url, headers: {"Authorization": "Bearer …"})`,
  or fetch the bytes. `404` means no image.
- Pre-select `is_default: true`. Send the chosen `label` as `schema_name` (unchanged).
- **Stop sending `schema_variant`, and remove any variant choice.** New Human batches always use
  the Human 5-QR layout; the backend ignores the field for them.

**Editing schema configurations** (Dhiway schema JSON, mapping, images) is done on the web.
- **If the app already lets organizations edit their configurations:**
  - show the new response field `warning_details` (`[{code, severity, fields, message}]`) inline,
    never as pop-ups, and never block on it;
  - show `output_map_sources` (`auto` / `manual`);
  - show `400 detail.errors[]` as form errors;
  - an organization cannot edit a SuperAdmin-authored configuration (existing 403).
- **Otherwise:** no change.
- **Mapping warnings are never notifications.** The backend sends no email, push or in-app
  notification for them; they exist only in response bodies. If the app shows a pop-up for them
  today, that pop-up is app code: replace it with inline text.
- **Internal fields:** keep collecting the batch-creation fields in section B (email, phone, DOB,
  etc.) even when they are not on the certificate. The backend stores them and, when a stored
  Dhiway schema exists, sends Dhiway only the properties it declares.

---

## D. Organization partial SDC authorization

**If the app shows a batch's holders and their verification results**, add the authorization flow.
If it does not, this is web-only for now.

1. **Data** (backend implemented; existing endpoints):
   - **Batch list / dashboard:** `GET /verification/batches` → `[{org_id, organization_name,
     batches: [...]}]`. Per batch: `status`, `total_users`, `approved`, `rejected` (holder counts).
     It has no per-type data. There is no dedicated dashboard endpoint.
   - **Batch detail:** `GET /verification/batches/{batch_id}`. Each `users[]` entry has
     `verification_type_status` (`{type_name: {status, report_url?, …}}`), `verification_status` and
     `overall_status_label`; the batch has `verification_checks[]` (per type: `status`,
     `completed_users`, `approved_users`, `rejected_users`, `is_complete`).
   - **Refreshing is app work:** the backend never pushes verification completions (no push
     notification for this). To show newly completed verifications, poll while the batch is not
     finished (e.g. every 30–60 s while the screen is open), and stop at `verification_completed`
     or `sdc_generated`.
   - **Known limitation:** no aggregated "available for partial SDC" endpoint. Derive it: a holder
     with at least one `approved` type who is not fully approved.
2. **Selection:**
   - select holders who are **not** fully verified (fully verified holders get a full SDC from the
     SuperAdmin with no authorization);
   - per holder, select only `approved` verification types; pending and rejected are disabled;
   - a rejected type does not stop the holder's other approved types.
3. **Submit:** `POST /sdc/batches/{batch_id}/partial-authorizations`
   ```json
   { "holders": [ { "batch_user_id": "…", "verification_types": ["PAN Verification", "Aadhar Verification"] } ] }
   ```
   → `201 {"authorizations": [Authorization]}`. All-or-nothing:
   - `400 {"detail": {"message": "Invalid partial SDC authorization — nothing was saved.", "holders": [{"batch_user_id": "…", "errors": ["…"]}]}}`:
     show the errors next to each holder;
   - `409`: concurrent save, retry;
   - `404`: not the organization's batch.
4. **Status:** `GET /sdc/batches/{batch_id}/partial-authorizations` (optional `?status=` /
   `?batch_user_id=`) → `{"authorizations": [...]}`.
   - Show `status` (`active`, `generating`, `consumed`, `cancelled`, `superseded`), `is_valid`, and
     items with `current_state` (`valid`, `changed`, `not_approved`).
   - When `is_valid` is false, show "Results changed — authorize again". Re-submitting supersedes
     the old one.
5. **Cancel:** `POST /sdc/partial-authorizations/{authorization_id}/cancel` → Authorization
   (`409` unless active).
6. **No generation:** organizations cannot generate SDCs. Remove or hide any "Generate SDC" action.
   `POST /sdc/batches/{id}/generate` and `…/issue` return `403 {"detail": "Only a SuperAdmin can generate SDCs."}`
   to organizations.

**Authorization object**
```json
{ "id": "…", "batch_id": "…", "batch_user_id": "…", "org_id": "…", "holder_name": "Asha Rao",
  "status": "active", "is_valid": true, "stale_verification_types": [],
  "items": [ { "verification_type_name": "PAN Verification", "snapshot_status": "approved",
               "snapshot_report_url": "…", "snapshot_checked_at": null, "current_state": "valid" } ],
  "created_by": "…", "created_at": "…", "updated_at": "…", "cancelled_at": null, "superseded_by": null,
  "consumed_at": null, "consumed_by": null, "generated_public_id": null }
```

---

## E. Existing SDC sharing and status

- **Send to Organization** is a SuperAdmin web action. **No Flutter UI change.** The organization
  now also receives every issued SDC of that batch by email (one email per batch share); website
  and app access are unchanged.
- **SDC status:** `GET /sdc/batches/{batch_id}/status` (read only) is unchanged.
  - `certificate_ids` appear once the batch is shared.
  - A holder who received an additional SDC shows the newest credential once issued.
- **Records:** `GET /sdc/records/{public_id}` is unchanged.

---

## F. Existing authentication and OTP

- **No change.** Login, signup, email OTP and password reset behave exactly as before. No new OTP
  implementation is required.
- **Visitor and holder** certificate-access flows (visitor OTP, holder approval) are web pages.
  **No Flutter work.**

---

## G. API reference (endpoints Flutter calls)

| Method | Route | Change |
|---|---|---|
| GET | `/auth/organizations/{own_org_id}/schema-configs` | config gains `image_url`, `image_content_type`, `image_updated_at`, `dhiway_schema`, `dhiway_schema_properties`, `dhiway_schema_required`, `output_map_sources` |
| GET | `/auth/organizations/{own_org_id}/schema-configs/{config_id}/image` | **new**: image bytes; bearer token; 404 if none |
| POST | `/verification/single/human` | Permission Required: `dob` required (400) |
| POST | `/verification/bulk-upload`, `/verification/bulk-upload/documents` | unchanged |
| GET | `/verification/batches` | unchanged (batch list: status and holder counts; poll for progress) |
| GET | `/verification/batches/{batch_id}` | unchanged (source of holders' verification results; poll for progress) |
| POST | `/sdc/batches/{batch_id}/partial-authorizations` | **new** (if the holder screen exists) |
| GET | `/sdc/batches/{batch_id}/partial-authorizations` | **new** (if the holder screen exists) |
| POST | `/sdc/partial-authorizations/{authorization_id}/cancel` | **new** (if the holder screen exists) |
| GET | `/sdc/batches/{batch_id}/status`, `/sdc/records/{public_id}` | unchanged |
| POST | `/sdc/batches/{batch_id}/generate`, `/sdc/batches/{batch_id}/issue` | **now 403 for organizations**: remove any call |

---

## H. Flutter integration checklist

**Mandatory**
- [ ] Remove any organization "Generate SDC" / "Issue SDC" action (now 403).
- [ ] Stop sending `schema_variant`; remove any variant selector.
- [ ] Permission Required Human single upload: make DOB required; handle the 400.
- [ ] Schema selection: show the label and the authenticated image (if the app has a schema
  picker).

**Conditional (only if the screen exists)**
- [ ] Partial-SDC authorization: selection, submit, status, stale handling, cancel.
- [ ] Schema configuration editing: show `warning_details` inline and `output_map_sources`.

**Unchanged:** login and OTP, batch lists, Excel/OCR upload rules, Open/Product/Warranty creation,
SDC status and records.

**Web-only (no Flutter work):** bulk delete, Send to Organization, schema JSON and image upload,
SuperAdmin authorization review and SDC generation, visitor and holder certificate-access pages.

**Testing:** verify against a backend with these migrations applied:
- `sql/add_schema_config_dhiway_schema.sql`, `sql/add_schema_config_image.sql` (reported executed);
- `sql/create_sdc_partial_authorizations.sql`, `sql/create_certificate_access_grant_reports.sql`
  (pending).

**Known limitations**
- Authorizations cover holders who are not fully verified only.
- No push for verification progress; the app must poll (section D).
- The backend's PostgreSQL integration tests have not been run yet. Nothing is deployed.

---

## I. Requirements traceability (organization app)

"App pending" means not integrated in Flutter; no frontend item is marked done.

| # | Original request | Backend (implemented, not deployed) | Flutter change | Status | Known limitation |
|---|---|---|---|---|---|
| 1 | SuperAdmin bulk deletion | `POST /verification/batches/bulk-delete` (SuperAdmin) | **none** (SuperAdmin web only); deleted batches simply disappear from the list | unchanged for Flutter | — |
| 2 | Mapping warnings / unwanted notifications | warnings are response data only; no notification is sent | if a config-edit screen exists: inline `warning_details`, no pop-ups (C) | conditional · app pending | app source not inspected |
| 3 | Organization-controlled partial SDC | batch list/detail data; authorization API; SuperAdmin-only generation | if a holder-results screen exists: status display, polling, selection, submit, status, cancel (D); remove Generate/Issue (mandatory) | conditional · app pending | no push; no aggregated endpoint |
| 4 | Individual certificate report access | per-report visitor grants, holder per-report decisions | **none** (visitor and holder pages are web) | unchanged for Flutter | — |
| 5 | SDC email to the organization | share endpoint emails every issued SDC of the batch | **none** | unchanged for Flutter | — |
| 6 | Schema configuration images | upload (SuperAdmin), authenticated `GET …/image`, `image_url` | if a schema picker exists: show label + image with the bearer token (C) | conditional · app pending | 404 when no image |
| 7 | Remove schema variant | new Human batches always 5-QR; field ignored | stop sending `schema_variant`, remove any selector (mandatory) | app pending | — |
| 8 | Mapping inside Advanced Settings | automatic + manual output mapping, `output_map_sources` | mapping is edited on the web; if the app edits configs, show `output_map_sources` (C) | conditional · app pending | — |
| 9 | Internal vs Dhiway fields | all intake fields stored; only declared schema properties sent | keep collecting required intake fields (B, C) | unchanged behaviour | — |
| — | Only SuperAdmin generates SDCs | generate/issue 403 for organizations | remove any Generate/Issue action (mandatory) | app pending | — |
| — | Permission Required DOB | single Human upload 400 without `dob` | make DOB required (mandatory, B) | app pending | — |
