//
//  EventData.swift
//  Tabi
//
//  Created by Elian Richard on 30/09/24.
//

import SwiftData
import SwiftUI

@Model
class EventData {
    var eventName: String
    var completionDate: Date?
    var userEventBalance: Double
    var transactions: [Int]
    var participants: [String]
    
    init(eventName: String, completionDate: Date? = nil, userEventBalance: Double = 0, transactions: [Int] = [], participants: [String] = ["You"]) {
        self.eventName = eventName
        self.completionDate = completionDate
        self.userEventBalance = userEventBalance
        self.transactions = transactions
        self.participants = participants
    }
}

var mockEventData: [EventData] = [
    EventData(eventName: "Korea Trip", completionDate: nil, userEventBalance: 0, transactions: []),
    EventData(eventName: "London Trip", completionDate: Date(), userEventBalance: 300_000, transactions: [10]),
    EventData(eventName: "Paris Trip", completionDate: Date(), userEventBalance: -300_000, transactions: [10]),
    EventData(eventName: "New York Trip", completionDate: nil, userEventBalance: 0, transactions: [10])
]

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

enum EventCardStatusEnum {
    case debt
    case credit
    case settled
    
    var id: String {
        switch self {
        case .credit:
            "credit"
        case .debt:
            "debt"
        case .settled:
            "settled"
        }
    }
    
    var statusDisplay: String {
        switch self {
        case .credit:
            "Ows you"
        case .debt:
            "You owe"
        case .settled:
            "Settled"
        }
    }
    
    var statusColor: Color {
        switch self {
        case .credit:
            Color(UIColor(hex: "#CBFFCC"))
        case .debt:
            Color(UIColor(hex: "#FFCBCC"))
        case .settled:
            Color(UIColor(hex: "#B8B5B5"))
        }
    }
}
