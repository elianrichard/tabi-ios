# Plan: Server-Backed Guest Accounts

## Goal

Convert "guest mode" from a local-only/offline SwiftData experience into a
**server-backed credential-less account**. Tapping "Sign in as Guest" creates a
real backend account (no email/credential), returns a token, and from then on
the app runs the **same authed code paths** as a Google/Apple user.

Guest requires internet (offline support is explicitly out of scope — see
Non-Goals). A guest account behaves identically to an authed account except it
has no real email; all UI affordances (share link, QR, owner tag, email-based
participant linking) are enabled for guests.

## Why

- Guest mode is currently the app's entire offline story, and it is unmaintained
  (there is **no reachability layer anywhere** in the codebase).
- Guest special-casing is ~105 `guest`/`isGuest`/`"Guest"` references across 19
  Swift files (verified by grep). The behavioral core is ~18 branches, each
  `if !isGuest { callBackend() }` wrapped around an unconditional SwiftData
  write — pure duplication of the authed path; the rest are UI guards, call-site
  `isGuest:` args, and the migration/sentinel layer.
- The guest→authed migration layer (`MigrationCoordinator`, `MigrateService`,
  `promoteGuestUserData`, `rewriteGuestEmails`, the `"Guest"` sentinel) exists
  ONLY to bridge local guest data to a real account. Server-backing guests from
  the first tap makes every event server-persisted (`isSynced=true`) and retires
  this entire layer.
- Two recent bugs (owner-tag mislabel, `Expense.coverer` delete crash) live
  inside guest special-casing / local-delete code that this refactor removes.

## Non-Goals

- **Offline support.** Guests will now hit the network and see the existing
  blocking error dialog on failed writes, exactly like authed users today.
  A proper reachability + offline-queue layer is a separate, app-wide project
  and is NOT part of this plan.
- Changing the Google/Apple sign-in flow.
- Rewriting SwiftData. It stays as the UI's source of truth and offline read
  cache for **all** users (authed and guest) — this is already how it works.

## Key facts (from codebase map)

- `isGuest` = `ProfileViewModel.isGuest` (`user.email == "Guest"`),
  `Modules/Home/Profile/ProfileViewModel.swift:17`. Threaded as an explicit
  `isGuest: Bool` param into view models.
- Guest identity minted in `LoginViewModel.guestLogin()`
  (`Modules/Login/LoginViewModel.swift:88`): a `CurrentUserDefaults` with
  email/name "Guest", empty userId, **no token**.
- SwiftData is load-bearing for everyone: authed writes ALSO go to SwiftData;
  the `!isGuest` guard wraps only the network call. Authed reads come from the
  API then mirror into SwiftData (`HomeViewModel.refreshEventData`,
  `Modules/Home/HomeViewModel.swift:93`).
- Auth today: passwordless find-or-create via Google/Apple `id_token` →
  `POST /auth/{google|apple}` → JWT + refresh token in Keychain
  (`Services/Auth/AuthService.swift:18`). **No anonymous/credential-less account
  endpoint exists** — this is the gating dependency.
- Requests carry `X-Api-Secret` + `Authorization: Bearer <token>`; 401 →
  refresh + retry, else clear tokens + post `.sessionExpired`
  (`Infrastructure/Networking/APIService.swift`).
- Backend already models a credential-less server row: **dummy users**
  (`dummy_user_id`, avatar, no login, promotable by email —
  `EventViewModel.swift:91`, `EventSchema.swift`). A guest account is nearly a
  dummy user + a token.

---

## Dependency (blocking): backend endpoints

**Nothing ships client-side until these exist.** Full backend spec, written
against the real Go/Fiber/GORM code, lives in
**`tabi-service/docs/plans/guest-account-endpoints.md`**. What the client relies
on:

- **`POST /auth/guest`** — mints a `user` row with the new `kind = "guest"` (the
  table already has a `Kind` discriminator: `real`/`dummy` → add `guest`), no
  email/password, random built-in avatar, an "Adjective Animal" name. Issues the
  same HS256 `{userId}` JWT + refresh token as OAuth and returns the existing
  `AuthLoginResponse` shape — the client reuses the token-storage path unchanged.
- The account is usable by every existing authed endpoint (`/event`, `/expense`,
  `/user`, participant routes) — a guest is just a `user`.
- **Guest signal**: the client must know "am I a guest?" to trigger a merge on
  later OAuth. Backend recommendation: **expose `kind` on the user profile**
  (`GET /user`) rather than adding a JWT claim. The client reads `kind` from the
  profile it already fetches and stores it on the current user. (If the backend
  instead adds an `isGuest` JWT claim, the client reads that — decided backend-side.)

### Claim / merge endpoint (in scope — Phase 5)

When a guest signs in with Google/Apple, the guest account is reconciled with the
provider identity so guest-owned data is never lost.

- **`POST /auth/{google|apple}` gains optional `merge_from_guest_token`** — the
  client sends the provider `id_token` PLUS the current guest's token. Absent =
  today's behavior, no regression.
- **Backend behavior** — find-or-create on the provider identity, then merge
  inside the existing OAuth transaction using the already-present
  `reassignUserRefs` engine (minus its event scope):
  - **Target account is new**: promote the guest row in place (flip `kind`→`real`,
    set email/name) — cheapest, no FK moves.
  - **Target account exists** (email already connected): repoint every user FK
    (`event.creator_id`, `expense.coverer_id`, `user_item.user_id`+`coverer_id`,
    `payment.payer/reciever`, `notification.*`, `info_payment.user_id`,
    `session.user_id`) guest → target, handling the `user_event`
    `(event_id,user_id)` unique and `user_item` `(item_id,user_id)` PK collisions
    (delete would-be-duplicates first), then soft-delete the empty guest row.
  - Return the authoritative account's `AuthLoginResponse` (merged account token).
- **Idempotent + transactional**: repeated merge is a no-op; a partial failure
  must not split ownership across two accounts (guaranteed by the single OAuth tx).
- The email + name come from the Google/Apple `id_token` (already captured at
  `LoginViewModel.signIn`).

---

## Client work

### Phase 1 — Mint a guest account on tap

**Files:** `Services/Auth/AuthService.swift`, `Modules/Login/LoginViewModel.swift`,
`Modules/Login/LoginView.swift`, `Infrastructure/Networking/KeychainService.swift`
(reuse).

1. Add `AuthenticationService.guestSignIn()` → `POST /auth/guest`, decode the
   `LoginResponse`, store `token` + `refresh_token` in Keychain (identical to
   the Google/Apple path).
2. Rewrite `LoginViewModel.guestLogin()`: call `guestSignIn()`, on success save
   the returned account (real `userId`, generated display name/avatar) to
   UserDefaults + SwiftData, set `SessionState.shared.isAuthenticated = true`,
   `router.popToRoot()`. Remove the "Guest" sentinel email — the account now has
   a real `userId`.

   **Generated display name + avatar** (client picks, sends to `/auth/guest`, or
   backend generates — decide with backend; client-side keeps it simple):
   - Name = random **adjective + animal**, e.g. "Happy Panda", "Glorious
     Giraffe". Add a small `GuestNameGenerator` (two curated word lists —
     positive adjectives + friendly animals) returning
     `"\(adjectives.randomElement()!) \(animals.randomElement()!)"`. Keep lists
     ~15–25 words each; avoid anything that reads oddly paired.
   - Avatar = `ProfileImageEnum.allCases.randomElement()!` (cases today:
     `owl, dragon, wallet, octopus` — `Infrastructure/Model/UserData.swift:72`).
     `UserData.init` already random-picks an image when none is given, but here
     pick explicitly so the chosen value is persisted and sent to the backend
     (so the same avatar shows across devices / after refresh).
   - Put the generator in something like
     `Infrastructure/Utils/GuestNameGenerator.swift`; unit-test that it always
     returns "Adjective Animal" and a valid enum case.
3. Handle failure (no network / server error): show the existing error dialog,
   stay on login. Guest now genuinely requires connectivity.

**Checkpoint:** guest can sign in, lands on Home, has a real token. App runs.

### Phase 2 — Remove behavioral `!isGuest` guards

The authed branch already exists next to each guest branch; delete the guard so
the authed path runs for everyone. Remove the now-unused `isGuest: Bool` params
as you go. Run the app after each file.

- `Modules/Event/EventViewModel.swift`: `handleEditEvent` (:68 — delete the
  email-strip loop entirely; guests now link by email like anyone),
  `handleCreateEvent` (:140), `handleDeleteEvent` (:169), `completeEvent` (:187),
  `incompleteEvent` (:205).
- `Modules/Event/EventExpense/EventExpenseViewModel.swift`: `finalizeExpense`
  (:333), `handleDeleteExpense` (:354), `handleUpdateExpense` (:387).
- `Modules/Event/EventForm/EditParticipant/EditParticipantViewModel.swift`:
  `remove` (:43 — drop the client-side "linked to expense" guard; backend
  enforces it) and `save` (:98 — drop the forced-empty-email path; guests link
  by email now). **Note:** this removes the client-side expense-link check added
  recently — the backend rejection is now authoritative for everyone.
- `Modules/Home/HomeViewModel.swift`: `refreshEventData` (:93 — guests fetch from
  `/event` like authed users).
- `Modules/Home/Profile/ProfileViewModel.swift`: `logout` (:24 — guests now call
  backend logout), `updateProfile` (:59), `refreshUserData` (:82), `deleteUser`
  (:98).
- `ContentView.swift`: `checkAuthentication` (:86 — guests require token +
  `probeSession()` like everyone; remove the forced-`isAuthenticated` branch),
  `handleIncomingURL`/join (:161 — guests join via API).
- `Modules/Home/HomeView.swift:96` — remove guest skip of `deleteUsersWithNoId()`.

**Call sites passing `isGuest:` into the above methods** — drop the argument when
the param is removed (no logic here, just plumbing):
`Modules/Event/EventDetail/EventDetailView.swift:154,192,229` (complete /
incomplete / delete event) and
`Modules/Event/EventExpense/ExpenseResult/ExpenseResultView.swift:34,120,126`
(delete / update / finalize expense), plus the invocations inside
`EditParticipantView.swift` and `EventFormView.swift`.

**Checkpoint:** create/edit/delete events + expenses as a guest, all persisting
to the backend and rehydrating via refresh.

### Phase 3 — Enable UI affordances for guests

Decision: **turn all guest-hidden UI on** (guest ≈ authed). Remove these guards:

- `Modules/Home/Profile/ProfileView.swift`: edit-profile pencil (:28), keep or
  adapt the "register to save" CTA (:72 — reframe as "link a real account" or
  drop; product call), logout/settings (:88).
- `Modules/Components/UserCard.swift`: "(Owner)" tag (:28), own-email display
  (:39 — guest has no real email; show a placeholder or hide just the email row).
- `Modules/Event/EventForm/EventInvite/EventInviteView.swift`: share-link/QR
  (:47), email-based invite (:97).
- `Modules/Event/EventForm/EditParticipant/EditParticipantView.swift`: email
  field (:26, :74) and the `isLinkingByEmail`/`isEmailInvalid` gating added
  recently — revert to unconditional.
- `Modules/Event/EventForm/EventFormView.swift:121,125` — drop `isGuest` pass.

**Checkpoint:** guest UI is indistinguishable from authed (minus real email).

### Phase 4 — Delete the migration/sentinel layer

Now that guest events are server-persisted from creation, nothing needs
migrating.

- Delete `Modules/Migration/MigrationCoordinator.swift` and
  `Services/Migrate/MigrateService.swift`.
- Delete `promoteGuestUserData` (`Infrastructure/SwiftData/UserSwiftData.swift:88`).
- Remove `MigrationCoordinator` calls: `LoginView.handleSignIn:128`,
  `ContentView.runMigrationIfNeeded:114`, and `SessionState.migrationRunning` /
  `lastMigrationError` if unused afterward. **The login sign-in path does not
  become a no-op** — it now triggers the server-side claim/merge (Phase 5)
  instead of the old client batch upload.
- Remove all `"Guest"` string-literal checks: `ContentView.swift:86,118`,
  `LoginView.swift:46,117`, `EventViewModel.swift:74,77`,
  `MigrationCoordinator` refs (file gone).
- Remove `ProfileViewModel.isGuest` and the `isGuest:` params if fully unused.
- Revisit `UserData.isSameUser` (`Infrastructure/Model/UserData.swift:57-69`) and
  its comment (:60): its "don't collapse multiple guests" logic leans on the
  `"Guest"` sentinel. With real distinct `userId`s per guest the identity match
  works correctly on `userId` alone — drop the sentinel-specific reasoning.

**Checkpoint:** no `isGuest` / `"Guest"` references remain except the deliberate
claim/merge path (Phase 5); grep confirms
(`grep -rniE "guest" "Tabi Split" --include="*.swift"`).

### Phase 5 — Guest → provider claim/merge on login

When a signed-in **guest** taps Google/Apple sign-in, hand off to the merge
endpoint so guest-owned events/expenses/participants are absorbed into the
provider account (existing or new). Replaces the deleted client migration.

**Files:** `Modules/Login/LoginViewModel.swift` (`signIn`),
`Services/Auth/AuthService.swift`, `Modules/Login/LoginView.swift`.

1. In `LoginViewModel.signIn`, detect that the current session is a guest (real
   `userId`, credential-less — tracked via a stored flag such as
   `CurrentUserDefaults.isGuest` since the `"Guest"` email sentinel is gone).
   If so, include the current guest token in the auth request
   (`merge_from_guest_token`, per the backend contract above) alongside the
   provider `id_token` + the email/name from Google/Apple.
2. Backend merges (existing account) or promotes in place (new account) and
   returns the authoritative `LoginResponse`. Client stores the new token,
   overwrites the local current-user, and does a full refresh
   (`refreshEventData` / `refreshUserData`) so SwiftData rehydrates from the
   merged account — no client-side row rewriting.
3. Non-guest sign-in (already a provider account, or fresh install) skips the
   merge and behaves exactly as today.

**Tracking the guest flag** — since `email == "Guest"` is retired, the client
needs a server-sourced marker to know when to request a merge. The backend plan
exposes **`kind` on the user profile** (`GET /user` → `real`/`dummy`/`guest`);
the client reads it via `ProfileService.getCurrentProfile` and stores it on
`CurrentUserDefaults` (e.g. `kind` or an `isGuest` bool derived from it). Source
of truth is the server's `kind`, so it can't drift. (If the backend adds an
`isGuest` JWT claim instead, read that — the choice is made backend-side; see
`tabi-service/docs/plans/guest-account-endpoints.md` §1.)

**Checkpoint:** create data as guest → sign in with a Google account that
already has events → all guest events/expenses now appear under that account,
no duplicates, guest account gone. Repeat with a brand-new Google account →
guest data carried over, account promoted.

---

## Verification

- Fresh install → tap guest → create event, add participants (by name AND
  email), add expense, split, complete, delete. All survive kill-and-relaunch
  (rehydrated from backend via refresh).
- **Claim/merge — existing account:** guest creates events/expenses → signs in
  with a Google/Apple account that ALREADY has events → all guest-owned events,
  expenses, expense items, participants and coverers now appear under that
  account with no duplicates; the guest account is retired.
- **Claim/merge — new account:** guest creates data → signs in with a brand-new
  Google/Apple identity → guest data carries over, account promoted in place.
- **Merge idempotency:** repeating the same guest→provider sign-in does not
  duplicate or split ownership.
- **Guest naming/avatar:** each new guest gets an "Adjective Animal" name and a
  random `ProfileImageEnum` avatar that persists across relaunch/refresh.
- Offline: guest action with no network → existing error dialog (accepted).

## Risks

- **Backend endpoint is the blocker** — client work can't ship without it.
- **Guests now see network-error dialogs.** No reachability layer exists; a
  no-signal guest gets a blocking dialog per failed action. Accepted per
  Non-Goals; flag for UX.
- **Removing the client-side expense-link removal guard** shifts that rule
  entirely to the backend — confirm the backend rejects participant removal when
  tied to an expense (it does for authed today).
- **Merge correctness is the hardest backend piece** — moving ownership of
  events + expenses + items + participants + coverers between accounts, deduping
  against data the target account already has, and staying transactional/
  idempotent. Get the server contract right before client Phase 5. A bad merge
  can duplicate events or strand ownership.
- **Guest-flag tracking:** the `"Guest"` email sentinel is gone, so the client
  needs a reliable "am I a guest?" signal to know when to request a merge —
  prefer a JWT claim over a local boolean so it can't drift.
- **Orphaned guest data** on old installs (pre-upgrade users mid *local* guest
  session): their events are unsynced SwiftData with no server id, so the new
  server-side merge can't see them. The deleted `MigrationCoordinator` is what
  handled this. Decide: keep a one-shot on-upgrade local→server migration, or
  accept loss for in-flight local guest sessions at the upgrade boundary.

## Effort

- Backend: `/auth/guest` (create) **S–M** + claim/merge endpoint **M–L**
  (ownership transfer + dedup + idempotency is the real work). Both gating.
- Client Phases 1–4: **M** (~2–4 focused days), mostly deletion, low-risk,
  incremental with a runnable checkpoint per phase.
- Client Phase 5 (merge handoff): **S** — pass the guest token + provider token,
  then reuse the existing refresh to rehydrate. The weight is on the backend.
- Offline/reachability: **out of scope** (separate M–L project).
