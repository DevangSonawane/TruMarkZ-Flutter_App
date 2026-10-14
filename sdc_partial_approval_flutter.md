# Flutter Developer Handoff — Partial-SDC Approval (Organization Side Only)

Scope note: this covers **only** what an organization-side Flutter screen needs for the new mandatory partial-SDC approval workflow. It deliberately does **not** cover the superadmin dashboard (selecting users, triggering generation, retrying) or any verifier-facing UI — those are out of scope for this handoff.

---

## What this feature is

When a superadmin tries to generate SDCs (certificates) for a batch and the selection includes someone who isn't *fully* verified yet (some required check still pending/rejected, even if they already passed at least one check), the system blocks generation and creates a **pending approval request** scoped to that exact batch + exact set of users. Your organization needs to see these requests and approve or reject them. Nothing generates until your organization says yes.

---

## Retrieving pending (and past) approval requests

**`GET /sdc/batches/{batch_id}/approvals`**

Auth: same as your existing org-authenticated calls (org token). Only returns requests for batches your organization owns — a batch belonging to another org returns `404`.

Response — a list, newest first, every request ever made for that batch (not just pending ones):

```json
[
  {
    "id": "9d1f2e3a-5b7c-4a1e-9c3d-1a2b3c4d5e6f",
    "batch_id": "6f5e4d3c-2b1a-4c3d-8e7f-9a0b1c2d3e4f",
    "org_id": "<your org's id>",
    "selected_user_ids": ["<batch_user_id>", "<batch_user_id>"],
    "status": "pending",
    "requested_by": "<superadmin user id, or null>",
    "created_at": "2026-01-15T09:30:00Z",
    "decided_by": null,
    "decided_at": null,
    "decision_reason": null
  }
]
```

Field meanings:
- `status`: `"pending"` (needs your decision), `"approved"`, or `"rejected"` — once approved/rejected, a request never changes again.
- `selected_user_ids`: the **exact** batch users this request covers — not the whole batch. If you want to show names instead of raw ids, cross-reference against the batch's own user list (which you already fetch elsewhere) by id.
- `requested_by` / `decided_by`: user ids, nullable — resolve against your existing user-lookup if you want to display who acted.

**Suggested display:** filter client-side for `status == "pending"` to drive a badge/notification count; show the full list (including decided ones) in a "history" view so the org can see what they already approved/rejected and for whom.

If you need to know *which batch(es)* have pending requests across the whole org without fetching batch-by-batch, there is currently no single cross-batch listing endpoint — you'll need to check per batch (e.g., when the org opens a batch's detail screen, fetch this alongside whatever else you already load for it).

---

## Inspecting the selected-user scope

`selected_user_ids` is a flat array of batch user ids. There is no separate endpoint that expands these into full user objects — reuse whatever call your app already uses to fetch a batch's user list (you'll already have it loaded on a batch detail screen), and match by id locally to show names/details for the affected users.

---

## Approving or rejecting

**`POST /sdc/approvals/{request_id}/decide`**

Auth: org token, same as above. **Only your organization's own account** can decide a request belonging to your org — this is enforced server-side regardless of what the client sends.

Request body:
```json
{
  "decision": "approved",
  "reason": "Optional free-text note — shown back in decision_reason"
}
```
`decision` must be exactly `"approved"` or `"rejected"` (case-insensitive, but send lowercase). `reason` is optional.

Success response (`200`) — the updated request, same shape as the list item, now with `status`, `decided_by` (your org's user id), `decided_at`, and `decision_reason` populated.

**Error handling:**
- `404` — the request doesn't exist, or doesn't belong to your organization. Treat this the same as "not found" in your UI (don't try to distinguish "wrong org" from "doesn't exist" — the API deliberately doesn't tell you which, to avoid leaking existence of other orgs' data).
- `409` — this request was already decided (someone else on your team already acted, or you're resubmitting a stale screen). Refresh the list and show the already-recorded decision instead of retrying.
- `400` — malformed `decision` value — shouldn't happen if you're sending `"approved"`/`"rejected"` from a fixed UI choice, but guard against it defensively.

**What happens after you approve:** nothing generates automatically. Approving only unblocks a *subsequent* superadmin action (out of scope here) for that exact same selection. If the org later sees the request is still "approved" but nothing happened, that's expected — it's waiting on the superadmin side, not something your screen needs to re-trigger.

---

## Refresh / repeated-submission handling

- After calling `/decide`, re-fetch `GET /sdc/batches/{batch_id}/approvals` (or just use the response you got back) to update the local list — don't assume success silently; confirm the returned `status` matches what you sent.
- Disable the approve/reject buttons for a request as soon as you've successfully decided it (client-side), and treat a `409` on a retry (e.g. double-tap, flaky network) as "already handled" — show the existing decision rather than an error toast.
- Two different pending requests can legitimately exist for the *same batch* if the superadmin tried two different selections — don't assume one batch has at most one pending request.
- **Follow-up audit note:** the `decide` endpoint now enforces "only one decision ever wins" at the database level (an atomic conditional update), so if two team members on the same org account tap approve/reject on the same request within the same instant, exactly one of them gets the `200` and the other gets `409` — never two conflicting decisions silently applied. No change needed on your side; this just makes the `409` case above a reliable guarantee rather than a best-effort check.

---

## What you do *not* need to build

- No screen for triggering SDC generation itself (superadmin-only).
- No verifier-facing upload/report UI.
- No need to compute or validate "who is fully verified" — that's entirely server-side; you only ever see a request once the server has already decided it needs approval.
