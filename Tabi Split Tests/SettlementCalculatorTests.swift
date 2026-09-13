//
//  SettlementCalculatorTests.swift
//  Tabi Split Tests
//
//  Created by Elian Richard on 13/09/26.
//

import XCTest
import SwiftData
@testable import Tabi_Split

/// The single settlement engine behind Home's event card, the Summary tab and
/// the Optimization screen (SettlementCalculator.swift).
@MainActor
final class SettlementCalculatorTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var me: UserData!
    private var arief: UserData!
    private var eric: UserData!

    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: EventData.self, UserData.self, configurations: config)
        context = ModelContext(container)
        context.autosaveEnabled = false
        me = user("me", "Me")
        arief = user("arief", "Arief")
        eric = user("eric", "Eric")
    }

    override func tearDown() async throws {
        context = nil
        container = nil
    }

    // MARK: - Fixtures

    private func user(_ id: String, _ name: String) -> UserData {
        let user = UserData(userId: id, name: name, email: "\(id)@example.com", kind: "real", image: .owl)
        context.insert(user)
        return user
    }

    private func item(_ name: String, price: Float, qty: Float, among assignees: [UserData]) -> ExpenseItem {
        ExpenseItem(itemName: name, itemPrice: price, itemQuantity: qty, assignees: assignees.map { ExpensePerson(user: $0, share: 1) })
    }

    /// Custom split; `price` is items (qty * price) plus `charges`, like the server sends.
    private func customExpense(_ name: String, coverer: UserData, items: [ExpenseItem], charges: Float, date: Date = Date()) -> Expense {
        let itemsTotal = items.reduce(0) { $0 + $1.itemPrice * $1.itemQuantity }
        var participants: [UserData] = []
        for item in items {
            for assignee in item.assignees where !participants.contains(where: { $0 === assignee.user }) {
                participants.append(assignee.user)
            }
        }
        let expense = Expense(
            name: name, coverer: coverer, dateOfCreation: date, price: itemsTotal + charges, splitMethod: .custom,
            participants: participants, items: items,
            additionalCharges: charges > 0
                ? [AdditionalCharge(additionalChargeBase: ExpenseEventAdditionalChargeBase(id: "\(name)-tax", name: "tax", amount: charges))]
                : []
        )
        context.insert(expense)
        return expense
    }

    private func equalExpense(_ name: String, coverer: UserData, price: Float, among participants: [UserData], date: Date = Date()) -> Expense {
        let expense = Expense(name: name, coverer: coverer, dateOfCreation: date, price: price, splitMethod: .equally, participants: participants)
        context.insert(expense)
        return expense
    }

    private func compute(_ expenses: [Expense], participants: [UserData]? = nil, as current: UserData? = nil) throws -> SettlementResult {
        try XCTUnwrap(SettlementCalculator.compute(participants: participants ?? [me, arief, eric], expenses: expenses, currentUser: current ?? me))
    }

    private func row(_ result: SettlementResult, _ user: UserData) throws -> PersonBalanceData {
        try XCTUnwrap(result.participants.first { $0.user === user })
    }

    // MARK: - Shares

    /// Regression for the Home-card drift: additional charges are pro-rated over
    /// qty * price, so a qty-3 item doesn't soak up three times its share of tax.
    func testCustomSplitProRatesChargesOverQuantityAndSumsToPrice() throws {
        // 3 x 22,727 shared by all three (one each) + 20,909 for Arief alone; 8,910 tax.
        let expense = customExpense("Dartoyo kopi", coverer: me, items: [
            item("Es Kopi Susu", price: 22_727, qty: 3, among: [me, arief, eric]),
            item("Croffle", price: 20_909, qty: 1, among: [arief]),
        ], charges: 8_910)
        XCTAssertEqual(expense.price, 98_000)

        let result = try compute([expense])

        // Each coffee carries 22,727 / 89,090 of the tax = 2,273 -> 25,000 per person.
        XCTAssertEqual(try row(result, eric).debt, 25_000)
        XCTAssertEqual(try row(result, arief).debt, 25_000 + 23_000)
        // Coverer's own share reduces what they lent instead of appearing as debt.
        XCTAssertEqual(try row(result, me).debt, 0)
        XCTAssertEqual(try row(result, me).balance, 98_000 - 25_000)
        XCTAssertEqual(result.userTotalSpending, 25_000)

        let total = result.participants.reduce(Float(0)) { $0 + $1.balance }
        XCTAssertEqual(total, 0, accuracy: 1)
    }

    func testEqualSplitBalancesConserveAndBuildPaymentList() throws {
        let expense = equalExpense("Bensin", coverer: arief, price: 300_000, among: [me, arief, eric])

        let result = try compute([expense])

        XCTAssertEqual(try row(result, arief).balance, 200_000)
        XCTAssertEqual(try row(result, me).balance, -100_000)
        XCTAssertEqual(try row(result, eric).balance, -100_000)
        XCTAssertEqual(result.userBalance?.status, .debt)

        XCTAssertEqual(result.userTransactionHistory.map(\.amount), [-100_000])
        XCTAssertEqual(result.userSettlementList.count, 1)
        XCTAssertEqual(result.userSettlementList.first?.targetUser, arief)
        XCTAssertEqual(result.userSettlementList.first?.amount, 100_000)
        XCTAssertEqual(result.userSettlementList.first?.status, .NeedPayment)
    }

    /// A creditor's "waiting for payment" list must only carry transfers to
    /// them, not everything their debtor owes other people.
    func testCreditSettlementListOnlyIncludesTransfersToCurrentUser() throws {
        let expenses = [
            equalExpense("Dinner", coverer: me, price: 300_000, among: [me, eric]),
            equalExpense("Taxi", coverer: arief, price: 200_000, among: [arief, eric]),
        ]

        let result = try compute(expenses)

        XCTAssertEqual(try row(result, eric).balance, -250_000)
        XCTAssertEqual(try row(result, eric).settlement.count, 2)
        XCTAssertEqual(result.userBalance?.status, .credit)
        XCTAssertEqual(result.userSettlementList.count, 1)
        XCTAssertEqual(result.userSettlementList.first?.targetUser, eric)
        XCTAssertEqual(result.userSettlementList.first?.amount, 150_000)
        XCTAssertEqual(result.userSettlementList.first?.status, .WaitingPayment)
    }

    func testDirectSettlementsListEveryPairwiseDebtWithoutNetting() throws {
        let expenses = [
            equalExpense("Dinner", coverer: me, price: 300_000, among: [me, eric]),
            equalExpense("Taxi", coverer: arief, price: 200_000, among: [arief, eric]),
        ]

        let result = try compute(expenses)

        let ericDirect = try XCTUnwrap(result.directSettlements.first { $0.user === eric })
        XCTAssertEqual(ericDirect.settlement.map { $0.userPaid }, [arief, me])
        XCTAssertEqual(ericDirect.settlement.map(\.amount), [100_000, 150_000])
        XCTAssertNil(result.directSettlements.first { $0.user === me })
    }

    // MARK: - Callers agree

    /// Home's card balance is produced by the same engine as the summary.
    func testEventDataBalanceMatchesEngine() throws {
        let expenses = [
            customExpense("Dartoyo kopi", coverer: me, items: [
                item("Es Kopi Susu", price: 22_727, qty: 3, among: [me, arief, eric]),
            ], charges: 8_910),
            equalExpense("Bensin", coverer: arief, price: 400_000, among: [me, arief, eric]),
        ]
        let event = EventData(eventName: "Bandung", participants: [me, arief, eric], expenses: expenses, creatorId: arief.userId)
        context.insert(event)

        event.calculateUserEventBalance(currentUser: me)

        let engine = try compute(expenses)
        XCTAssertEqual(event.userEventBalance, engine.userBalance?.balance)
        XCTAssertNotEqual(event.userEventBalance, 0)
    }

    func testCurrentUserNotAParticipantHasNoBalanceRow() throws {
        let outsider = user("outsider", "Outsider")
        let expense = equalExpense("Bensin", coverer: arief, price: 300_000, among: [me, arief, eric])

        let result = try compute([expense], as: outsider)

        XCTAssertNil(result.userBalance)
        XCTAssertTrue(result.userSettlementList.isEmpty)
        XCTAssertTrue(result.userTransactionHistory.isEmpty)
    }

    func testCovererOutsideParticipantsReturnsNil() {
        let ghost = user("ghost", "Ghost")
        let expense = equalExpense("Bensin", coverer: ghost, price: 300_000, among: [me, arief])

        XCTAssertNil(SettlementCalculator.compute(participants: [me, arief, eric], expenses: [expense], currentUser: me))
    }
}
