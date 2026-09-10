//
//  EventData+Sync.swift
//  Tabi Split
//
//  Created by Elian Richard on 10/09/26.
//

import Foundation
import SwiftData

/// Server → SwiftData mapping for events, shared by Home's full list refresh
/// (`insertSynced`) and the detail screen's in-place refresh (`apply`). Both
/// consume the same payload shape (`EventBase`), so an event refreshed on its
/// own ends up identical to one rebuilt from the list.
///
/// The `ModelContext` is injected (rather than reaching for
/// `SwiftDataService.shared`) so the mapping can be unit-tested against an
/// in-memory container.
extension EventData {

    /// Inserts a new synced event built from `base` into `context`.
    @MainActor
    @discardableResult
    static func insertSynced(from base: EventBase, currentUser: UserData, in context: ModelContext) -> EventData {
        let event = EventData(eventName: base.name, creatorId: base.creator_id, isSynced: true)
        // Insert before wiring relationships so participants/expenses attach to
        // a managed object rather than a transient one.
        context.insert(event)
        event.apply(from: base, currentUser: currentUser, in: context)
        return event
    }

    /// Updates this event in place from `base`, keeping the object identity so
    /// views observing `selectedEvent` (and Home's list) re-render without a
    /// swap. Expenses are reconciled by server id: changed ones are updated,
    /// synced ones missing from the server are deleted, new ones are added, and
    /// unsynced local rows (pending creates) are left untouched.
    @MainActor
    func apply(from base: EventBase, currentUser: UserData, in context: ModelContext) {
        eventId = base.id
        eventName = base.name
        eventIcon = (EventIconEnum(rawValue: base.avatar_url) ?? .icon1).id
        completionDate = (base.completion_date ?? "").convertIsoToDate()
        creatorId = base.creator_id
        if let created = base.created_at.convertIsoToDate() {
            createdAt = created
        }
        isSynced = true

        var users = UserLookup(context: context)
        var resolvedParticipants: [UserData] = []
        for participant in base.participants {
            resolvedParticipants.append(users.resolve(participant))
        }
        participants = resolvedParticipants

        reconcileExpenses(with: base.expenses, users: users, in: context)
        calculateUserEventBalance(currentUser: currentUser)
    }

    @MainActor
    private func reconcileExpenses(with incoming: [ExpenseEventBase], users: UserLookup, in context: ModelContext) {
        var pending = Dictionary(incoming.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        for expense in Array(expenses) {
            // A local create that hasn't reached the server yet has no server
            // counterpart; leave it queued rather than treating it as deleted.
            guard expense.isSynced else { continue }
            if let id = expense.expenseId, let serverExpense = pending.removeValue(forKey: id) {
                expense.apply(from: serverExpense, users: users, in: context)
            } else {
                expenses.removeAll { $0 === expense }
                expense.deleteWithContents(in: context)
            }
        }

        // Anything still pending is new on the server; append in server order.
        for serverExpense in incoming where pending[serverExpense.id] != nil {
            if let expense = Expense.insertSynced(from: serverExpense, users: users, in: context) {
                expenses.append(expense)
            }
        }
    }
}

extension Expense {

    /// Inserts a new synced expense built from `base`, or nil when its coverer
    /// or split method can't be resolved (same skip rule as the list refresh).
    @MainActor
    static func insertSynced(from base: ExpenseEventBase, users: UserLookup, in context: ModelContext) -> Expense? {
        guard let coverer = users.byId(base.coverer_id),
              let method = SplitMethod(rawValue: base.split_method) else { return nil }
        let expense = Expense(expenseId: base.id, name: base.name, coverer: coverer, price: base.total_expense, splitMethod: method, isSynced: true)
        context.insert(expense)
        expense.apply(from: base, users: users, in: context)
        return expense
    }

    /// Updates this expense in place from `base`. Left untouched (not
    /// half-applied) when the coverer or split method can't be resolved.
    @MainActor
    func apply(from base: ExpenseEventBase, users: UserLookup, in context: ModelContext) {
        guard let coverer = users.byId(base.coverer_id),
              let method = SplitMethod(rawValue: base.split_method) else { return }
        expenseId = base.id
        name = base.name
        self.coverer = coverer
        creator = base.creator_id.flatMap { users.byId($0) }
        if let created = base.created_at.convertIsoToDate() {
            dateOfCreation = created
        }
        price = base.total_expense
        splitMethod = method.id
        receiptId = base.receipt_url.isEmpty ? nil : base.receipt_url
        isSynced = true
        rebuildLineItems(from: base, users: users, in: context)
    }

    /// Replaces items, assignees and charges wholesale. They carry no
    /// local-only state, so rebuilding is simpler and safer than diffing.
    @MainActor
    private func rebuildLineItems(from base: ExpenseEventBase, users: UserLookup, in context: ModelContext) {
        deleteLineItems(in: context)

        var resolvedParticipants: [UserData] = []
        var newItems: [ExpenseItem] = []
        for item in base.items {
            var assignees: [ExpensePerson] = []
            for assignee in item.assignees {
                guard let user = users.byId(assignee.user_id) else { continue }
                assignees.append(ExpensePerson(user: user, share: assignee.share))
                if !resolvedParticipants.contains(where: { $0 == user }) {
                    resolvedParticipants.append(user)
                }
            }
            newItems.append(ExpenseItem(itemId: item.id, itemName: item.name, itemPrice: item.price, itemQuantity: item.quantity, assignees: assignees))
        }
        participants = resolvedParticipants
        items = newItems
        additionalCharges = base.additional_charges.map { AdditionalCharge(additionalChargeBase: $0) }
    }

    /// `ExpenseItem.assignees` only nullifies on delete, so assignee rows must
    /// be removed explicitly or they linger as orphans.
    @MainActor
    private func deleteLineItems(in context: ModelContext) {
        for item in items {
            for person in item.assignees {
                context.delete(person)
            }
            context.delete(item)
        }
        items.removeAll()
        for charge in additionalCharges {
            context.delete(charge)
        }
        additionalCharges.removeAll()
    }

    /// Deletes the expense and its line items (see `deleteLineItems`).
    @MainActor
    func deleteWithContents(in context: ModelContext) {
        deleteLineItems(in: context)
        context.delete(self)
    }
}

/// One fetch of all users per refresh, keyed by server id. New server
/// participants are inserted on first sight and reused for later lookups
/// (expense coverers/assignees are always event participants).
@MainActor
struct UserLookup {
    private var byServerId: [String: UserData]
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
        let users = (try? context.fetch(FetchDescriptor<UserData>())) ?? []
        var map: [String: UserData] = [:]
        for user in users where !user.userId.isEmpty {
            // Duplicate rows can exist after past refreshes; first wins, matching
            // SwiftDataService.getUserByUserId.
            if map[user.userId] == nil {
                map[user.userId] = user
            }
        }
        byServerId = map
    }

    func byId(_ id: String) -> UserData? {
        byServerId[id]
    }

    /// Existing row updated from the payload, or a new one inserted.
    mutating func resolve(_ base: UserBase) -> UserData {
        if let existing = byServerId[base.user_id] {
            existing.update(fromUserBase: base)
            return existing
        }
        let user = UserData(userBase: base)
        context.insert(user)
        byServerId[base.user_id] = user
        return user
    }
}
