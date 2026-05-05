//
//  ExpenseSwiftData.swift
//  Tabi Split
//
//  Created by Elian Richard on 15/10/24.
//

import Foundation
import SwiftData

extension SwiftDataService {
    @MainActor
    func addExpenseToEvent(_ event: EventData, _ expense: Expense) {
        let events = fetchAllEvents() ?? []
        if let targetEvent = events.first(where: { $0 == event }) {
            targetEvent.expenses.append(expense)
        }
        saveModelContext()
    }

    @MainActor
    func deleteAllExpenses() {
        deleteModelContext(type: Expense.self)
    }
}
