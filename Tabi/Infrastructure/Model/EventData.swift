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
    var userEventBalance: Float
    var transactions: [Int]
    
    init(eventName: String, completionDate: Date? = nil, userEventBalance: Float, transactions: [Int] = []) {
        self.eventName = eventName
        self.completionDate = completionDate
        self.userEventBalance = userEventBalance
        self.transactions = transactions
    }
}
