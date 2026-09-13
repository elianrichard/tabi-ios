//
//  SettlementCalculator.swift
//  Tabi Split
//
//  Created by Elian Richard on 13/09/26.
//

import Foundation

/// Everything derived from an event's expenses, computed in one pass by
/// `SettlementCalculator.compute`.
struct SettlementResult {
    /// One row per event participant, sorted by name, with lent/debt/balance
    /// filled and `settlement` holding the netted (fewest-transfers) plan.
    var participants: [PersonBalanceData]
    /// Raw pairwise debts (each debtor pays each coverer directly, no netting).
    /// Same row type so the recap card can reuse it; only `settlement` is set.
    var directSettlements: [PersonBalanceData]
    /// The current user's net effect per expense, newest first; expenses that
    /// net to zero for them are omitted.
    var userTransactionHistory: [SummaryHistoryData]
    /// Sum of the current user's own shares across all expenses.
    var userTotalSpending: Float
    /// Who the current user pays (debt) or waits on (credit), sorted by name.
    var userSettlementList: [SummarySettlementData]
    /// The current user's row in `participants`; nil when they're not a
    /// participant of this event.
    var userBalance: PersonBalanceData?
}

/// Single source of truth for who owes whom in an event.
///
/// Home's event card (`EventData.userEventBalance`), the Summary tab and the
/// Optimization screen all read from this. Never compute a share or balance
/// anywhere else: the card once had its own copy that pro-rated additional
/// charges without item quantity and disagreed with the summary by Rp12k.
enum SettlementCalculator {

    /// - Returns: nil when an expense references a coverer or assignee who is
    ///   not an event participant (data the app can't settle); the caller
    ///   decides how to degrade.
    static func compute(participants: [UserData], expenses: [Expense], currentUser: UserData) -> SettlementResult? {
        // "Is this the signed-in user": identity first, then userId
        // (authoritative), then email. A bare `==` only matches the same object
        // instance, which fails after a sync rebuilds UserData rows.
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

        let rows = participants
            .map { PersonBalanceData(user: $0) }
            .sorted { $0.user.name.lowercased() < $1.user.name.lowercased() }
        let rowByKey = Dictionary(uniqueKeysWithValues: rows.map { (ObjectIdentifier($0), $0) })

        // An expense can reference a *different* UserData instance than the one
        // in `participants` (same person, rebuilt after a SwiftData re-fetch),
        // so index by identity first and fall back to userId, then email.
        let byIdentity = Dictionary(rows.map { (ObjectIdentifier($0.user), $0) }, uniquingKeysWith: { first, _ in first })
        var byUserId: [String: PersonBalanceData] = [:]
        var byEmail: [String: PersonBalanceData] = [:]
        for row in rows {
            if !row.user.userId.isEmpty { byUserId[row.user.userId] = row }
            if !row.user.email.isEmpty { byEmail[row.user.email] = row }
        }
        func row(for user: UserData) -> PersonBalanceData? {
            if let hit = byIdentity[ObjectIdentifier(user)] { return hit }
            if !user.userId.isEmpty, let hit = byUserId[user.userId] { return hit }
            if !user.email.isEmpty, let hit = byEmail[user.email] { return hit }
            return nil
        }

        // Pairwise debts for the non-simplified recap: debtor row -> creditor row -> amount.
        var directDebt: [ObjectIdentifier: [ObjectIdentifier: Float]] = [:]
        var history: [SummaryHistoryData] = []
        var totalSpending: Float = 0

        for expense in expenses {
            guard let coverer = row(for: expense.coverer) else {
                return nil
            }
            let covererIsMe = isCurrentUser(expense.coverer)
            coverer.lent += expense.price
            var userDelta: Float = covererIsMe ? expense.price : 0

            /// Books `amount` owed by `buyer` to this expense's coverer.
            func book(_ amount: Float, to buyer: PersonBalanceData) {
                if covererIsMe && isCurrentUser(buyer.user) {
                    // The current user's own share of their own expense shows as
                    // less lent rather than as a debt to themselves.
                    coverer.lent -= amount
                } else {
                    buyer.debt += amount
                }
                if buyer !== coverer && amount != 0 {
                    directDebt[ObjectIdentifier(buyer), default: [:]][ObjectIdentifier(coverer), default: 0] += amount
                }
                if isCurrentUser(buyer.user) {
                    totalSpending += amount
                    userDelta -= amount
                }
            }

            switch SplitMethod(rawValue: expense.splitMethod) {
            case .custom:
                let charges = expense.additionalCharges.reduce(0) { $0 + $1.amount }
                // Denominator for pro-rating charges. Must include quantity since
                // each spend below is qty * price, or the shares over-allocate.
                let itemsTotal = expense.items.reduce(0) { $0 + $1.itemPrice * $1.itemQuantity }
                for item in expense.items {
                    let totalShares = item.assignees.reduce(0) { $0 + $1.share }
                    guard totalShares > 0 else { continue }
                    for assignee in item.assignees {
                        guard let buyer = row(for: assignee.user) else {
                            return nil
                        }
                        let spent = (assignee.share / totalShares) * item.itemQuantity * item.itemPrice
                        let extra = itemsTotal > 0 ? charges * (spent / itemsTotal) : 0
                        book((spent + extra).properRound(), to: buyer)
                    }
                }
            case .equally:
                guard !expense.participants.isEmpty else { break }
                let share = (expense.price / Float(expense.participants.count)).rounded(toDecimalPlaces: 1).properRound()
                for person in expense.participants {
                    guard let buyer = row(for: person) else {
                        return nil
                    }
                    book(share, to: buyer)
                }
            case nil:
                break
            }

            if userDelta != 0 {
                history.append(SummaryHistoryData(expenseName: expense.name, expenseDate: expense.dateOfCreation, amount: userDelta, expense: expense))
            }
        }

        let directSettlements: [PersonBalanceData] = rows.compactMap { debtor in
            guard let creditors = directDebt[ObjectIdentifier(debtor)], !creditors.isEmpty else { return nil }
            let entry = PersonBalanceData(user: debtor.user)
            entry.settlement = creditors.compactMap { key, amount -> PersonSettlementData? in
                let rounded = amount.properRound()
                guard let creditor = rowByKey[key], rounded != 0 else { return nil }
                return PersonSettlementData(userPaid: creditor.user, amount: rounded)
            }
            .sorted { $0.userPaid.name.lowercased() < $1.userPaid.name.lowercased() }
            return entry.settlement.isEmpty ? nil : entry
        }

        // Net the balances into the fewest transfers: walk debtors (largest
        // debt first) against creditors (smallest credit first).
        let debtRows = rows.filter { $0.balance < 0 }.sorted { $0.balance < $1.balance }
        let creditRows = rows.filter { $0.balance > 0 }.sorted { $0.balance < $1.balance }
        for debtor in debtRows {
            for creditor in creditRows {
                if creditor.calculationBalance <= 0 { continue }
                let sum = debtor.calculationBalance + creditor.calculationBalance
                if sum >= 0 {
                    debtor.settlement.append(PersonSettlementData(userPaid: creditor.user, amount: abs(debtor.calculationBalance)))
                    debtor.calculationBalance = 0
                    creditor.calculationBalance = sum
                    break
                } else {
                    debtor.settlement.append(PersonSettlementData(userPaid: creditor.user, amount: creditor.calculationBalance))
                    debtor.calculationBalance = sum
                    creditor.calculationBalance = 0
                }
            }
        }

        let me = rows.first { isCurrentUser($0.user) }
        var userSettlements: [SummarySettlementData] = []
        if let me {
            switch me.status {
            case .debt:
                userSettlements = me.settlement.map {
                    SummarySettlementData(targetUser: $0.userPaid, amount: $0.amount, status: .NeedPayment)
                }
            case .credit:
                for debtor in rows {
                    for settlement in debtor.settlement where isCurrentUser(settlement.userPaid) {
                        userSettlements.append(SummarySettlementData(targetUser: debtor.user, amount: settlement.amount, status: .WaitingPayment))
                    }
                }
            case .settled:
                break
            }
        }

        return SettlementResult(
            participants: rows,
            directSettlements: directSettlements,
            userTransactionHistory: history.sorted { $0.expenseDate > $1.expenseDate },
            userTotalSpending: totalSpending,
            userSettlementList: userSettlements.sorted { $0.targetUser.name.lowercased() < $1.targetUser.name.lowercased() },
            userBalance: me
        )
    }
}
