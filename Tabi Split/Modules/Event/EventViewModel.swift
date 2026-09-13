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
    /// The current user's row from the last `calculateOptimization` run, or an
    /// empty (settled) placeholder. Stored rather than re-derived from
    /// UserDefaults so every screen resolves "me" exactly as the engine did.
    var userBalance: PersonBalanceData = PersonBalanceData(user: UserData(name: "Unknown", email: ""))
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
    
    /// Runs the settlement engine for `selectedEvent` and publishes its output.
    /// Every balance-derived value on this view model comes from here.
    func calculateOptimization(currentUser: UserData) {
        guard let event = selectedEvent else { return }
        guard let result = SettlementCalculator.compute(participants: event.participants, expenses: event.expenses, currentUser: currentUser) else {
            // An expense references a non-participant: show everyone as settled
            // rather than a half-computed plan.
            participantsBalance = event.participants
                .map { PersonBalanceData(user: $0) }
                .sorted { $0.user.name.lowercased() < $1.user.name.lowercased() }
            directSettlements = []
            userTransactionHistory = []
            userTotalSpending = 0
            userSettlementList = []
            userBalance = PersonBalanceData(user: currentUser)
            return
        }
        participantsBalance = result.participants
        directSettlements = result.directSettlements
        userTransactionHistory = result.userTransactionHistory
        userTotalSpending = result.userTotalSpending
        userSettlementList = result.userSettlementList
        userBalance = result.userBalance ?? PersonBalanceData(user: currentUser)
        // Keep Home's card in step without waiting for the next list refresh.
        event.userEventBalance = userBalance.balance
    }
}
