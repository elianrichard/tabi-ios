//
//  StoreMigrationTests.swift
//  Tabi Split Tests
//
//  Opens SwiftData stores written by PREVIOUS RELEASES with the current schema.
//  A failure here is exactly the launch crash users hit after updating the app
//  (1.1.8 → 1.2.0 crashed because `UserData.phone` became a mandatory `email`
//  with no default, which lightweight migration cannot add to existing rows).
//
//  Fixtures: `Tabi Split Tests/Fixtures/store-v<version>/default.store`, see the
//  README there and docs/adr/0001-swiftdata-schema-migration.md.
//

import XCTest
import SwiftData
@testable import Tabi_Split

@MainActor
final class StoreMigrationTests: XCTestCase {

    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: - v1.1.5 … v1.1.8 (phone-based UserData; no kind / creator / receiptId)

    func testOpensStoreFromV1_1_5() throws {
        let url = try copyFixture("store-v1.1.5")

        // This line is the migration assertion: it throws when lightweight migration fails.
        let container = try TabiSchema.makeContainer(at: url)
        let ctx = ModelContext(container)

        let users = try ctx.fetch(FetchDescriptor<UserData>())
        XCTAssertEqual(users.count, 4)
        XCTAssertTrue(users.allSatisfy { $0.email == "" }, "dropped `phone` values must not leak into `email`")
        XCTAssertTrue(users.allSatisfy { $0.kind == "dummy" })
        XCTAssertEqual(users.first { $0.userId == "user-me" }?.name, "Me")

        let events = try ctx.fetch(FetchDescriptor<EventData>())
        XCTAssertEqual(events.count, 2)
        let trip = try XCTUnwrap(events.first { $0.eventId == "event-1" })
        XCTAssertEqual(trip.participants.count, 3)
        XCTAssertEqual(trip.expenses.count, 3)
        XCTAssertEqual(trip.creatorId, "user-me")

        let expenses = try ctx.fetch(FetchDescriptor<Expense>())
        XCTAssertEqual(expenses.count, 3)
        XCTAssertTrue(expenses.allSatisfy { $0.creator == nil && $0.receiptId == nil })
        let dinner = try XCTUnwrap(expenses.first { $0.expenseId == "exp-1" })
        XCTAssertEqual(dinner.coverer.userId, "user-me")
        XCTAssertEqual(dinner.participants.count, 2)
        XCTAssertEqual(dinner.items.count, 1)
        XCTAssertEqual(dinner.items.first?.assignees.count, 2)
        XCTAssertEqual(dinner.additionalCharges.count, 1)
        XCTAssertEqual(expenses.filter { !$0.isSynced }.count, 1, "unsynced local rows survive")

        XCTAssertEqual(try ctx.fetch(FetchDescriptor<ExpenseItem>()).count, 1)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<ExpensePerson>()).count, 2)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<AdditionalCharge>()).count, 1)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<NoteData>()).count, 1)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Author>()).count, 1)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<SubNote>()).count, 1)

        // Migrated rows must be writable through the current code paths.
        let me = try XCTUnwrap(users.first { $0.userId == "user-me" })
        trip.calculateUserEventBalance(currentUser: me)
        me.email = "me@example.com"
        me.kind = "real"
        try ctx.save()

        // And readable again by a second container on the same file.
        let reopened = ModelContext(try TabiSchema.makeContainer(at: url))
        XCTAssertEqual(try reopened.fetch(FetchDescriptor<UserData>()).first { $0.userId == "user-me" }?.email, "me@example.com")
    }

    // MARK: - Fresh store

    func testOpensFreshStore() throws {
        let container = try TabiSchema.makeContainer(at: tempDir.appendingPathComponent("default.store"))
        XCTAssertNoThrow(try ModelContext(container).fetch(FetchDescriptor<UserData>()))
    }

    // MARK: - Recovery (the never-crash-at-launch guarantee)

    func testLoadOrRecoverOpensHealthyStoreWithoutTouchingIt() throws {
        let url = try copyFixture("store-v1.1.5")
        let (_, result) = TabiSchema.loadOrRecover(at: url)
        XCTAssertEqual(result, .opened)
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("Recovery").path))
    }

    func testLoadOrRecoverMovesUnreadableStoreAside() throws {
        let url = tempDir.appendingPathComponent("default.store")
        try Data("this is not a sqlite database".utf8).write(to: url)
        try Data("garbage".utf8).write(to: URL(fileURLWithPath: url.path + "-wal"))

        let (container, result) = TabiSchema.loadOrRecover(at: url)
        guard case .recovered(let movedTo) = result else {
            return XCTFail("expected .recovered, got \(result)")
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: movedTo.appendingPathComponent("default.store").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: movedTo.appendingPathComponent("default.store-wal").path))
        XCTAssertEqual(movedTo.deletingLastPathComponent().lastPathComponent, "Recovery")

        // The fresh store at the original URL works.
        let ctx = ModelContext(container)
        ctx.insert(UserData(userId: "u", name: "U", email: "u@example.com"))
        try ctx.save()
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<UserData>()).count, 1)
    }

    func testMoveStoreAsideKeepsOnlyTwoRecoveryFolders() throws {
        let url = tempDir.appendingPathComponent("default.store")
        for i in 0..<4 {
            try Data("v\(i)".utf8).write(to: url)
            XCTAssertNotNil(TabiSchema.moveStoreAside(at: url))
            // Distinct timestamps (second resolution).
            Thread.sleep(forTimeInterval: 1.05)
        }
        let folders = try FileManager.default.contentsOfDirectory(atPath: tempDir.appendingPathComponent("Recovery").path)
        XCTAssertEqual(folders.count, 2)
    }

    // MARK: - Fixture generation (manual, run before each App Store release)

    /// Writes `Fixtures/store-v<MARKETING_VERSION>/default.store` for the CURRENT
    /// schema so the next schema change is tested against what users actually have.
    /// See `Tabi Split Tests/Fixtures/README.md` for the exact command.
    func testGenerateFixtureForCurrentSchema() throws {
        let env = ProcessInfo.processInfo.environment
        try XCTSkipUnless(env["TABI_GENERATE_FIXTURE"] == "1", "manual: set TEST_RUNNER_TABI_GENERATE_FIXTURE=1")
        let fixturesDir = try XCTUnwrap(env["TABI_FIXTURE_DIR"], "set TEST_RUNNER_TABI_FIXTURE_DIR to the Fixtures folder")
        let version = try XCTUnwrap(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)

        let dir = URL(fileURLWithPath: fixturesDir).appendingPathComponent("store-v\(version)", isDirectory: true)
        try? FileManager.default.removeItem(at: dir)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("default.store")

        let container = try TabiSchema.makeContainer(at: url)
        let ctx = ModelContext(container)
        ctx.autosaveEnabled = false
        StoreFixtureSeed.seedEveryEntity(in: ctx)
        try ctx.save()
        print("Wrote fixture: \(url.path) — commit the folder (default.store plus any -wal/-shm files).")
    }

    // MARK: - Helpers

    private func copyFixture(_ name: String) throws -> URL {
        let bundle = Bundle(for: Self.self)
        let src = try XCTUnwrap(
            bundle.url(forResource: "default", withExtension: "store", subdirectory: "Fixtures/\(name)"),
            "Missing fixture Fixtures/\(name)/default.store in the test bundle (project.yml adds the folder as a resource)"
        )
        let dst = tempDir.appendingPathComponent("default.store")
        try FileManager.default.copyItem(at: src, to: dst)
        for suffix in ["-wal", "-shm"] {
            let side = URL(fileURLWithPath: src.path + suffix)
            if FileManager.default.fileExists(atPath: side.path) {
                try FileManager.default.copyItem(at: side, to: URL(fileURLWithPath: dst.path + suffix))
            }
        }
        return dst
    }
}

/// Sample rows for EVERY @Model, using the current initializers. Keep one row per
/// entity: mandatory-attribute migration failures only surface on existing rows.
enum StoreFixtureSeed {
    @MainActor
    static func seedEveryEntity(in ctx: ModelContext) {
        let me = UserData(userId: "user-me", name: "Me", email: "me@example.com", kind: "real", image: .owl)
        let friend = UserData(userId: "user-friend", name: "Friend", email: "friend@example.com", kind: "real", image: .dragon)
        let dummy = UserData(userId: "user-dummy", name: "Dummy", email: "", kind: "dummy", image: .wallet)
        let guest = UserData(userId: "user-guest", name: "Guest", email: "", kind: "guest", image: .octopus)
        for user in [me, friend, dummy, guest] { ctx.insert(user) }

        let p1 = ExpensePerson(user: me, share: 1)
        let p2 = ExpensePerson(user: friend, share: 1)
        let item = ExpenseItem(itemId: "item-1", itemName: "Chicken", itemPrice: 50000, itemQuantity: 2, assignees: [p1, p2])
        let charge = AdditionalCharge(additionalChargeId: "charge-1", additionalChargeType: .tax, amount: 5000)
        let custom = Expense(expenseId: "exp-1", name: "Dinner", coverer: me, creator: me, price: 105000, splitMethod: .custom,
                             participants: [me, friend], receiptId: "receipt-1", items: [item], additionalCharges: [charge], isSynced: true)
        let equal = Expense(expenseId: "exp-2", name: "Taxi", coverer: friend, price: 40000, splitMethod: .equally,
                            participants: [me, friend], isSynced: true)
        ctx.insert(p1); ctx.insert(p2); ctx.insert(item); ctx.insert(charge); ctx.insert(custom); ctx.insert(equal)

        let trip = EventData(eventId: "event-1", eventName: "Bali Trip", eventIcon: .icon2, participants: [me, friend, dummy, guest],
                             expenses: [custom, equal], creatorId: "user-me", isSynced: true)
        let done = EventData(eventId: "event-2", eventName: "Done Trip", completionDate: Date(), eventIcon: .icon5,
                             participants: [me, friend], creatorId: "user-friend", isSynced: true)
        ctx.insert(trip); ctx.insert(done)

        let author = Author(name: "Author", age: 30)
        let sub = SubNote(name: "Sub", authors: [author], subNoteDescription: "desc")
        let note = NoteData(name: "Note", authors: [author], subNotes: [sub])
        ctx.insert(author); ctx.insert(sub); ctx.insert(note)
    }
}
