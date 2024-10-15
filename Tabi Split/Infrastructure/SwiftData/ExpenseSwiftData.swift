//
//  ExpenseSwiftData.swift
//  Tabi Split
//
//  Created by Elian Richard on 15/10/24.
//


import Foundation
import SwiftData

extension SwiftDataService {
    func addExpenseToEvent (_ event: EventData, _ expense: Expense) {
        let events = fetchAllEvents() ?? []
        if let targetEvent = events.first(where: { $0 == event }) {
            print("new participants", expense.participants)
//            print("events", targetEvent.)
            targetEvent.expenses.append(expense)
        }
        saveModelContext()
    }
    
    func fetchAllExpense (_ event: EventData) -> [Expense] {
        let events = fetchAllEvents() ?? []
        if let targetEvent = events.first(where: { $0 == event }) {
            return targetEvent.expenses
        } else {
            return []
        }
    }
}
