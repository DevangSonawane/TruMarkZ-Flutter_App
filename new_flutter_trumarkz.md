
---

## 12. New (2026-10-21): Permission Required / Open Search — Human batches only

A new consent workflow exists on the backend, scoped **strictly to Human
batches** — Product and Warranty batches are completely unaffected by it,
under every configuration (verified; see `changes_trumarkz.md` for the
full backend history and the Human-only scope fix). Only the parts below
touch organization-side API contracts this app already calls or could
reasonably call; everything else about this feature (consent emails to
the end recipient, the public accept/reject page, the 24h expiry
scheduler, SQL migrations) is backend/ops-internal or belongs to the
recipient, not the organization, and is intentionally not covered here.

**Backend contract verified; Flutter UI implementation could not be
verified** — same caveat as §10: this repository contains backend code
only.

### 12a. Organization permission setting (new, optional)

If this app already calls the organization profile endpoints, two already-
existing calls gained one new optional field:

| Method | Path | New field | Values |
|---|---|---|---|
| GET | `/auth/me` | `permission_mode` in the response | `"open_search"` \| `"permission_required"` \| `null` (null = open_search, every existing organization) |
| PATCH | `/auth/me` | `permission_mode` in the request body | `"open_search"` \| `"permission_required"` (aliases `"public"`/`"private"` also accepted) |

This sets an organization-level **default**. It is not required for any
existing functionality — nothing breaks if this app never sends it.

### 12b. Human batch creation — email becomes conditionally required

**Not confirmed whether this app performs Human batch creation at all**
(no batch-creation flow is referenced anywhere else in this document) —
documented here only in case it does. If this app calls
`POST /verification/bulk-upload`, `POST /verification/bulk-upload/documents`,
or `POST /verification/single/human` for Human batches, and the
resolved mode for that batch is `permission_required` (via the batch's own
`credential_visibility` or the organization's `permission_mode` default —
§12a), **email becomes a required, validated field**:
- Excel upload: a missing `email` column → `400`; a blank/invalid cell on
  an otherwise-valid row → that row is rejected with a validation error,
  same shape as an existing missing `full_name`/`dob`/`gender`/`nationality`
  error.
- Single-human upload: unaffected — email was already required there.

For `"open_search"` (every existing organization's default, and any batch
whose `credential_visibility` is `"public"`), **nothing changes** — email
stays fully optional, exactly as before.

### 12c. New per-user fields on endpoints this app already calls

`GET /verification/all` and `GET /verification/user/{user_id}` — both
already in this app's contract (§4) — now additionally return, per Human
user:
```json
{
  "consent_status": "pending | accepted | rejected | null",
  "consent_deadline": "2026-10-22T10:00:00Z",
  "consent_auto_expired": false
}
```
- `null` for every Product/Warranty user and every Open Search Human user
  (not applicable to them — never populate a "consent" UI element for
  those).
- `"pending"`/`"accepted"`/`"rejected"` only ever appear for a Human user
  whose batch resolved to Permission Required.
- `consent_auto_expired: true` means a `"rejected"` status was reached by
  the 24h deadline passing with no response, not by the person explicitly
  declining — useful if this app wants to show that distinction, but both
  states mean the same thing for eligibility (excluded from further
  processing either way).
- **Known gap:** `GET /verification/batches/{batch_id}` (§4's primary
  batch-detail endpoint) does **not** currently include these three
  fields — its response is built independently and was not extended in
  this pass. If this app needs consent status specifically on that
  endpoint, that is separate, not-yet-made backend work, not something to
  build around on the client.

### 12d. What this app should NOT build for this feature

- No public consent accept/reject screen — that is the end recipient's
  flow (a no-login, token-based web link sent by email), not part of the
  organization app.
- Nothing for Product or Warranty batches — the consent fields above are
  always `null` for them and require no handling.
- No scheduler/expiry-trigger UI — expiry is a backend/ops concern.

---

## 13. New (2026-10-22): Organization Batch Deletion Notifications

A superadmin permanently deleting a batch now creates an **in-app**
notification for the batch's own organization — no email is sent for
this, by design. This is brand-new backend infrastructure (no
notification system existed before it; see `changes_trumarkz.md` for the
full history) and **nothing on the Flutter side has been built against
it yet** — the sections below are the verified API contract for doing
that, not a description of completed Flutter work.

**Backend contract verified; Flutter UI implementation could not be
verified** — same caveat as §10/§12: this repository contains backend
code only.

### 13a. Fetch notifications

```
GET /verification/notifications?unread_only=<bool>&limit=<1-200>&offset=<int>
```
- `unread_only` — optional, default `false`.
- `limit` — optional, default `50`, must be `1`-`200`.
- `offset` — optional, default `0`.
- Same bearer-token organization authentication as every other endpoint
  in §4's table — no new auth mechanism.
- Response: a plain list, newest first —
```json
[
  {
    "id": "uuid",
    "notification_type": "batch_deleted",
    "message": "Batch 'Q1 Onboarding' was deleted by the superadmin and is no longer available.",
    "batch_id": "uuid-or-null",
    "is_read": false,
    "created_at": "2026-10-22T10:00:00Z"
  }
]
```
- `batch_id` is a **historical reference only** — the batch it points to
  has already been permanently deleted by the time this notification
  exists. **Do not attempt to open or fetch that batch's detail page**
  from this id; `GET /verification/batches/{batch_id}` will 404 for it
  (the same generic "not found" every nonexistent/foreign batch id
  already gets — see §11). Show the notification's own `message` text,
  not a link into the deleted batch.
- `notification_type` is a plain string, currently always `"batch_deleted"`
  for this feature — treat it as an extensible field (a future
  notification type needs no new endpoint), not a fixed enum.

### 13b. Mark one notification as read

```
POST /verification/notifications/{id}/read
```
- No body.
- `200 {"id": "uuid", "is_read": true}` on success.
- `404` if the id doesn't exist **or belongs to a different
  organization** — this app can never read or affect another
  organization's notification, and the 404 does not distinguish which
  reason applies (consistent with this backend's existing convention of
  never confirming another tenant's data exists at all).

### 13c. Mark all notifications as read

```
POST /verification/notifications/read-all
```
- No body, no parameters — always applies to the calling organization's
  own unread notifications only.
- `200 {"marked_count": <int>}` — the number actually flipped from
  unread to read by this call.

### 13d. Organization UI behavior

- Surface new notifications in this app's existing notification/bell
  area, with the usual unread indicator (`is_read: false`) and a way to
  mark one (§13b) or all (§13c) read.
- Empty list → show a normal "no notifications" empty state, not an
  error.
- Handle `401`/`403` (expired/invalid session) the same way this app
  already handles them elsewhere — nothing new here.
- **No real-time delivery exists** — there is no WebSocket or push
  mechanism anywhere in this backend (confirmed by inspecting the
  codebase). If this app needs to show a new notification while already
  open, the only option is re-polling `GET /verification/notifications`
  (e.g. on app/dashboard resume, and optionally on a periodic timer while
  the relevant screen is visible) — the same "re-fetch, no live push"
  pattern this document already describes for picking up updated
  verification results in §10.
- Do not send an email or implement any email-based notification for
  this feature — the backend deliberately does not, and the Flutter app
  should not invent one either.

### 13e. What this app should NOT build for this feature

- No superadmin-side deletion UI — deleting a batch is a superadmin-only
  backend action; nothing here suggests or requires the organization app
  to expose a delete action of its own.
- No attempt to re-open, preview, or link to the deleted batch from a
  notification — see the `batch_id` caveat in §13a.