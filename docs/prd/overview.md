# Tabi Split — Product Requirements (Snapshot)

> **Audience:** AI coding agents working on this repo.
> **Style:** Snapshot of current state, link-heavy. Not a roadmap. Verify against code before acting on any claim.
> **Last verified branch:** `feat/v2.1` · marketing version `1.1.5`.

## 1. Product Summary

Tabi Split is an iOS bill-splitting app for groups (travel, dinners, shared trips). The core loop is:

1. User creates an **Event** (a shared context with participants).
2. Each participant adds **Expenses** to the event — equal split, custom item-level split, or receipt-OCR import.
3. The app computes per-user **Balance** (lent − debt), produces an **Optimization** (fewest transfers), and lets users mark **Settlements** as paid.

The app is **offline-first**: every event/expense is written to local SwiftData immediately with `localId` + `isSynced` flags, then reconciled with the backend. Unauthenticated **Guest mode** lets users build events offline and bulk-uploads them via `/migrate` after sign-in.

- **Bundle id:** `com.sora.Tabi` · **Display name:** Tabi · **Category:** Finance
- **Target:** iOS 18.0, iPhone-only, portrait, full-screen, status bar hidden
- **Build:** XcodeGen (`project.yml`) — no `.xcodeproj` checked in
- **SPM:** Lottie (≥4.5.0), JWTDecode (≥3.2.0)

## 2. Personas & Modes

| Mode | Description | Identifier |
|------|-------------|------------|
| Authenticated | Phone + password account, JWT in Keychain, syncs with backend | `UserData.phone != "Guest"` |
| Guest | No account, fully offline; events stored locally; converts on login via `/migrate` | `UserData.phone == "Guest"` |

Auth probe runs at launch in [`ContentView.checkAuthentication()`](Tabi%20Split/ContentView.swift). Session-expired events broadcast via `Notification.Name.sessionExpired` and the global [`SessionState`](Tabi%20Split/Infrastructure/Session/SessionState.swift).

## 3. Architecture Snapshot

- **UI pattern:** SwiftUI + MVVM with Swift `@Observable` (Observation framework, **not** Combine).
- **Routing:** [`AppRouter`](Tabi%20Split/Infrastructure/Navigation/Routes.swift) (an `@Observable` class) drives a `NavigationStack` keyed on the `AppRoute` enum (~30 cases). Methods: `push`, `pop`, `popToRoot`, `replaceStack`, `navigate`. Deep link scheme `tabisplit://join-event?event-id=…`.
- **DI / app state:** shared singletons + environment-injected view models in [`ContentView`](Tabi%20Split/ContentView.swift).
  - [`APIService.shared`](Tabi%20Split/Infrastructure/Networking/APIService.swift) — REST client
  - [`KeychainService.shared`](Tabi%20Split/Infrastructure/Keychain) — token storage
  - [`SwiftDataService.shared`](Tabi%20Split/Infrastructure/SwiftData) — local DB wrapper
  - [`UserDefaultsService.shared`](Tabi%20Split/Infrastructure/UserDefault) — prefs / current user / onboarding flag
  - [`SessionState.shared`](Tabi%20Split/Infrastructure/Session/SessionState.swift) — transient banners, last migration error
- **SwiftData container:** schema `[NoteData, EventData, UserData]` initialized in [`TabiApp`](Tabi%20Split/TabiApp.swift) (persistent, on disk).
- **Networking:** [`APIService`](Tabi%20Split/Infrastructure/Networking/APIService.swift) sets `Content-Type: application/json` + `X-Api-Secret: ENV.API_SECRET_KEY` + `Authorization: Bearer <token>` when present. On `401`, it auto-calls `/auth/refresh` and retries the original request once. Failure broadcasts `.sessionExpired`.
- **Errors:** `APIError` enum (`invalidResponse`, `refreshFailed`, `unauthorized`, `requestFailed(message)`, `tokenMissing`, `internalServerError(message)`) plus domain errors `EventAPIError`, `ExpenseAPIError`, `ProfileAPIError`.

## 4. Feature Map

| Module | Purpose | Path |
|--------|---------|------|
| Onboarding | 4-slide intro carousel; routes to Login or Home | [`Modules/Onboarding`](Tabi%20Split/Modules/Onboarding) |
| Login | Phone/password auth; guest entry; session-expired banner | [`Modules/Login`](Tabi%20Split/Modules/Login) |
| Register | Name/phone/password sign-up | [`Modules/Register`](Tabi%20Split/Modules/Register) |
| Home | Event list, filters (All / You Owe / Owes You / Settled), profile + inbox entry | [`Modules/Home`](Tabi%20Split/Modules/Home) |
| Event Form | Create/edit event: name, icon, participants | [`Modules/Event/EventForm`](Tabi%20Split/Modules/Event/EventForm) |
| Event Detail | Event hub: summary, expenses, settlements | [`Modules/Event/EventDetail`](Tabi%20Split/Modules/Event/EventDetail) |
| Event Expense | Add/edit expense, item-level splits, receipt OCR (Vision) | [`Modules/Event/EventExpense`](Tabi%20Split/Modules/Event/EventExpense) |
| Event Summary | Per-user balance, history, optimized settlement view | [`Modules/Event/EventDetail/EventSummary`](Tabi%20Split/Modules/Event/EventDetail) |
| Settlement | Optimized payment paths, payment method, receipt upload | (under Event Detail) |
| Profile | User profile, edit, payment methods, logout | [`Modules/Home/Profile`](Tabi%20Split/Modules/Home/Profile) |
| Inbox | Notifications/invitations — UI scaffold, data mocked | [`Modules/Home/Inbox`](Tabi%20Split/Modules/Home/Inbox) |
| Migration | Bulk-upload guest/offline events on first authenticated launch | [`Modules/Migration/MigrationCoordinator.swift`](Tabi%20Split/Modules/Migration/MigrationCoordinator.swift) |

Top-level Home view model: [`HomeViewModel`](Tabi%20Split/Modules/Home/HomeViewModel.swift). Shared event view model used across event flows: [`EventViewModel`](Tabi%20Split/Modules/Event/EventViewModel.swift).

## 5. User Flows

**5.1 First launch**

1. `TabiApp` boots SwiftData container.
2. `ContentView.checkAuthentication()` reads Keychain + SwiftData current user.
3. If onboarding flag unset → `OnboardingView`; else if no token → `LoginView`; else → `HomeView`.
4. On valid session, `runMigrationIfNeeded()` triggers `MigrationCoordinator` if any local events have `isSynced == false`.

**5.2 Create event → add expense → settle**

1. Home → `+` → `EventFormView`: enter name, pick icon (`EventIconEnum`), tap Add Participants → `EventInviteView` → contact picker → `POST /user/check` validates phones.
2. Save → `POST /event` (auth) or store local-only (guest); `EventData(localId, isSynced)` written to SwiftData.
3. Event Detail → `+` → `AddExpenseView`: pick coverer, amount, split method (`equally` or `custom`), optionally `Scan Receipt` (Vision OCR populates items).
4. Custom split → `ExpenseAddItemsView` → `ExpenseAssignView`: assign participants per item; tax/tip via `AdditionalCharge`.
5. Finalize → `POST /expense/{eventId}` or local queue.
6. Summary → `EventViewModel.calculateBalance()` uses a greedy creditor/debtor match; settlement view exposes the optimized path.
7. `POST /event/complete/{eventId}` locks edits; receipt upload attaches proof to a settlement.

**5.3 Guest → authenticated migration**

1. Guest creates events offline with `phone == "Guest"`.
2. User logs in → `runMigrationIfNeeded` collects all `isSynced == false` events.
3. `MigrationCoordinator` rewrites `"Guest"` references to the auth user, batches in groups of 20, calls `POST /migrate`.
4. `MigrateResponse` returns `{local_id → event_id}` mapping; coordinator marks each as synced. `409` is treated as already-migrated and skipped.

**5.4 Session expiration**

1. Any API call returning `401` → `APIService` calls `/auth/refresh`; on failure posts `.sessionExpired`.
2. `SessionState.sessionExpiredBanner` flips on; root UI shows banner + routes to login on tap.

## 6. Data Model

SwiftData `@Model` classes under [`Tabi Split/Infrastructure/Model/`](Tabi%20Split/Infrastructure/Model). Naming caveat: the expense model is **`Expense`** (file [`ExpenseData.swift`](Tabi%20Split/Infrastructure/Model/ExpenseData.swift)).

| Model | Key fields | Relationships |
|-------|------------|---------------|
| `EventData` | `eventId?`, `eventName`, `eventIcon`, `completionDate?`, `userEventBalance`, `createdAt`, `creatorId`, `localId`, `isSynced` | `participants: [UserData]`, `expenses: [Expense]` (.nullify) |
| `UserData` | `userId`, `name`, `phone`, `image`, `imageUrl?` | `events`, `expenses`, `coveredExpenses`, `expenseShare` |
| `Expense` | `expenseId?`, `name`, `dateOfCreation`, `price`, `splitMethod` (`equally`/`custom`), `localId`, `isSynced` | `event?`, `coverer: UserData`, `participants`, `items: [ExpenseItem]` (.cascade), `additionalCharges: [AdditionalCharge]` (.cascade) |
| `ExpenseItem` | item name, price, quantity, assignees | (relationship to `Expense`) |
| `ExpensePerson` | per-person share | (relationship to `Expense` + `UserData`) |
| `AdditionalCharge` | tax / tip / fee | (relationship to `Expense`) |
| `SettlementData` | settlement transfer record | see [`SettlementData.swift`](Tabi%20Split/Infrastructure/Model/SettlementData.swift) |
| `InboxData` | inbox row (mock today) | see [`InboxData.swift`](Tabi%20Split/Infrastructure/Model/InboxData.swift) |
| `NoteData` | scratch notes | (in container schema) |

**Sync invariant:** every event/expense has `localId` (UUID) and `isSynced: Bool`. Server `eventId`/`expenseId` is optional and populated post-sync. The PATH of truth is local DB; backend is reconciled.

## 7. API Contract

**Base URL:** `https://tabi-service.elianrichard.my.id` (see [`ENV.swift`](Tabi%20Split/Constants/ENV.swift)).
**Headers:** `X-Api-Secret: <ENV.API_SECRET_KEY>`, `Authorization: Bearer <token>` (when present), `Content-Type: application/json`.
**Auth retry:** `401` → `POST /auth/refresh` → retry once → on failure, post `.sessionExpired`.

| Method | Path | Purpose | Service |
|--------|------|---------|---------|
| POST | `/auth/register` | Create account | [`AuthService`](Tabi%20Split/Infrastructure/Services/Auth/AuthService.swift) |
| POST | `/auth/login` | Login, returns access + refresh | [`AuthService`](Tabi%20Split/Infrastructure/Services/Auth/AuthService.swift) |
| POST | `/auth/refresh` | Refresh access token | [`AuthService`](Tabi%20Split/Infrastructure/Services/Auth/AuthService.swift) |
| POST | `/event` | Create event | [`EventService`](Tabi%20Split/Infrastructure/Services/Event/EventService.swift) |
| GET  | `/event` | List user's events (with expenses) | [`EventService`](Tabi%20Split/Infrastructure/Services/Event/EventService.swift) |
| PATCH | `/event/{id}` | Edit event (name, icon, participants, dummies) | [`EventService`](Tabi%20Split/Infrastructure/Services/Event/EventService.swift) |
| POST | `/event/complete/{id}` | Mark complete / lock | [`EventService`](Tabi%20Split/Infrastructure/Services/Event/EventService.swift) |
| DELETE | `/event/{id}` | Delete event | [`EventService`](Tabi%20Split/Infrastructure/Services/Event/EventService.swift) |
| POST | `/event/join/{id}` | Join event via deep link | [`EventService`](Tabi%20Split/Infrastructure/Services/Event/EventService.swift) |
| POST | `/expense/{eventId}` | Add expense | [`ExpenseService`](Tabi%20Split/Infrastructure/Services/Expense/ExpenseService.swift) |
| PATCH | `/expense/{id}` | Update expense | [`ExpenseService`](Tabi%20Split/Infrastructure/Services/Expense/ExpenseService.swift) |
| DELETE | `/expense/{id}` | Delete expense | [`ExpenseService`](Tabi%20Split/Infrastructure/Services/Expense/ExpenseService.swift) |
| GET | `/user` | Get current user | [`ProfileService`](Tabi%20Split/Infrastructure/Services/Profile/ProfileService.swift) |
| PATCH | `/user` | Update profile | [`ProfileService`](Tabi%20Split/Infrastructure/Services/Profile/ProfileService.swift) |
| DELETE | `/user` | Delete account | [`ProfileService`](Tabi%20Split/Infrastructure/Services/Profile/ProfileService.swift) |
| POST | `/user/check` | Validate phone numbers (for invites) | [`ProfileService`](Tabi%20Split/Infrastructure/Services/Profile/ProfileService.swift) |
| POST | `/migrate` | Bulk-upload guest events | [`MigrateService`](Tabi%20Split/Infrastructure/Services/Migrate/MigrateService.swift) |

Wire format uses `snake_case`. Response decoding lands directly into domain types via custom initializers (e.g. `UserData(userBase:)`); there is **no separate DTO/mapper layer** — keep snake/camel conversions in the schema files next to each service.

## 8. Key Constants & Config

- [`ENV.swift`](Tabi%20Split/Constants/ENV.swift) — base URL, API secret. **Note:** API secret is committed in source. Do not add new secrets there.
- [`UIConfig.swift`](Tabi%20Split/Constants/UIConfig.swift) — color/spacing tokens.
- Fonts: Figtree (Bold / Medium / Regular / SemiBold), bundled via Resources.
- Permissions (Info.plist): camera (receipt scan), contacts (event invites).
- URL scheme: `tabisplit://` — handled in `ContentView` for `join-event` deep link.
- Light UI style enforced; dark mode not supported.

## 9. Open Questions / TODOs

- **Inbox feature.** [`Modules/Home/Inbox`](Tabi%20Split/Modules/Home/Inbox) is UI-only; `InboxData` is mocked. No polling / WebSocket / push backend integration yet.
- **Apple Sign-In.** UI present but disabled in [`LoginView`](Tabi%20Split/Modules/Login/LoginView.swift) (~line 89). Decide: implement, hide, or remove.
- **Reminder feature.** Hinted in onboarding copy ([`OnboardingView`](Tabi%20Split/Modules/Onboarding) ~line 37). No implementation.
- **Profile image upload.** `UserData.imageUrl` exists; the upload pipeline (multipart? presigned URL?) is unclear. `PATCH /user` accepts `avatar_url` only.
- **Settlement payment webhooks.** No backend confirmation of "payment received" beyond local receipt upload.
- **Uncommitted local edits at snapshot time:** [`EventData.swift`](Tabi%20Split/Infrastructure/Model/EventData.swift) and [`Modules/Home/Components/EventCard.swift`](Tabi%20Split/Modules/Home/Components/EventCard.swift) — re-verify before relying on field lists.
- **`SwiftDataTestingView.swift`** in [`Modules/Home`](Tabi%20Split/Modules/Home/SwiftDataTestingView.swift) appears to be a developer scratchpad. Confirm before referencing in user flows.
- **API secret in source.** `ENV.API_SECRET_KEY` is checked in. If rotated, rotate here and in backend together.

## 10. Glossary

- **Event** — shared context with participants, an icon, and a list of expenses. Persisted as `EventData`.
- **Participant** — `UserData` linked to an event. May be authenticated or a "dummy" (placeholder name) until they sign up.
- **Coverer** — the participant who actually paid for an expense (the lender).
- **Expense** — a single charge inside an event. Has `splitMethod` (`equally` or `custom`), a coverer, items, and additional charges.
- **Item** — line in a receipt-style expense (`ExpenseItem`). Each item can be assigned to a subset of participants.
- **Additional Charge** — tax / tip / service fee on top of items (`AdditionalCharge`).
- **Split Method** — `equally` (price ÷ participants) or `custom` (per-item assignment).
- **Settlement** — a transfer from debtor to creditor. Field on `SettlementData`.
- **Optimization** — minimum-transfer settlement plan (greedy match between debtors and creditors in `EventViewModel.calculateBalance`).
- **Balance** — `lent − debt` per user. Surfaced as You Owe / Owes You / Settled.
- **Sync flag (`isSynced`)** — `true` once the backend has acknowledged the event/expense.
- **Local ID (`localId`)** — UUID generated client-side; stable across sync, used as the migration key.
- **Migration** — `POST /migrate` flow that converts guest events into authenticated server events.
- **Guest mode** — offline-only mode where `UserData.phone == "Guest"`.
- **Session expired** — broadcast via `Notification.Name.sessionExpired` after a refresh failure.
- **Probe session** — `ProfileService.probeSession()`; called at launch to validate the stored token.
