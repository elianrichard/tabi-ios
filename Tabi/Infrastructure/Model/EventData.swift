//
//  EventData.swift
//  Tabi
//
//  Created by Elian Richard on 30/09/24.
//

import Foundation
import SwiftData

@Model
class EventData {
    var eventName: String
    var completionDate: Date?
    var userEventBalance: Double
    var transactions: [Int]
    
    init(eventName: String, completionDate: Date? = nil, userEventBalance: Double, transactions: [Int] = []) {
        self.eventName = eventName
        self.completionDate = completionDate
        self.userEventBalance = userEventBalance
        self.transactions = transactions
    }
}

var mockEventData: [EventData] = [
    EventData(eventName: "Korea Trip", completionDate: nil, userEventBalance: 0, transactions: []),
    EventData(eventName: "London Trip", completionDate: Date(), userEventBalance: 300_000, transactions: [10]),
    EventData(eventName: "Paris Trip", completionDate: Date(), userEventBalance: -300_000, transactions: [10]),
    EventData(eventName: "New York Trip", completionDate: nil, userEventBalance: 0, transactions: [10])
]
