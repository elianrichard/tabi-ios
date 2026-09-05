# Plan: Event Invite Hotlinks (Universal Links + signed-JWT tokens)

## Context

Today an event owner shares a join link, but the flow is inconsistent and insecure:
`EventInviteView` builds `https://tabi-web.vercel.app/join?eventId=<raw eventId>` for Copy/Share
while the QR encodes `tabisplit://join-event?event-id=<raw eventId>` — two different schemes and
param names, and the raw eventId is a permanent, un-scoped credential: anyone who ever sees it can
join forever.

Goal: replace the raw-eventId link with a **1-hour signed invite token** at
`https://tabisplit.my.id/join?token=...`. Tapping it opens the app via **Universal Links** (App Store
fallback if not installed), which joins the event automatically. Error dialogs for already-joined and
expired/invalid token.

**Decisions (confirmed):** signed JWT (no Redis/table) · Universal Links + AASA · App Store fallback
(invite context dropped post-install for v1) · **iOS target branch: `origin/feat/navigation`**
(all iOS line refs below are on that branch, not `main`).

---

## Backend — `tabi-service`

### 1. Generate invite token — `POST /event/:id/invite-token`
- **Route** `internal/delivery/http/route/route.go` (event group ~:62, after `/join/:id`):
  `group.Post("/:id/invite-token", c.EventController.CreateInviteToken)`.
- **Controller** `internal/delivery/http/event_controller.go` (mirror `Join` :190-206):
  read `ctx.Params("id")`, `authenticatedUserID(ctx)`, call usecase, `ctx.JSON(resp)`.
- **Usecase** `internal/usecase/event_usecase.go` new `CreateInviteToken`:
  - verify event exists (`EventRepository.FindByID`) and caller is a member
    (`UserEventRepository.ExistsByEventAndUser`) → else `fiber.ErrForbidden`.
  - mint token reusing the `issueSession` idiom (`auth_usecase.go:203-227`):
    `exp := time.Now().Add(time.Hour).Unix()`; `lib.GenerateToken(...)`.
    - **Reuse `lib.GenerateToken` as-is** (`internal/lib/jwt.go:9-22`) — it signs a single
      `userId` claim. Pass the **eventId** as that claim value. Sign with a **dedicated key**
      `app.secret_invite` (add to `config.json` + `.env.example`) so an invite token can NOT be
      replayed as a bearer access token in `NewBearerAuth`.
      `ponytail:` reuse GenerateToken with eventId-in-userId claim; add a typed invite claim only if a second field is ever needed.
  - return `model.InviteTokenResponse{ Token, ExpiresAt }`.
- **Model/converter** add `InviteTokenResponse` to `internal/model/event_model.go` + converter in
  `event_converter.go`.

### 2. Join by token — `POST /event/join-by-token/:token`
- **Route** (same group): `group.Post("/join-by-token/:token", c.EventController.JoinByToken)`.
- **Usecase** new `JoinByToken(ctx, userID, token)`:
  - `lib.ParseToken(token, app.secret_invite)` → on error return
    **`fiber.NewError(fiber.StatusBadRequest, "Invite link expired or invalid")`** (ParseToken already
    rejects expired tokens). **Must be 400/409, NOT 401** — the iOS client treats 401 as
    session-expired and triggers logout instead of showing the dialog (see iOS step 6).
  - eventId = claims`["userId"]`.
  - **then reuse the exact `Join` body** (`event_usecase.go:433-467`): tx, `FindByID`,
    `ExistsByEventAndUser` → if exists `fiber.NewError(fiber.StatusConflict, "User already joined event")`,
    create `entity.UserEvent{GenerateUUID()...}`, commit.
  - `ponytail:` extract the shared tx+dedupe+insert into a private `join(tx, eventID, userID)` so
    `Join` and `JoinByToken` don't duplicate 30 lines.
  - return `EventJoinResponse` (existing).
- **Controller** `JoinByToken`: `ctx.Params("token")`, `authenticatedUserID`, call usecase.

No migration, no Redis. `app.secret_invite` is the only new config.

---

## Web — `tabi-web` (App Router, deployed tabisplit.my.id)

### 3. `/join` route — `src/app/join/route.ts` (Route Handler, 302)
Reads `?token=`, redirects to the Universal Link `https://tabisplit.my.id/join?token=<token>`
**itself is the universal link** — so the page only needs to exist as the AASA-matched path AND
provide the App-Store fallback for when the app is not installed. Minimal handler:
- Serve a tiny HTML page (client) that attempts nothing special — iOS intercepts the URL before the
  page loads when the app is installed (that's how Universal Links work). If it loads, app isn't
  installed → JS redirects to `APP_STORE_URL` (`https://apps.apple.com/id/app/.../id6736793455`,
  currently hardcoded in `page.tsx:18`).
- Simplest: `src/app/join/page.tsx` (client component) that `window.location = APP_STORE_URL` on mount.
  `ponytail:` App Store fallback only; deferred deep link (preserve token post-install) later if asked.

### 4. AASA file — `public/.well-known/apple-app-site-association`
JSON, no extension:
```json
{ "applinks": { "apps": [], "details": [
  { "appID": "5E27WSDAU2.com.sora.TabiSplit", "paths": ["/join", "/join?*"] } ] } }
```
- **`5E27WSDAU2` is NOT in the repo** (injected at signing) — must be supplied. Placeholder until then.
- Force content type in `next.config.js` (currently empty `{}`) via `headers()`:
  `/.well-known/apple-app-site-association` → `Content-Type: application/json`.
  `ponytail:` header override over a route.ts — static file + one header rule is the smaller diff.

---

## iOS — `tabi-ios`

### 5. Associated domains
- `Tabi Split/Tabi Split.entitlements`: add
  `com.apple.developer.associated-domains` = `["applinks:tabisplit.my.id"]`.

### 6. Handle the https link — `ContentView.swift handleIncomingURL` (feat/navigation :118-155)
Currently only `scheme == "tabisplit"` (:119) + host `join-event` (:128) + query `event-id` (:133),
and it **swallows all join errors in a `print`** (:150) and does a silent local-dedupe `return`
(:137-140). Add a branch + fix the error swallowing:
- if `url.host == "tabisplit.my.id"` && path == `/join` && query `token` present →
  `Task { try await EventService.shared.joinEventByToken(token:) }` then `router.popToRoot()`.
- **Error dialogs — reuse the existing global dialog, don't build new alerts.**
  `APIService.notifyError` (:160-168) already auto-fires `ErrorDialogViewModel.shared.show(<backend msg>)`
  on every API error except `.unauthorized`. So:
  - **Do NOT swallow the join error in `print`** — let it propagate so `notifyError` pops the dialog.
    "User already joined event" (409) then shows automatically with the backend message.
  - Expired/invalid maps to **401 `.unauthorized`, which `notifyError` skips** (:164) → would wrongly
    trigger the session-expired/logout path. So `joinEventByToken` must return a **non-401** status for a
    bad invite token: backend returns **409/400** (not 401) for expired/invalid, and iOS shows it via the
    same dialog. (Update backend step 2 accordingly — see note there.)
    `ponytail:` reuse `ErrorDialogViewModel.shared` + `notifyError`; only tailor the copy if the raw
    backend strings ("User already joined event" / "Invite link expired or invalid") read badly.
- Keep the existing local-SwiftData dedupe pre-check (:137-140) as a fast path, but let it also `show`
  the already-joined dialog instead of silently returning.

### 7. New service method — `EventService.swift` (mirror `joinEvent` :65)
```swift
func joinEventByToken(token: String) async throws {
  let _: JoinEventResponse = try await apiClient.post(endpoint: "/event/join-by-token/\(token)", body: Empty())
}
```
Reuse existing `JoinEventResponse` (`EventSchema.swift:105`).

### 8. Invite UI — `EventInviteView.swift` (feat/navigation)
- `deeplinkHost` (:44) → `tabisplit.my.id`. Today the three actions build **three inconsistent
  shapes**: Copy `https://.../join?eventId=` (:67), Share same (:72-76), QR
  `tabisplit://join-event?event-id=` (:178). Unify all to **`https://tabisplit.my.id/join?token=<token>`**.
- Token is per-share and must be fetched: when the invite sheet appears, call a new
  `EventService.createInviteToken(eventId:)` → `POST /event/:id/invite-token`, cache the token in the
  view for Copy (:57-71), Share (:72-76), QR (:178; `generateQRCode` :301-317, reuse as-is).
  `ponytail:` fetch one token when the sheet opens, reuse for all three buttons; refetch only if the
  1h window lapses while the sheet is open (rare) — no per-tap network call.
- The new `EventInviteShareButtonView` (presentational, takes `text/icon/action?`) is unchanged —
  just feed it the token-based URL.
- Add `createInviteToken` to `EventService` + an `InviteTokenResponse` Codable in `EventSchema.swift`.

---

## Verification (end-to-end)

1. **Backend unit**: table test in `event_usecase_test.go` (if present) or a `demo()`-style check:
   generate token → parse → assert eventId round-trips and an `exp` 61 min in the past is rejected by
   `ParseToken`. Also assert `JoinByToken` returns 409 when `ExistsByEventAndUser` is true.
2. **Backend manual**: `make dev` (air), then
   `curl -X POST .../event/<id>/invite-token -H 'Authorization: Bearer <jwt>' -H 'X-Api-Secret: ...'`
   → get token; `curl -X POST .../event/join-by-token/<token>` with a *second* user's bearer → 200;
   repeat → 409; tamper token → 401.
3. **Web**: `bun run build` (already green) + `bun dev`; hit `/join?token=x` in a desktop browser →
   should redirect to App Store; `curl https://<preview>/.well-known/apple-app-site-association` →
   `200 application/json`. Validate with Apple's AASA validator once TEAM_ID is filled.
4. **iOS**: build via XcodeGen; on a device with the app installed, tap a real
   `https://tabisplit.my.id/join?token=...` from Notes → app opens, joins, `popToRoot`. Repeat with the
   same account → "already joined" dialog. Wait >1h or edit token → "expired/invalid" dialog. Delete app,
   tap link → App Store.

## Reference values
- **Apple Team ID:** `5E27WSDAU2` · **Bundle id:** `com.sora.TabiSplit` → AASA `appID` =
  `5E27WSDAU2.com.sora.TabiSplit`.
- **App Store id:** `6736793455` (fallback URL).
