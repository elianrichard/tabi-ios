# Tabi Split — Product Requirements (Snapshot)

> **Audience:** AI coding agents working on this repo.
> **Style:** Snapshot of current state, link-heavy. Not a roadmap. Verify against code before acting on any claim.
> **Last verified:** `main` @ `291023f` (2026-09-09) · marketing version `1.2.0`.
> **Backend:** Go service in sibling repo `tabi-service` (Fiber + GORM + Postgres + Redis + S3). Web fallback pages in `tabi-web`.

## 1. Product Summary

Tabi Split is an iOS bill-splitting app for groups (travel, dinners, shared trips). The core loop is:

1. User creates an **Event** (a shared context with participants) and invites people by contact email, custom name, or a shareable **invite link / QR code**.
2. Participants add **Expenses** — equal split, custom item-level split, or **receipt scan** (on-device OCR refined by a backend AI parser). Receipts can also be shared into Tabi from Photos via the **Share Extension**.
3. The app computes per-user **Balance** (lent − debt) and a **Recap** in two modes — **Simplified** (fewest transfers) and **Detailed** (raw pairwise) — exportable to **PDF**.

**Data ownership is server-first.** Every mutation calls the backend first; local SwiftData is a mirror that Home rebuilds from `GET /event` on every refresh (synced rows are deleted and re-inserted). `localId` / `isSynced` still exist on the models but every write path sets `isSynced: true`; there is **no offline queue and no migration flow** anymore. **Guest mode is a server-backed, credential-less account** (`POST /auth/guest`) that runs the exact same authed code paths and requires connectivity.

- **Bundle id:** `com.sora.TabiSplit` (extension: `com.sora.TabiSplit.ShareExtension`) · **Display name:** Tabi · **Category:** Finance
- **Target:** iOS 18.1+, iPhone-only, portrait, full-screen, status bar hidden, light UI only
- **Build:** XcodeGen ([`project.yml`](project.yml)) — `.xcodeproj` is **not** tracked. Run `xcodegen generate` first.
- **Targets:** `Tabi Split` (app), `ShareExtension` (app extension), `Tabi Split Tests` (unit tests). [`Shared/`](Shared) compiles into both app and extension.
- **Configs / schemes:** `Debug|Release-{Dev,Staging,Production}` fed by [`Config/Dev.xcconfig`](Config/Dev.xcconfig), [`Staging.xcconfig`](Config/Staging.xcconfig), [`Production.xcconfig`](Config/Production.xcconfig). Schemes `Tabi Split (Dev)`, `(Staging)`, `(Production)`. Dev points at a localhost backend (Simulator only).
- **SPM:** Lottie (≥4.5.0), JWTDecode (≥3.2.0), GoogleSignIn-iOS (≥8.0.0)

## 2. Personas & Modes

| Mode                 | Description                                                                                                                                                                                   | Identifier                                                    |
| -------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| Provider account     | Sign in with **Apple** or **Google** (passwordless). Provider `id_token` → backend verifies → app JWT (access + refresh) in Keychain. Email is the identity key.                                | `CurrentUserDefaults.kind == "real"`                          |
| Guest                | `POST /auth/guest` creates a real server account with no credential. Same token + `GET /user` probe path as a provider user. Profile shows **Sign In** instead of Log Out. Requires network.    | `CurrentUserDefaults.kind == "guest"` (`isGuest`)             |
| Guest → provider     | On the next Apple/Google sign-in the guest access token is sent as `merge_from_guest_token`; backend absorbs the guest's events into the provider account.                                     | [`LoginViewModel.guestMergeToken()`](Tabi%20Split/Modules/Login/LoginViewModel.swift) |

**Participant kinds** (server field `kind`, mirrored on [`UserData.kind`](Tabi%20Split/Infrastructure/Model/UserData.swift)): `real` · `dummy` (placeholder added by the owner, no account) · `guest`. `UserData.isLinked` = `real || guest`; linked participants must be unlinked before their details can be edited.

Auth probe runs at launch in [`ContentView.checkAuthentication()`](Tabi%20Split/ContentView.swift): Keychain token + `GET /user`. [`SessionState.isAuthenticated`](Tabi%20Split/Infrastructure/Session/SessionState.swift) drives the root view (Onboarding → Login → Home). Session-expired events broadcast via `Notification.Name.sessionExpired` → banner + `router.popToRoot()`.

## 3. Architecture Snapshot

- **UI pattern:** SwiftUI + MVVM with Swift `@Observable` (Observation framework, **not** Combine).
- **Routing:** [`Router`](Tabi%20Split/Infrastructure/Navigation/Router.swift) (`@Observable`) holds `path: [AppRoute]` (25 cases) for a `NavigationStack` and `sheet: SheetRoute?` (6 cases: `eventComplete`, `eventIncomplete`, `eventDelete`, `eventLeave`, `eventQuickScan`, `eventAllParticipants`). API: `push`, `pop`, `popToRoot`; sheets via [`Sheet+Router.swift`](Tabi%20Split/Infrastructure/Navigation/Sheet+Router.swift) (`present`, `dismissSheet`, `sheetBinding(for:)`). Route → view mapping lives in [`AppRoute+View.swift`](Tabi%20Split/Infrastructure/Navigation/AppRoute+View.swift) (`appNavigationDestinations()`). The root (Onboarding / Login / Home) is swapped by `SessionState.isAuthenticated`, not by a route, so Back can never return to auth screens.
- **Deep links** ([`ContentView.handleIncomingURL`](Tabi%20Split/ContentView.swift)):
  - Universal Link `https://tabisplit.my.id/join?token=<code>` — arrives via `.onContinueUserActivity(NSUserActivityTypeBrowsingWeb)` **and** sometimes `.onOpenURL`; both are wired. Missing the user-activity path = "app opens but nothing happens".
  - Custom scheme `tabisplit://join?token=` (the web `/join` page's "Open in Tabi" button), legacy `tabisplit://join-event?event-id=` (old QR codes), `tabisplit://quickscan` (Share Extension hand-off).
  - `GIDSignIn.sharedInstance.handle(url)` gets first refusal on every `.onOpenURL` (Google OAuth callback).
  - Tokens / shared receipts that arrive before auth is ready are queued (`pendingInviteToken`, `pendingSharedReceipt`) and drained on `isAuthenticated`.
- **DI / app state:** environment-injected in [`ContentView`](Tabi%20Split/ContentView.swift): `Router`, `EventViewModel`, `EventInviteViewModel`, `EventExpenseViewModel`, `EventSettlementViewModel`, `ProfileViewModel`, `LoadingViewModel.shared`. Singletons:
  - [`APIService.shared`](Tabi%20Split/Infrastructure/Networking/APIService.swift) — REST client (JSON + multipart)
  - [`KeychainService.shared`](Tabi%20Split/Infrastructure/Keychain) — access/refresh tokens, service = bundle id
  - [`SwiftDataService.shared`](Tabi%20Split/Infrastructure/SwiftData) — local mirror (events / expenses / users)
  - [`UserDefaultsService.shared`](Tabi%20Split/Infrastructure/UserDefault) — current user, onboarding flag, scan-disclaimer flag, rating cadence
  - [`SessionState.shared`](Tabi%20Split/Infrastructure/Session/SessionState.swift) — `isAuthenticated`, `sessionExpiredBanner`
  - [`ToastViewModel.shared`](Tabi%20Split/Modules/Components/ViewModel/ToastViewModel.swift) / [`ErrorDialogViewModel.shared`](Tabi%20Split/Modules/Components/ViewModel/ErrorDialogViewModel.swift) — global toast + error dialog overlays
  - [`RatingPromptManager.shared`](Tabi%20Split/Infrastructure/Review/RatingPromptManager.swift) — decides when to fire the native `requestReview`
  - [`BackupService.shared`](Tabi%20Split/Infrastructure/SwiftData/BackupService.swift), [`ImageService.shared`](Tabi%20Split/Infrastructure/Services/Image/ImageService.swift), [`ReceiptParseService.shared`](Tabi%20Split/Infrastructure/Services/Receipt/ReceiptParseService.swift)
- **Global overlays** (ContentView `ZStack`): `LoadingView`, `ToastOverlay`, `ErrorDialogOverlay`, `SplashView`.
- **SwiftData container:** schema `[NoteData, EventData, UserData]` defined once in [`TabiSchema`](Tabi%20Split/Infrastructure/SwiftData/TabiSchema.swift); `SwiftDataService.shared` opens the single on-disk container via `TabiSchema.loadOrRecover()` (failed open → store moved to `Application Support/Recovery/`, fresh store, toast on Home; never `fatalError`) and [`TabiApp`](Tabi%20Split/TabiApp.swift) injects that same container. Schema rules + fixture tests: [ADR-0001](../adr/0001-swiftdata-schema-migration.md).
- **Networking:** every request carries `Content-Type: application/json` + `<ENV.API_SECRET_HEADER>: <ENV.API_SECRET_KEY>` + `Authorization: Bearer <token>` when present. On `401` it calls `POST /auth/refresh` once and retries; a `401` **on the refresh endpoint itself** posts `.sessionExpired` without recursing. Concurrent refreshes are de-duplicated (`isRefreshing` + queue). Any non-401 failure is auto-surfaced in the global error dialog by `notifyError`; task/URL cancellations are swallowed. Logging is `os_log` (no `print` in `APIService`).
- **Errors:** [`APIError`](Tabi%20Split/Infrastructure/Networking/APIError.swift) (`invalidResponse`, `refreshFailed`, `unauthorized`, `requestFailed(message)`, `tokenMissing`, `internalServerError(message)`) plus domain errors `EventAPIError`, `ExpenseAPIError`, `ProfileAPIError`, [`ProviderSignInError`](Tabi%20Split/Infrastructure/Services/Auth/ProviderSignIn.swift).

## 4. Feature Map

| Module                  | Purpose                                                                                                                                                               | Path                                                                                                                                                  |
| ----------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| Onboarding              | 4-slide intro carousel; sets onboarding flag; routes to Login                                                                                                         | [`Modules/Onboarding`](Tabi%20Split/Modules/Onboarding)                                                                                               |
| Login                   | **Continue with Apple / Google**, **Enter as Guest**; session-expired banner                                                                                          | [`Modules/Login`](Tabi%20Split/Modules/Login)                                                                                                         |
| Register                | Same provider buttons (register == login); links back to Login                                                                                                        | [`Modules/Register`](Tabi%20Split/Modules/Register)                                                                                                   |
| Home                    | Event list + filters (All / You Owe / Owes You / Settled); profile + inbox entry; `refreshEventData` rebuilds the local mirror                                        | [`Modules/Home`](Tabi%20Split/Modules/Home)                                                                                                           |
| Event Form              | Create/edit event: name, icon; participants list with "All Participants (n)" sheet                                                                                    | [`Modules/Event/EventForm`](Tabi%20Split/Modules/Event/EventForm)                                                                                     |
| Event Invite            | Contacts (email-keyed, `CNContactEmailAddressesKey`), **Invite by Email**, **Add Custom Participant**; Copy / Share / QR invite link via `InviteShareButtons`         | [`EventForm/EventInvite`](Tabi%20Split/Modules/Event/EventForm/EventInvite)                                                                           |
| Edit Participant        | Rename / avatar, link to account by email, **claim link** (single-use) with live claim polling, **Unlink**, **Remove**                                                | [`EventForm/EditParticipant`](Tabi%20Split/Modules/Event/EventForm/EditParticipant)                                                                   |
| Event Detail            | Expenses / Summary tabs; **Add Manually** + **Quick Scan** CTAs; Complete / Incomplete / Delete / **Leave** sheets                                                    | [`Modules/Event/EventDetail`](Tabi%20Split/Modules/Event/EventDetail)                                                                                 |
| Event Expense           | Add/edit expense, equal or custom split, receipt attach, on-device OCR + AI refine, item entry, item assignment (participant picker + All/Assigned/Unassigned filters), result with **See Receipt** | [`Modules/Event/EventExpense`](Tabi%20Split/Modules/Event/EventExpense)                                                                               |
| Receipt Upload / Scan   | `ReceiptUploadSheet` (Take Photo via VisionKit `DocumentScannerView`, Open Library), `ReceiptScanDisclaimerSheet`, `ReceiptImageReviewView`, `ReceiptViewerView` (pinch-zoom) | [`EventExpense/ReceiptUpload`](Tabi%20Split/Modules/Event/EventExpense/ReceiptUpload), [`Components/DocumentScannerView.swift`](Tabi%20Split/Modules/Components/DocumentScannerView.swift) |
| Quick Scan (shared)     | Event picker for a receipt shared in from the Share Extension                                                                                                        | [`EventExpense/QuickScan`](Tabi%20Split/Modules/Event/EventExpense/QuickScan)                                                                         |
| Event Summary           | Balance card, total spending, transaction history (tap → expense result), "See Optimization Details"                                                                  | [`EventDetail/EventSummary`](Tabi%20Split/Modules/Event/EventDetail/EventSummary)                                                                     |
| Settlement Optimization | Per-person lent/debt/balance, recap with **Simplified / Detailed** toggle, **Export PDF**                                                                             | [`EventSummary/EventSettlement/SettlementOptimization`](Tabi%20Split/Modules/Event/EventDetail/EventSummary/EventSettlement/SettlementOptimization)     |
| Settlement (payment)    | Payment method, receipt upload, confirmation — **code present but disabled**; Summary routes to optimization instead                                                  | [`EventSummary/EventSettlement`](Tabi%20Split/Modules/Event/EventDetail/EventSummary/EventSettlement)                                                 |
| Profile                 | Edit profile, payment methods, **Export Data / Import Data** (JSON backup), Log Out (provider) or Sign In (guest)                                                     | [`Modules/Home/Profile`](Tabi%20Split/Modules/Home/Profile)                                                                                           |
| Inbox                   | UI scaffold only; `inboxList` is empty (mock rows commented out)                                                                                                      | [`Modules/Home/Inbox`](Tabi%20Split/Modules/Home/Inbox)                                                                                               |
| Share Extension         | Accepts exactly 1 image from the system share sheet, writes JPEG to the App Group, opens `tabisplit://quickscan`                                                     | [`ShareExtension/`](ShareExtension), [`Shared/AppGroup.swift`](Shared/AppGroup.swift)                                                                 |
| Rating prompt           | Native App Store prompt after 3 saved expenses; 60-day cooldown; max 3 lifetime asks. No custom star UI.                                                             | [`Infrastructure/Review`](Tabi%20Split/Infrastructure/Review)                                                                                         |
| Backup                  | Export/import the SwiftData store as versioned JSON (`BackupPayload` v1)                                                                                             | [`Infrastructure/SwiftData/BackupService.swift`](Tabi%20Split/Infrastructure/SwiftData/BackupService.swift)                                           |
| PDF export              | `UIGraphicsPDFRenderer` A4 export of the optimization (people + simplified + detailed recap + item breakdown)                                                        | [`Utils/SettlementOptimizationPDFExporter.swift`](Tabi%20Split/Utils/SettlementOptimizationPDFExporter.swift)                                         |

Top-level Home view model: [`HomeViewModel`](Tabi%20Split/Modules/Home/HomeViewModel.swift). Shared event view model used across event flows: [`EventViewModel`](Tabi%20Split/Modules/Event/EventViewModel.swift). Shared expense view model (incl. OCR pipeline): [`EventExpenseViewModel`](Tabi%20Split/Modules/Event/EventExpense/EventExpenseViewModel.swift).

## 5. User Flows

**5.1 First launch**

1. `TabiApp` boots the SwiftData container.
2. If the onboarding flag is unset → `OnboardingView` (sets the flag on appear).
3. `ContentView.checkAuthentication()`: no token and no local user → `LoginView`; local user but no token → `LoginView` with the session-expired banner; token → `GET /user` probe → `HomeView`. Guests take the same path (no bypass).
4. Any queued invite token / shared receipt is drained once authenticated.

**5.2 Sign in**

1. Apple (`AuthenticationServices`) or Google (`GoogleSignIn` SDK) via [`ProviderSignIn`](Tabi%20Split/Infrastructure/Services/Auth/ProviderSignIn.swift) → `ProviderCredential(idToken, name, email)`.
2. `POST /auth/apple` or `/auth/google` with `id_token` (+ `merge_from_guest_token` if the current session is a guest) → `LoginResponse(token, refresh_token, full_name, email, profile_image)`.
3. `userId` is read from the JWT (`JWTDecode`); tokens go to Keychain; `CurrentUserDefaults` (UserDefaults) and the SwiftData current user are saved; `SessionState.isAuthenticated = true`.
4. Guest: `POST /auth/guest` → same persistence with `kind: "guest"`. Cancelling the provider sheet is not surfaced as an error.
5. Token lifetimes: access token 24h, renewed by `POST /auth/refresh` on a 401. Provider refresh tokens last 7 days (then the session-expired banner; sign in again). **Guest refresh tokens never expire** — a guest has no credentials to sign back in with — and are revoked only by logout, account deletion, or the guest → provider merge. A guest still holding a legacy 7-day token gets it rotated on its first refresh (`RefreshResponse.refresh_token`), which `AuthService.refresh()` stores in place.
6. Each fresh session resets the receipt-scan disclaimer so it shows again once.

**5.3 Create event → invite participants**

1. Home → `+` → `EventFormView`: name, icon (`EventIconEnum`) → `POST /event` → `EventData(isSynced: true)` with the creator as first participant.
2. Add Participants → `EventInviteView`: contacts are read with email keys; `POST /user/check` (emails) resolves registered users → sent as real participants; the rest go as `dummy_names` via `PATCH /event/{id}`. "Invite by Email" / "Add Custom Participant" add ad-hoc rows (duplicate-email guard).
3. Share invite: `POST /event/{id}/invite-token` → `https://tabisplit.my.id/join?token=<code>` shown as Copy Link / Share (system sheet, message "Join "<event>" on Tabi…") / QR (`CIFilter.qrCodeGenerator`). The QR **must** encode the https form (Camera won't reliably open custom schemes). Token is short-lived (1 h) and multi-use.

**5.4 Join via link / QR**

1. Tap → app opens (Universal Link) → `handleIncomingURL` → `handleInviteToken` (queued if not yet authenticated) → `POST /event/join-by-token/{token}` → refresh events → push `.eventDetail`.
2. Backend errors ("User already joined event", "Invite link expired or invalid", `400` not `401`) are shown by the global error dialog; the app lands on Home.
3. App not installed → the web `/join` page (tabi-web) offers App Store + "Open in Tabi" (`tabisplit://join?token=`). Invite context is dropped after install (v1).

**5.5 Claim a placeholder participant**

1. Owner opens a dummy participant → `EditParticipantView` → "Or invite them to claim this participant" → `POST /event/{id}/participant/{pid}/invite-token` (only for dummies with no email) → Copy / Share / QR.
2. After any share action the view polls `GET /event/{id}/participant/{pid}/status` every ~5 s ("Waiting for someone to open the link…").
3. The joiner taps the link → same `join-by-token` entry; backend swaps the dummy for the joiner (all expense refs move, dummy row deleted, token consumed) → owner's poll sees the linked participant.
4. Alternative: owner types an email into the participant → `PATCH /event/{id}/participant/{pid}` links to that registered account. **Unlink** reverts a linked participant to a placeholder; **Remove** → `DELETE /event/{id}/participant/{pid}`.

**5.6 Add expense — manual and scan**

1. Event Detail → **Add Manually** → `AddExpenseView`: name, Paid By, participants (`SelectParticipantsSheet` with Select All), split method (`equally` / `custom`), total, optional receipt image (`ReceiptUploadSheet`).
2. **Next** with custom split + image: `runOCRIfNeeded()` (Vision `VNRecognizeTextRequest` + row/price heuristics → `ReceiptDraft`) → `refineReceiptWithAI()` (`POST /receipt/parse`, gated by `ENV.RECEIPT_AI_REFINE_ENABLED`) → `ExpenseAddItemsView` (banner: "These items were read from your receipt…") → `ExpenseAssignView` (pinned participant picker, tap items, All / Assigned / Unassigned filter, "Some items aren't assigned" guard) → `ExpenseResultView` → Save.
3. Save: `uploadReceiptIfNeeded()` (`POST /upload`, folder `receipt`) → `POST /expense/{eventId}` (or `PATCH /expense/{id}` on edit) with `receipt_url` → local mirror updated → `RatingPromptManager.registerSuccessfulExpense()`.
4. **Quick Scan** (Event Detail CTA): sheet `.eventQuickScan` → `ReceiptUploadSheet` in scan mode → disclaimer (skippable with "Do not show again") → **Take Photo** (VisionKit document camera, single page) or **Open Library** → `ReceiptImageReviewView` → OCR → `AddExpenseView` with `isQuickScanned = true`.
5. **Share Extension**: Photos / any app → share → "Tabi" → [`ShareViewController`](ShareExtension/ShareViewController.swift) writes `shared-receipt.jpg` into App Group `group.com.sora.TabiSplit` → opens `tabisplit://quickscan` → `handleQuickScan` (queued if unauthenticated) → `QuickScanEventPickerView` → attaches image → `.eventDetail` + `.addExpense`.
6. Saved expenses show **See Receipt** → `ReceiptViewerView` fetches a fresh signed URL via `GET /image/{id}`.

**5.7 Recap / optimization**

1. Summary tab → "See Optimization Details" (or, for the creator, "Complete and See Optimization" → `.eventComplete` sheet → `POST /event/complete/{id}`).
2. [`EventViewModel.calculateOptimization`](Tabi%20Split/Modules/Event/EventViewModel.swift) builds `participantsBalance` (greedy debtor/creditor netting → **Simplified**) and `directSettlements` (raw pairwise **Detailed**), plus the current user's history and total spending.
3. `SettlementOptimizationView`: `RecapModeToggle` switches modes; share icon → `SettlementOptimizationPDFExporter.generatePDF` → `ShareSheet`.
4. Complete / incomplete both `POST /event/complete/{id}` with a flag; completed events lock expense edits. The payment settlement flow (`.eventSettlement` and children) is **disabled** — Summary pushes `.settlementOptimization` instead.

**5.8 Leave / delete event**

- Creator: **Delete Event** → `DELETE /event/{id}`. Creator cannot leave.
- Non-creator: **Leave Event** → `POST /event/leave/{id}`; backend replaces them with a placeholder dummy carrying their name so history stays intact.

**5.9 Backup**

- Profile → **Export Data** → `BackupService.exportToTemporaryFile()` (JSON, `BackupPayload.version = 1`) → `ShareSheet`.
- **Import Data** → `.fileImporter` → `BackupService.importFromFile(url:)` → writes into local SwiftData only (no API calls). See §9 for the interaction with server-first refresh.

**5.10 Session expiration / logout**

1. Any API call returning `401` → `APIService` refreshes once; on failure (or `401` from `/auth/refresh`) posts `.sessionExpired`.
2. `ContentView.handleSessionExpired()` → banner on, `isAuthenticated = false`, `router.popToRoot()` → Login shows "Your session expired. Sign in to sync your local data."
3. **Log Out** (`ProfileViewModel.logout`) clears tokens (local only — there is no `/auth/logout` call) and wipes all local events, expenses, users and `CurrentUserDefaults`.

## 6. Data Model

SwiftData `@Model` classes under [`Tabi Split/Infrastructure/Model/`](Tabi%20Split/Infrastructure/Model). Naming caveat: the expense model is **`Expense`** (file [`ExpenseData.swift`](Tabi%20Split/Infrastructure/Model/ExpenseData.swift)).

| Model              | Key fields                                                                                                                                                 | Relationships                                                                                                                        |
| ------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| `EventData`        | `eventId?`, `eventName`, `eventIcon`, `completionDate?`, `userEventBalance`, `createdAt`, `creatorId`, `localId`, `isSynced`                               | `participants: [UserData]`, `expenses: [Expense]` (.nullify)                                                                         |
| `UserData`         | `userId`, `name`, **`email`**, **`kind`** (`real`/`dummy`/`guest`), `image` (avatar id), `imageUrl?`; helpers `isLinked`, `isSameUser(as:)`                | `events`, `expenses`, `coveredExpenses`, `expenseShare`                                                                              |
| `Expense`          | `expenseId?`, `name`, `dateOfCreation`, `price`, `splitMethod` (`equally`/`custom`), **`creator?`**, **`receiptId?`**, `localId`, `isSynced`               | `event?`, `coverer: UserData`, `participants`, `items: [ExpenseItem]` (.cascade), `additionalCharges: [AdditionalCharge]` (.cascade) |
| `ExpenseItem`      | `itemId?`, `itemName`, `itemPrice`, `itemQuantity`, `localId`                                                                                              | `assignees: [ExpensePerson]`, `expense?`                                                                                             |
| `ExpensePerson`    | `share`                                                                                                                                                    | `user: UserData`, `expenseItem?`                                                                                                     |
| `AdditionalCharge` | `additionalChargeId?`, `additionalChargeType` (`tax`/`service`/`discount`/`other`), `amount`                                                               | `expense?`                                                                                                                           |
| `InboxData`        | inbox row (unused — list is empty)                                                                                                                        | see [`InboxData.swift`](Tabi%20Split/Infrastructure/Model/InboxData.swift)                                                           |
| `NoteData`         | scratch notes                                                                                                                                              | (in container schema)                                                                                                                |

Non-persisted view/domain types in [`SettlementData.swift`](Tabi%20Split/Infrastructure/Model/SettlementData.swift): `PersonBalanceData` (lent / debt / balance / status / settlement list), `PersonSettlementData`, `SummaryHistoryData` (+ `expense?` for tap-through), `SummarySettlementData`, `SettlementCardTypeEnum`.

Current user lives in **UserDefaults** as [`CurrentUserDefaults`](Tabi%20Split/Infrastructure/UserDefault/CurrentUserDefaults.swift) (`userName`, `userEmail`, `userImage`, `userId`, `kind`) and is mirrored as a `UserData` row for relationships.

**Avatars** are template ids only: `owl`, `dragon`, `wallet`, `octopus` (`ProfileImageEnum`). Anything else in `avatar_url` is treated as a legacy remote URL.

**Sync note:** `localId` / `isSynced` are vestigial. `refreshEventData` deletes every `isSynced == true` event and re-inserts from the server; nothing in the app currently creates `isSynced == false` rows.

## 7. API Contract

**Base URL:** per scheme, from the xcconfig → Info.plist `BASE_URL` → [`ENV.BASE_API_URL`](Tabi%20Split/Constants/ENV.swift). Missing value = `fatalError` at launch.
**Headers:** `<ENV.API_SECRET_HEADER>: <ENV.API_SECRET_KEY>` (both from xcconfig), `Authorization: Bearer <token>` (when present), `Content-Type: application/json` or `multipart/form-data`.
**Auth retry:** `401` → `POST /auth/refresh` → retry once → on failure, post `.sessionExpired`.

| Method | Path                                             | Purpose                                                              | Service                                                                                        |
| ------ | ------------------------------------------------ | -------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| POST   | `/auth/guest`                                    | Create credential-less guest session                                 | [`AuthService`](Tabi%20Split/Infrastructure/Services/Auth/AuthService.swift)                   |
| POST   | `/auth/google`                                   | Exchange Google `id_token` (+ optional `merge_from_guest_token`)     | `AuthService`                                                                                  |
| POST   | `/auth/apple`                                    | Exchange Apple `id_token` (+ optional `merge_from_guest_token`)      | `AuthService`                                                                                  |
| POST   | `/auth/refresh`                                  | Refresh access token                                                 | `AuthService` / `APIService`                                                                   |
| POST   | `/event`                                         | Create event                                                         | [`EventService`](Tabi%20Split/Infrastructure/Services/Event/EventService.swift)                |
| GET    | `/event`                                         | List user's events (with participants + expenses)                    | `EventService`                                                                                 |
| PATCH  | `/event/{id}`                                    | Edit event (name, icon, participants, `dummy_names`)                 | `EventService`                                                                                 |
| DELETE | `/event/{id}`                                    | Delete event (creator)                                               | `EventService`                                                                                 |
| POST   | `/event/complete/{id}`                           | Mark complete **or** incomplete (flag in body)                       | `EventService`                                                                                 |
| POST   | `/event/join/{id}`                               | Legacy join by raw event id (`tabisplit://join-event`)               | `EventService`                                                                                 |
| POST   | `/event/leave/{id}`                              | Leave event (non-creator → placeholder dummy)                        | `EventService`                                                                                 |
| POST   | `/event/join-by-token/{token}`                   | Redeem event-join **or** participant-claim token; returns `event_id` | `EventService`                                                                                 |
| POST   | `/event/{id}/invite-token`                       | Mint 1 h multi-use event-join token                                  | `EventService`                                                                                 |
| POST   | `/event/{id}/participant/{pid}/invite-token`     | Mint single-use claim token for an email-less dummy                  | `EventService`                                                                                 |
| GET    | `/event/{id}/participant/{pid}/status`           | Poll whether the dummy has been claimed                              | `EventService`                                                                                 |
| PATCH  | `/event/{id}/participant/{pid}`                  | Edit participant (name, avatar, optional email → link)               | `EventService`                                                                                 |
| DELETE | `/event/{id}/participant/{pid}`                  | Remove participant                                                   | `EventService`                                                                                 |
| POST   | `/expense/{eventId}`                             | Add expense (items, assignees, charges, `receipt_url`)               | [`ExpenseService`](Tabi%20Split/Infrastructure/Services/Expense/ExpenseService.swift)          |
| PATCH  | `/expense/{id}`                                  | Update expense                                                       | `ExpenseService`                                                                               |
| DELETE | `/expense/{id}`                                  | Delete expense                                                       | `ExpenseService`                                                                               |
| GET    | `/user`                                          | Current user (also the launch session probe)                         | [`ProfileService`](Tabi%20Split/Infrastructure/Services/Profile/ProfileService.swift)          |
| PATCH  | `/user`                                          | Update profile (`name`, `avatar_url`)                                | `ProfileService`                                                                               |
| DELETE | `/user`                                          | Delete account                                                       | `ProfileService`                                                                               |
| POST   | `/user/check`                                    | Resolve registered users by **email** (for invites)                  | `ProfileService`                                                                               |
| POST   | `/upload`                                        | Multipart image upload (`folder`, e.g. `receipt`) → image id         | [`ImageService`](Tabi%20Split/Infrastructure/Services/Image/ImageService.swift)                |
| GET    | `/image/{id}`                                    | Fresh signed URL for a stored image                                  | `ImageService`                                                                                 |
| POST   | `/receipt/parse`                                 | Refine OCR lines + heuristic draft into a structured receipt (LLM)   | [`ReceiptParseService`](Tabi%20Split/Infrastructure/Services/Receipt/ReceiptParseService.swift) |

Removed since 1.1.5: `/auth/register`, `/auth/login`, `/migrate` (and `MigrateService` / `MigrationCoordinator`).

Wire format uses `snake_case`. Response decoding lands directly into domain types via custom initializers (e.g. `UserData(userBase:)`); there is **no separate DTO/mapper layer** — keep snake/camel conversions in the schema files next to each service. Invite tokens are opaque short codes (backend Redis, 1 h TTL) — not JWTs; the client never inspects them.

## 8. Key Constants & Config

- [`ENV.swift`](Tabi%20Split/Constants/ENV.swift) — `BASE_API_URL`, `API_SECRET_KEY`, `API_SECRET_HEADER` read from Info.plist (filled by the active xcconfig); `APP_BUNDLE_ID`; `DEEPLINK_HOST = "tabisplit.my.id"`, `DEEPLINK_SCHEME = "tabisplit"` (fixed across configs — must match entitlements + `CFBundleURLSchemes`); feature flag `RECEIPT_AI_REFINE_ENABLED`.
- [`Config/*.xcconfig`](Config) — `API_SCHEME`, `API_HOST`, `BASE_URL`, `API_SECRET_KEY`, `API_SECRET_HEADER`, `CODE_SIGN_ENTITLEMENTS`, `SWIFT_ACTIVE_COMPILATION_CONDITIONS` (`DEV` / `STAGING`). **Secret values are committed** in these files. Dev expects the backend to run with `APP_ENV=development` (secret check bypassed).
- [`Info.plist`](Tabi%20Split/Info.plist) — URL schemes `tabisplit` + Google reversed client id; `GIDClientID`; `NSCameraUsageDescription` (receipt scan), `NSContactsUsageDescription` (invites); `NSAllowsLocalNetworking` (Dev localhost); `UIUserInterfaceStyle = Light`; Figtree fonts.
- [`Tabi Split.entitlements`](Tabi%20Split/Tabi%20Split.entitlements) — Sign in with Apple, `applinks:tabisplit.my.id`, App Group `group.com.sora.TabiSplit`. [`ShareExtension.entitlements`](ShareExtension/ShareExtension.entitlements) — same App Group. Extension activation: `NSExtensionActivationSupportsImageWithMaxCount = 1`.
- **Universal Links prerequisite:** AASA must be served at `https://tabisplit.my.id/.well-known/apple-app-site-association` with HTTP 200, `application/json`, **no redirect** (apex must be the primary domain in Vercel). iOS caches AASA per install — reinstall after changes.
- [`UIConfig.swift`](Tabi%20Split/Constants/UIConfig.swift) — color/spacing tokens. New color sets `buttonYellow` / `highlightYellow` back the expense tag `Nugget`s.
- UserDefaults keys ([`UserDefaultKeys`](Tabi%20Split/Infrastructure/UserDefault/UserDefaultsService.swift)): `currentUserDetails`, `onboardingStatus`, `receiptScanDisclaimerDismissed`, `ratingSuccessfulExpenseCount`, `ratingLastRequestedAt`, `ratingRequestCount`.
- Tests ([`Tabi Split Tests`](Tabi%20Split%20Tests)): `RatingPromptManagerTests`, `SettlementOptimizationPDFExporterTests`; `TabiSplitTests.swift` is the Xcode template.
- Build: `xcodegen generate` → `xcodebuild -scheme "Tabi Split (Dev)" …`. Single-file SourceKit "Cannot find type X in scope" diagnostics are usually cross-file noise, not real errors.

## 9. Open Questions / TODOs

- **Settlement payment flow disabled.** `EventSummaryView` routes to `.settlementOptimization`; `.eventSettlement` and its children (`SettlementPaymentMethodView`, `SettlementUploadView`, `SettlementConfirmationView`, `SettlementReceiptView`, `EventSettlementViewModel`) are reachable only via dead code. Decide: revive, or remove routes + views.
- **Inbox.** UI-only; `InboxViewModel.inboxList` is empty. No notifications backend. The reminder promise in onboarding copy ("Only one tap to remind your friends…") has no implementation.
- **Vestigial sync flags.** `localId` / `isSynced` survive on `EventData` / `Expense` / `ExpenseItem` but nothing writes `false`. Either drop them or re-introduce a real offline story (there is still **no reachability layer**).
- **Backup import vs server-first refresh.** `BackupService.importFromFile` writes local rows only; the next `refreshEventData` deletes every `isSynced == true` event and re-inserts from the server. Confirm what imported data is expected to survive and whether import should push to the backend.
- **Guest recovery.** A guest has no credential; deleting the app (or losing the Keychain token) orphans the account. Only "Sign In" (merge) rescues it. Consider surfacing this in UI.
- **Invite fallback after install.** Universal Link → App Store → fresh install drops the token (v1 decision). Deferred deep-linking not implemented.
- **Secrets in xcconfig.** `API_SECRET_KEY` values are committed for all three configs. If rotated, rotate here and in `tabi-service` together.
- **Plan docs partly superseded.** [`docs/prd/invite-hotlinks.md`](docs/prd/invite-hotlinks.md) describes signed-JWT tokens; the shipped backend uses opaque Redis codes with the same 1 h TTL. [`docs/plans/guest-server-backed-account.md`](docs/plans/guest-server-backed-account.md) is implemented.
- **Domain docs referenced but absent.** [`CLAUDE.md`](CLAUDE.md) → `docs/agents/domain.md` expects `CONTEXT.md` + `docs/adr/`; neither exists yet (created lazily by `/grill-with-docs`).
- **Developer leftovers.** [`SwiftDataTestingView`](Tabi%20Split/Modules/Home/SwiftDataTestingView.swift) + `AppRoute.swiftDataTesting`, `NoteData` in the container schema, `TabiSplitTests.swift` template.
- **Profile image upload.** `UserData.imageUrl` remains for legacy remote avatars; `PATCH /user` only accepts one of the four template ids. No upload pipeline for custom avatars.
- **Version numbers.** `project.yml` sets `CURRENT_PROJECT_VERSION: 1`; build numbers are managed outside the repo (Xcode Cloud / local `.xcodeproj`). Marketing versions **must** be bumped in `project.yml` and tagged (`v<version>`): 1.1.6–1.1.8 were never recorded in git, which made the 1.2.0 migration crash hard to reconstruct.
- **SwiftData follow-ups (all must pass `StoreMigrationTests`).** `Expense.creator` has no inverse (deleting a `UserData` leaves a dangling to-one); non-optional to-one `Expense.coverer` / `ExpensePerson.user` become nil when a user row is deleted → guard deletes or make optional; remove `NoteData`/`Author`/`SubNote` + `SwiftDataTestingView` from the schema via an explicit stage.

## 10. Release checklist

1. Bump `MARKETING_VERSION` in `project.yml` (all targets) and commit.
2. Generate the store fixture for this version and commit it: `Tabi Split Tests/Fixtures/README.md`.
3. `StoreMigrationTests` green (opens every previous fixture with the current schema).
4. Production secret present: local `Config/Secrets.xcconfig` (from `Secrets.xcconfig.example`) or the Xcode Cloud secret `PROD_API_SECRET_KEY`; the "Check required build settings" phase fails the archive otherwise.
5. Install the TestFlight build **over** the current App Store build on a device: app launches, Home balances correct, Profile shows the right email.
6. Tag the archived commit `v<version>`.

## 11. Glossary

- **Event** — shared context with participants, an icon, and a list of expenses. Persisted as `EventData`. Has a **creator** (owner) who alone can complete / delete it.
- **Participant** — `UserData` linked to an event. **Kind** is `real` (provider account), `guest` (credential-less account) or `dummy` (placeholder created by the owner). `real` and `guest` are **linked**.
- **Linked / Unlinked** — whether a participant row is backed by an account. Linked rows are read-only until **Unlink** turns them back into a placeholder.
- **Coverer** — the participant who actually paid for an expense (the lender). **Creator** (on `Expense`) — who entered it.
- **Expense** — a single charge inside an event. Has `splitMethod` (`equally` or `custom`), a coverer, items, additional charges, and an optional attached **receipt** (`receiptId`).
- **Item** — line in a receipt-style expense (`ExpenseItem`). Each item can be assigned to a subset of participants with per-person **share**.
- **Additional Charge** — tax / service / discount / other on top of items (`AdditionalCharge`).
- **Split Method** — `equally` (price ÷ participants) or `custom` (per-item assignment).
- **Quick Scan** — receipt-first expense entry: VisionKit document camera or Photos → on-device OCR → optional backend AI refine → pre-filled items. Also the name of the Share-Extension hand-off (`tabisplit://quickscan`).
- **OCR draft / AI refine** — the heuristic `ReceiptDraft` built from Vision text observations, and its refinement via `POST /receipt/parse`.
- **Balance** — `lent − debt` per user. Surfaced as You Owe / Owes You / Settled.
- **Recap (Optimization)** — the who-pays-whom plan. **Simplified** = greedy netting for fewest transfers (`participantsBalance`); **Detailed** = raw pairwise debts (`directSettlements`). Exportable as PDF.
- **Settlement** — a transfer from debtor to creditor (`PersonSettlementData`). The payment/confirmation UI for settlements is currently disabled.
- **Invite token (event-join)** — opaque 1 h, multi-use code minted by `POST /event/{id}/invite-token`; delivered as `https://tabisplit.my.id/join?token=`.
- **Claim token (participant-claim)** — opaque 1 h, single-use code for one email-less dummy; redeeming it swaps the dummy for the joiner.
- **Universal Link** — the https invite URL handled by the app via the `applinks:` entitlement + AASA. **Custom scheme** — `tabisplit://…`, used by the web fallback page and the Share Extension.
- **Guest mode** — server-backed, credential-less account (`kind == "guest"`); merged into a provider account on the next Apple/Google sign-in via `merge_from_guest_token`.
- **Backup** — JSON export/import of the local SwiftData store (`BackupPayload` v1) from Profile.
- **App Group** — `group.com.sora.TabiSplit`; shared container the Share Extension uses to pass a receipt image to the app.
- **Session expired** — broadcast via `Notification.Name.sessionExpired` after a refresh failure; root swaps to Login with a banner.
- **Probe session** — `ProfileService.probeSession()` (`GET /user`); called at launch to validate the stored token.
- **Rating prompt** — Apple's native `requestReview`, asked after the 3rd saved expense, at most every 60 days and 3 times ever.
