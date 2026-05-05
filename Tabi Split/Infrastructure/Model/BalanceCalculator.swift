//
//  BalanceCalculator.swift
//  Tabi Split
//

import Foundation

enum BalanceCalculator {

    // Returns the net balance for a single user across all expenses in an event.
    // Positive = they are owed money; negative = they owe money.
    static func userBalance(for user: UserData, in expenses: [Expense]) -> Float {
        var balance: Float = 0
        for expense in expenses {
            if expense.coverer == user {
                balance += expense.price
            }
            balance -= debtAmount(for: user, in: expense)
        }
        return balance
    }

    // Returns the amount a specific user owes for a single expense.
    static func debtAmount(for user: UserData, in expense: Expense) -> Float {
        if expense.splitMethod == SplitMethod.custom.id {
            return customSplitDebt(for: user, in: expense)
        } else if expense.splitMethod == SplitMethod.equally.id {
            guard expense.participants.contains(where: { $0 == user }) else { return 0 }
            return Float(expense.price / Float(expense.participants.count))
                .rounded(toDecimalPlaces: 1)
                .properRound()
        }
        return 0
    }

    // Full optimization: returns per-participant balances and settlement pairs.
    static func optimize(
        participants: [PersonBalanceData],
        expenses: [Expense],
        currentUser: UserData
    ) -> (history: [SummaryHistoryData], totalSpending: Float) {
        var history: [SummaryHistoryData] = []
        var totalSpending: Float = 0

        for expense in expenses {
            var userNetForExpense: Float = 0

            guard let payer = participants.first(where: { $0.user == expense.coverer }) else { continue }
            payer.lent += expense.price

            if expense.coverer == currentUser {
                userNetForExpense += expense.price
            }

            if expense.splitMethod == SplitMethod.custom.id {
                let totalAdditional = expense.additionalCharges.reduce(0) { $0 + $1.amount }
                let itemTotal = expense.items.reduce(0) { $0 + $1.itemPrice }

                for item in expense.items {
                    let totalShares = item.assignees.reduce(0) { $0 + $1.share }
                    for assignee in item.assignees {
                        guard let buyer = participants.first(where: { $0.user == assignee.user }),
                              totalShares > 0 else { continue }
                        let qty = (assignee.share / totalShares) * item.itemQuantity
                        let spent = qty * item.itemPrice
                        let additional = itemTotal > 0 ? totalAdditional * (spent / itemTotal) : 0
                        let debt = Float(spent + additional).properRound()

                        if expense.coverer == currentUser && buyer.user == currentUser {
                            payer.lent -= debt
                        } else {
                            buyer.debt += debt
                        }
                        if assignee.user == currentUser {
                            totalSpending += debt
                            userNetForExpense -= debt
                        }
                    }
                }
            } else if expense.splitMethod == SplitMethod.equally.id {
                let debt = Float(expense.price / Float(expense.participants.count))
                    .rounded(toDecimalPlaces: 1)
                    .properRound()
                for person in expense.participants {
                    guard let buyer = participants.first(where: { $0.user == person }) else { continue }
                    if expense.coverer == currentUser && buyer.user == currentUser {
                        payer.lent -= debt
                    } else {
                        buyer.debt += debt
                    }
                    if person == currentUser {
                        totalSpending += debt
                        userNetForExpense -= debt
                    }
                }
            }

            if userNetForExpense != 0 {
                history.append(SummaryHistoryData(
                    expenseName: expense.name,
                    expenseDate: expense.dateOfCreation,
                    amount: userNetForExpense
                ))
            }
        }

        // Resolve debts between participants
        let debtors = participants.filter { $0.balance < 0 }.sorted { $0.balance < $1.balance }
        let creditors = participants.filter { $0.balance > 0 }.sorted { $0.balance < $1.balance }

        for debtor in debtors {
            for creditor in creditors {
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

        return (history: history.sorted { $0.expenseDate > $1.expenseDate }, totalSpending: totalSpending)
    }

    private static func customSplitDebt(for user: UserData, in expense: Expense) -> Float {
        let totalAdditional = expense.additionalCharges.reduce(0) { $0 + $1.amount }
        let itemTotal = expense.items.reduce(0) { $0 + $1.itemPrice }
        var total: Float = 0
        for item in expense.items {
            let totalShares = item.assignees.reduce(0) { $0 + $1.share }
            guard let assignee = item.assignees.first(where: { $0.user == user }),
                  totalShares > 0 else { continue }
            let qty = (assignee.share / totalShares) * item.itemQuantity
            let spent = qty * item.itemPrice
            let additional = itemTotal > 0 ? totalAdditional * (spent / itemTotal) : 0
            total += Float(spent + additional).properRound()
        }
        return total
    }
}
