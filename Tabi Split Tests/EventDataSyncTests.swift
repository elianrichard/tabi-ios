//
//  EventDataSyncTests.swift
//  Tabi Split Tests
//
//  Created by Elian Richard on 10/09/26.
//

import XCTest
import SwiftData
@testable import Tabi_Split

/// Covers the server → SwiftData mapping shared by Home's list refresh and the
/// detail screen's in-place refresh (EventData+Sync.swift).
@MainActor
final class EventDataSyncTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var me: UserData!

    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: EventData.self, UserData.self, configurations: config)
        context = ModelContext(container)
        context.autosaveEnabled = false
        me = UserData(userId: "user-me", name: "Me", email: "me@example.com", kind: "real", image: .owl)
        context.insert(me)
        try context.save()
    }

    override func tearDown() async throws {
        context = nil
        container = nil
    }

    // MARK: - Fixtures

    private func user(_ id: String, name: String) -> UserBase {
        UserBase(user_id: id, email: "\(id)@example.com", name: name, avatar_url: "owl", kind: "real")
    }

    private func expense(_ id: String, name: String, coverer: String, total: Float, assignees: [String]) -> ExpenseEventBase {
        ExpenseEventBase(
            id: id,
            name: name,
            coverer_id: coverer,
            creator_id: coverer,
            total_expense: total,
            split_method: "equally",
            receipt_url: "",
            created_at: "2026-09-01T10:00:00.000Z",
            additional_charges: [ExpenseEventAdditionalChargeBase(id: "\(id)-tax", name: "tax", amount: 10)],
            items: [ExpenseEventItemBase(
                id: "\(id)-item",
                name: "Item",
                price: total,
                quantity: 1,
                assignees: assignees.map { ExpenseItemAssigneeBase(user_id: $0, share: 1) }
            )]
        )
    }

    private func event(name: String = "Trip", participants: [UserBase], expenses: [ExpenseEventBase], completion: String? = nil) -> EventBase {
        EventBase(
            id: "event-1",
            completion_date: completion,
            name: name,
            avatar_url: "icon3",
            creator_id: "user-me",
            created_at: "2026-09-01T09:00:00.000Z",
            updated_at: nil,
            participants: participants,
            expenses: expenses
        )
    }

    private func count<T: PersistentModel>(_ type: T.Type) throws -> Int {
        try context.fetchCount(FetchDescriptor<T>())
    }

    // MARK: - insertSynced

    func testInsertSyncedBuildsFullGraph() throws {
        let base = event(
            participants: [user("user-me", name: "Me"), user("user-b", name: "Budi")],
            expenses: [expense("exp-a", name: "Dinner", coverer: "user-me", total: 100, assignees: ["user-me", "user-b"])]
        )

        let created = EventData.insertSynced(from: base, currentUser: me, in: context)
        try context.save()

        XCTAssertEqual(created.eventId, "event-1")
        XCTAssertEqual(created.eventName, "Trip")
        XCTAssertEqual(created.eventIcon, EventIconEnum.icon3.id)
        XCTAssertEqual(created.creatorId, "user-me")
        XCTAssertTrue(created.isSynced)
        XCTAssertNil(created.completionDate)

        XCTAssertEqual(created.participants.count, 2)
        // The signed-in user's existing row is reused, not duplicated.
        XCTAssertTrue(created.participants.contains { $0 === me })
        XCTAssertEqual(try count(UserData.self), 2)

        XCTAssertEqual(created.expenses.count, 1)
        let dinner = try XCTUnwrap(created.expenses.first)
        XCTAssertEqual(dinner.expenseId, "exp-a")
        XCTAssertTrue(dinner.coverer === me)
        XCTAssertTrue(dinner.creator === me)
        XCTAssertTrue(dinner.isSynced)
        XCTAssertEqual(dinner.items.count, 1)
        XCTAssertEqual(dinner.items.first?.assignees.count, 2)
        XCTAssertEqual(dinner.participants.count, 2)
        XCTAssertEqual(dinner.additionalCharges.count, 1)
        XCTAssertEqual(dinner.additionalCharges.first?.amount, 10)

        // I paid 100 and owe half → positive balance.
        XCTAssertGreaterThan(created.userEventBalance, 0)
    }

    // MARK: - apply

    func testApplyKeepsIdentityAndUpdatesHeaderFields() throws {
        let initial = event(participants: [user("user-me", name: "Me"), user("user-b", name: "Budi")], expenses: [])
        let target = EventData.insertSynced(from: initial, currentUser: me, in: context)
        try context.save()
        let budi = try XCTUnwrap(target.participants.first { $0.userId == "user-b" })

        let updated = event(
            name: "Trip (renamed)",
            participants: [user("user-me", name: "Me"), user("user-b", name: "Budi S."), user("user-c", name: "Citra")],
            expenses: [],
            completion: "2026-09-05T12:00:00.000Z"
        )
        target.apply(from: updated, currentUser: me, in: context)
        try context.save()

        XCTAssertEqual(target.eventName, "Trip (renamed)")
        XCTAssertNotNil(target.completionDate)
        XCTAssertEqual(target.participants.count, 3)
        // Existing participant row is updated in place, not replaced.
        XCTAssertTrue(target.participants.contains { $0 === budi })
        XCTAssertEqual(budi.name, "Budi S.")
        XCTAssertEqual(try count(UserData.self), 3)
    }

    func testApplyReconcilesExpensesByServerId() throws {
        let initial = event(
            participants: [user("user-me", name: "Me"), user("user-b", name: "Budi")],
            expenses: [
                expense("exp-a", name: "Dinner", coverer: "user-me", total: 100, assignees: ["user-me", "user-b"]),
                expense("exp-b", name: "Taxi", coverer: "user-b", total: 40, assignees: ["user-me", "user-b"]),
            ]
        )
        let target = EventData.insertSynced(from: initial, currentUser: me, in: context)
        try context.save()

        let dinner = try XCTUnwrap(target.expenses.first { $0.expenseId == "exp-a" })
        let oldDinnerItem = try XCTUnwrap(dinner.items.first)

        // A local create that hasn't reached the server yet.
        let pending = Expense(name: "Snacks", coverer: me, price: 15, splitMethod: .equally, participants: [me], isSynced: false)
        context.insert(pending)
        target.expenses.append(pending)
        try context.save()
        XCTAssertEqual(target.expenses.count, 3)

        // Server: Dinner changed, Taxi deleted, Brunch added.
        let updated = event(
            participants: [user("user-me", name: "Me"), user("user-b", name: "Budi")],
            expenses: [
                expense("exp-a", name: "Dinner (edited)", coverer: "user-b", total: 120, assignees: ["user-me", "user-b"]),
                expense("exp-d", name: "Brunch", coverer: "user-me", total: 60, assignees: ["user-me", "user-b"]),
            ]
        )
        target.apply(from: updated, currentUser: me, in: context)
        try context.save()

        let ids = Set(target.expenses.map { $0.expenseId ?? "pending" })
        XCTAssertEqual(ids, ["exp-a", "exp-d", "pending"])

        // Changed expense: same object, new fields, line items rebuilt.
        XCTAssertTrue(target.expenses.contains { $0 === dinner })
        XCTAssertEqual(dinner.name, "Dinner (edited)")
        XCTAssertEqual(dinner.price, 120)
        XCTAssertEqual(dinner.coverer.userId, "user-b")
        XCTAssertEqual(dinner.items.count, 1)
        XCTAssertFalse(dinner.items.contains { $0 === oldDinnerItem })

        // Unsynced local row survives the merge untouched.
        XCTAssertTrue(target.expenses.contains { $0 === pending })
        XCTAssertFalse(pending.isSynced)

        // Deleted server expense is gone from the store along with its line
        // items; no orphaned rows remain.
        XCTAssertEqual(try count(Expense.self), 3)
        XCTAssertEqual(try count(ExpenseItem.self), 2)          // Dinner + Brunch (pending has none)
        XCTAssertEqual(try count(ExpensePerson.self), 4)        // 2 assignees each
        XCTAssertEqual(try count(AdditionalCharge.self), 2)
    }

    func testApplySkipsExpenseWithUnknownCoverer() throws {
        let initial = event(participants: [user("user-me", name: "Me")], expenses: [])
        let target = EventData.insertSynced(from: initial, currentUser: me, in: context)
        try context.save()

        let updated = event(
            participants: [user("user-me", name: "Me")],
            expenses: [expense("exp-x", name: "Ghost", coverer: "user-unknown", total: 10, assignees: ["user-me"])]
        )
        target.apply(from: updated, currentUser: me, in: context)
        try context.save()

        XCTAssertTrue(target.expenses.isEmpty)
        XCTAssertEqual(try count(Expense.self), 0)
    }
}
