# TruMarkZ Push Notifications — Flutter Integration Reference

Audience: the Flutter developer.
Status: **this is integration guidance derived from the verified backend
contract. No Flutter code has been written, inspected, or edited by this
agent at any point — no Flutter repository has ever been made available
in this environment.** Nothing here is proof that Flutter-side work
exists or has started.

This is a new, standalone document, created alongside (not replacing)
`trumarkz_flutter.md` and `new_flutter_trumarkz.md`, which document
unrelated features (the consent workflow, in-app organization
notifications) this document does not repeat. Note for context, not
corrected here: an earlier audit this session found `trumarkz_flutter.md`
had lost prior sections (§12/§13) outside of any edit this agent made;
`new_flutter_trumarkz.md` still has them intact. Neither file was touched
to produce this document.

---

## 1. Purpose and scope

What the Flutter app needs to do to register Android/iOS devices for FCM
push and receive the one currently-implemented push event
(superadmin batch deletion). Everything here is verified against the
actual backend source code in this session, not assumed from an earlier
report.

## 2. How the Flutter app communicates with the backend

Standard REST over the same bearer-token authentication every other
endpoint in this backend's Flutter-facing contract already uses — no new
auth mechanism. Base URL: whatever this app already uses for the rest of
the TruMarkZ API.

## 3. Backend endpoints, payloads, authentication, response behavior (verified from `api/routers/push.py` + `api/schemas/push.py`)

```
POST   /push/tokens
  Body:     {"token": "<fcm-token>", "platform": "android" | "ios"}
  Auth:     Bearer token, any authenticated account type
  200:      {"id": "uuid", "platform": "android", "created_at": "...", "updated_at": "..."}
             — the raw token value is NEVER returned
  422:      invalid/missing "token", or "platform" not one of the three
             allowed values (web/android/ios — validated case-insensitively)

GET    /push/tokens
  Auth:     Bearer token, any authenticated account type
  200:      [ {same shape as above}, ... ]  — the calling account's own
             devices only

DELETE /push/tokens?token=<value>
  Auth:     Bearer token, any authenticated account type
  200:      {"removed": true | false}  — ALWAYS 200. false covers both
             "token doesn't exist" and "token belongs to a different
             account" — never distinguishable, by design, so this
             endpoint can never be used to probe whether a token exists.
```

**Upsert behavior, important for this app's logic:** `POST /push/tokens`
upserts by the token's own value, not by `(user, token)`. If the exact
same token is already registered to a *different* account (a shared/
reused device where a different user previously logged in), registering
it again under the current account **reassigns** that row — the previous
account can no longer receive pushes to that device the moment this
happens. This app does not need to do anything special to get this
behavior; it's automatic on the backend.

## 4. Firebase project configuration information safe to document here

- Firebase project ID: **`trumarkz-dc7f0`** (as reported by the project
  owner; this agent has no Console access and did not independently
  verify this value).
- This may or may not be the same underlying GCP project as the one
  hosting the backend's Cloud Run service (`trumarkz`) — **do not assume
  they are the same project.** See `push_notification_web_trumarkz.md`
  §7 for the full cross-project caveat; it applies equally here.
- No Android app, iOS app, or any client app has been confirmed
  registered in this Firebase project as of this document — not
  verifiable from this backend repository.

## 5. Android package name — requires verification against the real Flutter project

The backend owner has specified **`com.asynk.trumarkz`** as the intended
Android `applicationId`. **This has not been verified against this
project's actual `android/app/build.gradle` (or `.gradle.kts`)** — no
Flutter repository has been accessible to this agent at any point in
this engagement. **Before registering this package name in Firebase
Console, the Flutter developer must confirm it matches the real
`applicationId`/`namespace` across every build variant this app actually
ships.** A mismatch here means FCM silently never reaches the real APK,
with no error anywhere to indicate why. If iOS is in scope, check
`ios/Runner`'s bundle identifier **separately** — it is commonly
different from the Android package name and must not be assumed to
match it.

## 6. Firebase client configuration prerequisites

- **`google-services.json`** (Android) — downloaded from Firebase
  Console once the Android app is registered there; place at
  `android/app/google-services.json`. **Its contents are not reproduced
  anywhere in this document** and must never be committed to a public
  repository — follow this project's own secret-handling convention.
- **`GoogleService-Info.plist`** (iOS, only if iOS is in scope) — added
  via Xcode (drag into the Runner target, not just the filesystem) so
  it's actually included in the build.
- `firebase_core` and `firebase_messaging` Flutter packages — pick
  versions compatible with this project's actual Flutter/Dart SDK
  constraints (check `pubspec.yaml`); do not assume the latest published
  version is safe without checking.

## 7. Device-token registration and refresh flow

1. `Firebase.initializeApp()` at app startup.
2. `FirebaseMessaging.instance.getToken()` to obtain the current device
   token.
3. `POST /push/tokens` with that token and `platform: "android"` or
   `"ios"` (§3) — call this once a token is obtained.
4. Listen for `FirebaseMessaging.instance.onTokenRefresh` and repeat step
   3 on every rotation — the backend's upsert behavior (§3) makes this
   safe to call repeatedly with no deduplication logic needed client-side.

## 8. Notification permission requirements

- `FirebaseMessaging.instance.requestPermission()` — **required
  explicitly on iOS**; Android 13+ also requires the runtime
  `POST_NOTIFICATIONS` permission prompt.
- Request at an appropriate point in the user journey, not blindly on
  every app launch — the OS itself remembers a prior grant/denial;
  there's no need for this app to track that state separately.

## 9. Foreground, background, and notification-tap handling

- **Foreground** (app open and focused): `FirebaseMessaging.onMessage` —
  show an in-app indicator; the OS does not show a system notification on
  its own in this state.
- **Background/terminated:** `FirebaseMessaging.onBackgroundMessage`
  (must be a top-level/static function) — Android requires a default
  notification channel configured for this to actually surface a system
  notification.
- **Notification tap:** `FirebaseMessaging.onMessageOpenedApp` (and
  checking `getInitialMessage()` for a cold start from a terminated
  state) — use the `data` payload only as a hint to navigate/refetch from
  the authenticated API. **Never trust the payload as a source of
  truth** — the backend deliberately keeps it minimal
  (`{"notification_type": "batch_deleted", "batch_id": "<uuid-or-absent>"}`
  for the one event implemented today) and never puts
  verification/identity detail in a push payload at all.

## 10. Logout / account-switch token cleanup

On logout, call `DELETE /push/tokens?token=<current-token>` (§3) before
clearing local session state, if the platform SDK makes the current
token retrievable at that point. This is best-effort — even if skipped,
the backend's upsert-reassignment behavior (§3) independently protects
the next account that logs into the same device.

## 11. Backend vs. Flutter responsibilities

| Backend already does | Flutter app must do |
|---|---|
| Stores/scopes tokens securely; never returns raw token values | Obtain the token from the platform SDK and send it |
| Upserts/reassigns on re-registration | Call `POST /push/tokens` on every token obtain/refresh |
| Removes FCM-confirmed-dead tokens automatically | Nothing — fully automatic |
| Sends the push on batch deletion, best-effort, failure-isolated | Handle the three delivery states (foreground/background/tap) |
| Never includes sensitive data in the push payload | Never assume the payload carries more than a navigation hint |

## 12. Testing instructions and integration checklist

**Backend-side verification already done** (mocked; see
`push_notification_web_trumarkz.md` §13 for the full backend test
report) — **nothing here substitutes for an actual device test**, which
this agent cannot perform (no Flutter build environment, no real
Firebase credentials, explicitly out of scope to send real notifications).

Flutter-side checklist (none of this has been done by this agent):
- [ ] Confirm `com.asynk.trumarkz` against the real `applicationId` (§5)
- [ ] Register the Android (and iOS, if applicable) app in Firebase
      Console project `trumarkz-dc7f0`
- [ ] Add `google-services.json` / `GoogleService-Info.plist`
- [ ] Implement token registration/refresh (§7) against a backend
      environment where `FIREBASE_SERVICE_ACCOUNT_JSON` is actually
      configured (confirm with the backend owner before testing — see
      `push_notification_web_trumarkz.md` §7's operational risk note)
- [ ] Implement foreground/background/tap handling (§9)
- [ ] Implement logout cleanup (§10)
- [ ] A real, authorized device test — the project owner has stated this
      will be verified separately; this agent makes no claim about it

## 13. Known limitations and outstanding work

- Only one push event exists today: superadmin batch deletion. Other
  event types have been proposed but not yet confirmed or built — do not
  build a fixed `switch`/enum over `notification_type`; treat it as an
  open string.
- No real end-to-end delivery has ever been performed or verified by
  this agent, in any environment, at any point in this engagement.
- IAM permission for the key's own service account to send FCM in
  project `trumarkz-dc7f0` is unverified (see
  `push_notification_web_trumarkz.md` §8).
- Whether the `fcm_device_tokens` migration has been applied to the live
  database is unverified (see `push_notification_web_trumarkz.md` §12).
