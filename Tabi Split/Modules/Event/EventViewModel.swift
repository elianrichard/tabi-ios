//
//  EventFormViewModel.swift
//  Tabi
//
//  Created by Elian Richard on 06/10/24.
//

import SwiftUI
import os.log

private extension OSLog {
    /// In-place event refresh diagnostics — filter Console.app / Xcode console by
    /// category "EventSync" to trace pull-to-refresh, foreground and poll syncs.
    static let sync = OSLog(subsystem: ENV.APP_BUNDLE_ID, category: "EventSync")
}

@Observable
final class EventViewModel {
    var selectedSection: EventSectionEnum = .expenses
    
    var selectedEvent: EventData? {
        didSet {
            lastSyncedAt = nil
            if let event = selectedEvent {
                eventName = event.eventName
                eventIcon = EventIconEnum(rawValue: event.eventIcon) ?? .icon1
                selectedSection = .expenses
            } else {
                eventName = ""
                eventIcon = .icon1
            }
        }
    }
    //    eventName and eventIcon need to be Bindable var, so user can change dynamically
    var eventName: String = ""
    var eventIcon: EventIconEnum = .icon1
    
    var isEventCompleted: Bool {
        if let event = selectedEvent {
            return event.completionDate != nil
        } else { return false }
    }
    var isNoParticipants: Bool {
        if let event = selectedEvent {
            return event.participants.count <= 1
        } else { return true }
    }
    var isUserCreator: Bool {
        if let user = UserDefaultsService.shared.getCurrentUser(), let selectedEvent {
            return user.userId == selectedEvent.creatorId
        } else { return false }
    }
    var isDirectInvite: Bool = false
    
    var participantsBalance: [PersonBalanceData] = []
    /// Raw pairwise debts (each debtor pays each coverer directly, no netting).
    /// Same shape as `participantsBalance` so the recap card can reuse it; only
    /// `settlement` is populated. Used by the recap's non-simplified mode.
    var directSettlements: [PersonBalanceData] = []
    var userTransactionHistory: [SummaryHistoryData] = []
    var userBalance: PersonBalanceData {
        if let currentUser = UserDefaultsService.shared.getCurrentUser(),
           let personBalance = participantsBalance.first(where: { $0.user.isSameUser(as: currentUser) }) {
            return personBalance
        } else { return PersonBalanceData(user: UserData(name: "Unkown", email: "")) }
    }
    var userTotalSpending: Float = 0
    var userSettlementList: [SummarySettlementData] = []
    
    var isApiCallLoading = false

    // MARK: - In-place refresh of the open event

    /// True while a background refresh of `selectedEvent` is in flight. Drives
    /// the small sync indicator on the detail screen; never the full overlay.
    var isSyncing = false
    /// When `selectedEvent` was last refreshed from the server in this session.
    /// Reset whenever a different event is selected.
    private(set) var lastSyncedAt: Date?

    enum RefreshOutcome: Equatable {
        case updated
        /// Nothing to do: no synced event selected, a refresh or a local write
        /// is already in flight, or the data is still fresh.
        case skipped
        /// Network/server error; local data left untouched.
        case failed
        /// The event was deleted, or the user is no longer a participant.
        case gone
    }

    /// Refreshes only when the last successful refresh is older than `maxAge`.
    @MainActor
    func refreshSelectedEventIfStale(currentUser: UserData, maxAge: TimeInterval) async -> RefreshOutcome {
        if let lastSyncedAt, Date().timeIntervalSince(lastSyncedAt) < maxAge {
            return .skipped
        }
        return await refreshSelectedEvent(currentUser: currentUser)
    }

    /// Fetches `selectedEvent` from the server and merges it in place (same
    /// object, so observers re-render without a swap), then recomputes the
    /// summary. Silent: no loading overlay, no error dialog.
    @MainActor
    func refreshSelectedEvent(currentUser: UserData) async -> RefreshOutcome {
        guard let event = selectedEvent else {
            os_log(.info, log: .sync, "refresh skipped: no selected event")
            return .skipped
        }
        guard event.isSynced, let eventId = event.eventId else {
            os_log(.info, log: .sync, "refresh skipped: event not synced (isSynced=%{public}@ eventId=%{public}@)",
                   String(event.isSynced), event.eventId ?? "nil")
            return .skipped
        }
        // Don't race a local mutation (edit/complete/delete) or another refresh.
        guard !isSyncing, !isApiCallLoading else {
            os_log(.info, log: .sync, "refresh skipped: busy (isSyncing=%{public}@ isApiCallLoading=%{public}@)",
                   String(isSyncing), String(isApiCallLoading))
            return .skipped
        }
        isSyncing = true
        defer { isSyncing = false }

        os_log(.info, log: .sync, "refresh start: event=%{public}@ local expenses=%d participants=%d",
               eventId, event.expenses.count, event.participants.count)
        let base: EventBase
        do {
            base = try await EventService.shared.getEvent(eventId: eventId)
        } catch let error as APIError {
            switch error {
            case .notFound, .forbidden:
                os_log(.error, log: .sync, "refresh gone: %{public}@", String(describing: error))
                return .gone
            default:
                os_log(.error, log: .sync, "refresh failed: %{public}@", String(describing: error))
                return .failed
            }
        } catch {
            os_log(.error, log: .sync, "refresh failed: %{public}@", String(describing: error))
            return .failed
        }

        // A deeplink/push may have switched events while the request was out.
        guard selectedEvent === event, !isApiCallLoading else {
            os_log(.info, log: .sync, "refresh discarded: selection changed or local write started mid-flight")
            return .skipped
        }

        os_log(.info, log: .sync, "refresh fetched: server expenses=%d participants=%d name=%{public}@",
               base.expenses.count, base.participants.count, base.name)
        event.apply(from: base, currentUser: currentUser, in: SwiftDataService.shared.modelContext)
        SwiftDataService.shared.saveModelContext()
        // `selectedEvent`'s didSet only runs on assignment, so mirror the
        // header fields it derives (the title reads `eventName`).
        eventName = event.eventName
        eventIcon = EventIconEnum(rawValue: event.eventIcon) ?? .icon1
        calculateOptimization(currentUser: currentUser)
        lastSyncedAt = Date()
        os_log(.info, log: .sync, "refresh applied: local expenses=%d participants=%d",
               event.expenses.count, event.participants.count)
        return .updated
    }
    
    @MainActor
    func handleEditEvent (selectedContacts: [UserData], currentUser: UserData) async -> Bool {
        guard let selectedEvent else { return false }
        isApiCallLoading = true
        defer { isApiCallLoading = false }

        do {
            var participants: [UserData] = selectedContacts
            // Only look up emails that exist; a list of only name-only dummies has
            // none, so skip the call entirely rather than sending an empty list.
            let emailsToCheck = selectedContacts.map { $0.email }.filter { !$0.isEmpty }
            let registeredUsers: [UserData]
            if emailsToCheck.isEmpty {
                registeredUsers = []
            } else {
                let checkUsersResponse = try await ProfileService.shared.checkUsers(emails: emailsToCheck)
                registeredUsers = checkUsersResponse.users.map { user in
                    if let image = ProfileImageEnum(rawValue: user.avatar_url) {
                        UserData(userId: user.user_id, name: user.name, email: user.email ?? "", image: image, imageUrl: "")
                    } else {
                        UserData(userId: user.user_id, name: user.name, email: user.email ?? "", image: .owl, imageUrl: user.avatar_url)
                    }
                }
            }

            let unregisteredUsers: [UserData] = selectedContacts.filter { contact in
                return !registeredUsers.contains(where: { user in user.email == contact.email })
            }

            // A dummy that already has a userId was created on a previous invite.
            // Keep its anchor (id + image) and send it as a normal participant so
            // the backend reuses the existing row instead of minting a new dummy
            // with a fresh random avatar. Only brand-new dummies (empty userId)
            // are sent via dummy_users (name + client-chosen avatar).
            let anchoredDummyUsers: [UserData] = unregisteredUsers.filter { !$0.userId.isEmpty }
            var newDummyUsers: [UserData] = unregisteredUsers.filter { $0.userId.isEmpty }

            let participantsToSend = registeredUsers + anchoredDummyUsers
            let response = try await EventService.shared.updateEvent(event: EventData(eventId: selectedEvent.eventId, eventName: eventName, eventIcon: eventIcon, participants: participantsToSend, creatorId: selectedEvent.creatorId), newDummyUsers: newDummyUsers)

            var registeredDummyUsers: [UserData] = []
            for dummyInfo in response.dummy_user_info {
                if let user = newDummyUsers.first(where: { $0.name == dummyInfo.dummy_name }) {
                    // Anchor the new dummy to the backend's id, and adopt the
                    // avatar it assigned so the image stays fixed from now on.
                    user.userId = dummyInfo.dummy_user_id
                    if let avatar = dummyInfo.avatar_url, let image = ProfileImageEnum(rawValue: avatar) {
                        user.image = image.id
                    }
                    registeredDummyUsers.append(user)
                    newDummyUsers.remove(user)
                }
            }
            participants = registeredUsers + anchoredDummyUsers + registeredDummyUsers
            selectedEvent.eventName = eventName
            selectedEvent.eventIcon = eventIcon.id
            selectedEvent.participants = participants
            SwiftDataService.shared.saveModelContext()
        } catch {
            print("Edit Event failed: \(error)")
            return false
        }
        return true

    }

    @MainActor
    func handleCreateEvent (currentUser: UserData) async -> Bool {
        isApiCallLoading = true
        defer { isApiCallLoading = false }

        do {
            let response = try await EventService.shared.createEvent(name: eventName, image: eventIcon.id)
            let eventId = response.event_id
            // Source creatorId from the same authoritative identity the edit gate
            // reads (UserDefaults JWT userId) rather than currentUser.userId, which
            // can be "" when the SwiftData user row hasn't resolved yet — an empty
            // creatorId would make isUserCreator false and hide the Edit menu.
            let creatorId = UserDefaultsService.shared.getCurrentUser()?.userId ?? currentUser.userId
            let newEvent = EventData(eventId: eventId, eventName: eventName, eventIcon: eventIcon, participants: [currentUser], creatorId: creatorId, isSynced: true)
            SwiftDataService.shared.addEvent(newEvent)
        } catch {
            print("Create event failed: \(error)")
            return false
        }
        return true
    }

    @MainActor
    func handleDeleteEvent () async -> Bool {
        guard let selectedEvent else { return false }
        isApiCallLoading = true
        defer { isApiCallLoading = false }

        do {
            try await EventService.shared.deleteEvent(event: selectedEvent)
            SwiftDataService.shared.deleteEvent(selectedEvent)
        } catch {
            print("Delete event failed: \(error)")
            return false
        }
        return true
    }

    // Leaves the event as a non-creator participant: the backend replaces the
    // caller with a placeholder dummy (keeping their expense history), and the
    // event is dropped from this user's local list since they no longer belong.
    @MainActor
    func handleLeaveEvent () async -> Bool {
        guard let selectedEvent, let eventId = selectedEvent.eventId else { return false }
        isApiCallLoading = true
        defer { isApiCallLoading = false }

        do {
            _ = try await EventService.shared.leaveEvent(eventId: eventId)
            SwiftDataService.shared.deleteEvent(selectedEvent)
        } catch {
            print("Leave event failed: \(error)")
            return false
        }
        return true
    }

    @MainActor
    func completeEvent() async -> Bool {
        guard let selectedEvent else { return false }
        isApiCallLoading = true
        defer { isApiCallLoading = false }

        do {
            try await EventService.shared.completeEvent(event: selectedEvent)
            SwiftDataService.shared.completeEvent(selectedEvent)
        } catch {
            print("Event completion fail: \(error)")
            return false
        }
        return true
    }

    @MainActor
    func incompleteEvent() async -> Bool {
        guard let selectedEvent else { return false }
        isApiCallLoading = true
        defer { isApiCallLoading = false }

        do {
            try await EventService.shared.incompleteEvent(event: selectedEvent)
            SwiftDataService.shared.incompleteEvent(selectedEvent)
        } catch {
            print("Event incomplete fail: \(error)")
            return false
        }
        return true
    }
    
    func calculateOptimization(currentUser: UserData) {
        let debug = false // enable this to debug print

        var userSummaryData: [SummaryHistoryData] = []
        var userTotalSpendingTemp: Float = 0

        // Raw pairwise debts for the recap's non-simplified mode: for every
        // expense each buyer owes the coverer their share directly, with no
        // netting across people. Keyed by identity (userId can be empty for
        // dummy participants) to match the `==` lookups used below.
        var directDebtMap: [ObjectIdentifier: [ObjectIdentifier: Float]] = [:]
        var userLookup: [ObjectIdentifier: UserData] = [:]
        func recordDirectDebt(from buyer: UserData, to coverer: UserData, amount: Float) {
            guard buyer !== coverer, amount != 0 else { return }
            let buyerKey = ObjectIdentifier(buyer)
            let covererKey = ObjectIdentifier(coverer)
            userLookup[buyerKey] = buyer
            userLookup[covererKey] = coverer
            directDebtMap[buyerKey, default: [:]][covererKey, default: 0] += amount
        }

        // Robust "is this the signed-in user" check. A bare `== currentUser`
        // only matches the same object instance, so after a backend sync (which
        // rebuilds UserData objects) the current user's expense rows silently
        // failed to register in their own transaction history. Match on userId
        // first (authoritative), then email, then object identity.
        func isCurrentUser(_ user: UserData) -> Bool {
            if user === currentUser { return true }
            if !user.userId.isEmpty && !currentUser.userId.isEmpty {
                return user.userId == currentUser.userId
            }
            if !user.email.isEmpty && !currentUser.email.isEmpty && currentUser.email != "unknown" {
                return user.email == currentUser.email
            }
            return false
        }
        guard let event = selectedEvent else { print("[OPT] no selectedEvent -> bail"); return }
        if debug {
            print("[OPT] ===== calculateOptimization START event=\(event.eventName) =====")
            print("[OPT] currentUser name=\(currentUser.name) id=\(currentUser.userId) email=\(currentUser.email) ptr=\(ObjectIdentifier(currentUser))")
            print("[OPT] event.participants count=\(event.participants.count)")
            for p in event.participants {
                print("[OPT]   participant name=\(p.name) id=\(p.userId) email=\(p.email) ptr=\(ObjectIdentifier(p))")
            }
            print("[OPT] event.expenses count=\(event.expenses.count)")
        }
        participantsBalance = event.participants
            .map { PersonBalanceData(user: $0) }
            .sorted { $0.user.name.lowercased() < $1.user.name.lowercased() }

        // Identity-keyed index so the per-expense lookups below are O(1) instead
        // of a linear `.first(where:)` scan on every coverer/assignee/participant.
        // Keyed by object identity to match the `==` semantics used previously.
        let balanceByUser: [ObjectIdentifier: PersonBalanceData] = Dictionary(
            participantsBalance.map { (ObjectIdentifier($0.user), $0) },
            uniquingKeysWith: { first, _ in first }
        )
        // Secondary indexes for the robust fallback below: an expense can
        // reference a *different* UserData instance than the one in
        // event.participants (same person, rebuilt object after a SwiftData
        // re-fetch / navigation). ObjectIdentifier then misses, the old code
        // bailed, and participantsBalance was left all-zero -> the summary card
        // wrongly showed "all settled". Fall back to userId, then email.
        var balanceByUserId: [String: PersonBalanceData] = [:]
        var balanceByEmail: [String: PersonBalanceData] = [:]
        for balance in participantsBalance {
            if !balance.user.userId.isEmpty { balanceByUserId[balance.user.userId] = balance }
            if !balance.user.email.isEmpty { balanceByEmail[balance.user.email] = balance }
        }

        /// Resolve the balance row for a user referenced by an expense, tolerating
        /// object-identity mismatches. Returns nil only when the user truly isn't
        /// a participant.
        func resolveBalance(for user: UserData) -> PersonBalanceData? {
            if let hit = balanceByUser[ObjectIdentifier(user)] { return hit }
            if !user.userId.isEmpty, let hit = balanceByUserId[user.userId] {
                if debug { print("[OPT]   ~ resolved \(user.name) by userId fallback (identity missed)") }
                return hit
            }
            if !user.email.isEmpty, let hit = balanceByEmail[user.email] {
                if debug { print("[OPT]   ~ resolved \(user.name) by email fallback (identity missed)") }
                return hit
            }
            return nil
        }

        //        FILL THE PERSON LENT AND PERSON DEBT EXPENSE

        for expense in event.expenses {
            var userBalanceTemp: Float = 0
            if debug { print(expense.name + " - " + "Coverer: " + expense.coverer.name + " \(expense.price.formatPrice()) split=\(expense.splitMethod) participants=\(expense.participants.count) items=\(expense.items.count)") }
            if debug { print("[OPT]   coverer name=\(expense.coverer.name) id=\(expense.coverer.userId) email=\(expense.coverer.email) ptr=\(ObjectIdentifier(expense.coverer))") }
            guard let personPaid = resolveBalance(for: expense.coverer) else {
                print("[OPT] !! BAIL: coverer not a participant. expense=\(expense.name) coverer name=\(expense.coverer.name) id=\(expense.coverer.userId) email=\(expense.coverer.email) participants=\(participantsBalance.map { "\($0.user.name)#\($0.user.userId)" })")
                return
            }
            personPaid.lent += expense.price

            if isCurrentUser(expense.coverer) {
                userBalanceTemp += expense.price
            }

            if (expense.splitMethod == SplitMethod.custom.id) {
                let totalAdditionalCharges: Float = expense.additionalCharges.reduce(0) { $0 + $1.amount }
                let itemTotalAmount = expense.items.reduce(0) {$0 + $1.itemPrice * $1.itemQuantity}
                for item in expense.items {
                    let itemTotalShares = item.assignees.reduce(0) { $0 + ($1.share) }
                    for assignee in item.assignees {
                        guard let personBuy = resolveBalance(for: assignee.user) else {
                            print("[OPT] !! BAIL: assignee not a participant (custom split). expense=\(expense.name) item=\(item.itemName) assignee name=\(assignee.user.name) id=\(assignee.user.userId) email=\(assignee.user.email)")
                            return
                        }
                        let personQuantity = (assignee.share / itemTotalShares) * item.itemQuantity
                        let amountSpent = personQuantity * item.itemPrice
                        let amountAdditional = totalAdditionalCharges * (amountSpent / itemTotalAmount)
                        let amountDebt = Float(amountSpent + amountAdditional).properRound()
                        if debug { print("Participants: " + assignee.user.name, "\(item.itemName) Spent: ", amountSpent, "Additional: ", amountAdditional, "debt: ", amountDebt) }
                        if (isCurrentUser(expense.coverer) && isCurrentUser(personBuy.user)) {
                            personPaid.lent -= amountDebt
                        } else {
                            personBuy.debt += amountDebt
                        }
                        recordDirectDebt(from: personBuy.user, to: expense.coverer, amount: amountDebt)
                        if (isCurrentUser(assignee.user)) {
                            userTotalSpendingTemp += amountDebt
                            userBalanceTemp -= amountDebt
                        }
                    }
                }
            } else if (expense.splitMethod == SplitMethod.equally.id) {
                let amountDebt = Float(expense.price / Float(expense.participants.count)).rounded(toDecimalPlaces: 1).properRound()
                for person in expense.participants {
                    guard let personBuy = resolveBalance(for: person) else {
                        print("[OPT] !! BAIL: participant not a participant (equally split). expense=\(expense.name) person name=\(person.name) id=\(person.userId) email=\(person.email)")
                        return
                    }
                    if (isCurrentUser(expense.coverer) && isCurrentUser(personBuy.user)) {
                        personPaid.lent -= amountDebt
                    } else {
                        personBuy.debt += amountDebt
                    }
                    recordDirectDebt(from: personBuy.user, to: expense.coverer, amount: amountDebt)
                    if (isCurrentUser(person)) {
                        userTotalSpendingTemp += amountDebt
                        userBalanceTemp -= amountDebt
                    }
                }
            }
            
            //            record the specific user balance history data
            if debug {
                print("[OPT][HIST] expense=\(expense.name) covererIsMe=\(isCurrentUser(expense.coverer)) userBalanceTemp=\(userBalanceTemp) -> \(userBalanceTemp != 0 ? "APPEND" : "skip")")
            }
            if (userBalanceTemp != 0) {
                userSummaryData.append(SummaryHistoryData(expenseName: expense.name, expenseDate: expense.dateOfCreation, amount: userBalanceTemp, expense: expense))
            }
        }
        
        if debug { print("[OPT] all expenses processed OK (no early return). participantsBalance count=\(participantsBalance.count)") }

        userTotalSpending = userTotalSpendingTemp
        userTransactionHistory = userSummaryData.sorted(by: { $0.expenseDate > $1.expenseDate })

        // Build the raw pairwise settlement list from the accumulated debt map.
        // One PersonBalanceData per debtor, ordered the same as participantsBalance,
        // each carrying a settlement row per creditor sorted by name.
        directSettlements = participantsBalance.compactMap { balance in
            guard let creditors = directDebtMap[ObjectIdentifier(balance.user)], !creditors.isEmpty else { return nil }
            let entry = PersonBalanceData(user: balance.user)
            entry.settlement = creditors.compactMap { key, amount -> PersonSettlementData? in
                let rounded = amount.properRound()
                guard let coverer = userLookup[key], rounded != 0 else { return nil }
                return PersonSettlementData(userPaid: coverer, amount: rounded)
            }
            .sorted(by: { $0.userPaid.name.lowercased() < $1.userPaid.name.lowercased() })
            return entry.settlement.isEmpty ? nil : entry
        }
        
        //        CALCULATE EACH PERSON BALANCE BASED ON LENT AND DEBT VALUE
        if debug {
            for participant in participantsBalance {
                print("\(participant.user.name) balance: " + String(participant.balance.formatPrice()))
            }
        }
        
        let personWithDebt: [PersonBalanceData] = participantsBalance.filter { $0.balance < 0 }.sorted(by: { $0.balance < $1.balance })
        let personWithLent: [PersonBalanceData] = participantsBalance.filter { $0.balance > 0 }.sorted(by: { $0.balance < $1.balance })
        
        for debtUser in personWithDebt {
            for lentUser in personWithLent {
                if debug { print("lent: ", lentUser.user.name, lentUser.calculationBalance, "debt: ", debtUser.user.name, debtUser.calculationBalance) }
                if (lentUser.calculationBalance <= 0) { continue }
                let sum = debtUser.calculationBalance + lentUser.calculationBalance
                if debug { print(debtUser.user.name, lentUser.user.name, sum) }
                if (sum >= 0) {
                    debtUser.settlement.append(PersonSettlementData(userPaid: lentUser.user, amount: abs(debtUser.calculationBalance)))
                    debtUser.calculationBalance = 0
                    lentUser.calculationBalance = sum
                    break
                } else if (sum < 0) {
                    debtUser.settlement.append(PersonSettlementData(userPaid: lentUser.user, amount: lentUser.calculationBalance))
                    debtUser.calculationBalance = sum
                    lentUser.calculationBalance = 0
                }
            }
        }
        
        //        Fill up user's settlement list
        // Resolve the current user's balance once; `userBalance` is a computed
        // property that re-runs getCurrentUser + a linear scan on every access.
        let currentUserBalance = userBalance

        if debug {
            print("[OPT] ----- FINAL balances event=\(event.eventName) -----")
            for p in participantsBalance {
                print("[OPT]   \(p.user.name) id=\(p.user.userId) lent=\(p.lent) debt=\(p.debt) balance=\(p.balance) status=\(p.status) settlements=\(p.settlement.count)")
            }
            print("[OPT]   >>> userBalance: name=\(currentUserBalance.user.name) id=\(currentUserBalance.user.userId) balance=\(currentUserBalance.balance) status=\(currentUserBalance.status)")
            let matched = participantsBalance.contains { isCurrentUser($0.user) }
            if !matched {
                print("[OPT]   !! WARNING: current user (id=\(currentUser.userId) email=\(currentUser.email)) not found among participants -> userBalance is a default 'settled' placeholder")
            }
            print("[OPT] ----- END event=\(event.eventName) -----")
        }
        userSettlementList = []
        if currentUserBalance.status == .debt {
            for settlement in currentUserBalance.settlement {
                userSettlementList.append(SummarySettlementData(targetUser: settlement.userPaid, amount: settlement.amount, status: .NeedPayment))
            }
        } else if currentUserBalance.status == .credit {
            let relatedPersonBalance = participantsBalance.filter { $0.settlement.contains(where: { isCurrentUser($0.userPaid) }) }
            for balance in relatedPersonBalance {
                for settlement in balance.settlement {
                    userSettlementList.append(SummarySettlementData(targetUser: balance.user, amount: settlement.amount, status: .WaitingPayment))
                }
            }
        }
        userSettlementList = userSettlementList.sorted(by: { $0.targetUser.name.lowercased() < $1.targetUser.name.lowercased() })

        if let selectedEvent {
            selectedEvent.userEventBalance = currentUserBalance.balance
        }
        
        if debug {
            print("=== CALCULATE FINISH ===")
            for person in participantsBalance {
                for settlement in person.settlement {
                    print("\(person.user.name) should pay \(settlement.userPaid.name) for amount of \(settlement.amount.formatPrice())")
                }
            }
            for person in participantsBalance {
                print("\(person.user.name) balance: \(person.balance) calculation balance: \(person.calculationBalance)")
            }
        }
    }
}
