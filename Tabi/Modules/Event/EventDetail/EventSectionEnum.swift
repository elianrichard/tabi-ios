//
//  EventSectionModel.swift
//  Tabi
//
//  Created by Elian Richard on 07/10/24.
//

enum EventSectionEnum: Identifiable {
    case expenses
    case totals
    
    var id: String {
        switch self {
        case .expenses:
            "expenses"
        case .totals:
            "totals"
        }
    }
    
    var displayName: String {
        switch self {
        case .expenses:
            "Expenses"
        case .totals:
            "Totals"
        }
    }
    
    static var allCases: [EventSectionEnum] {
        [.expenses, .totals]
    }
}
