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
    var isCompleted: Bool
    var userEventBalance: Float
    
    init(eventName: String, isCompleted: Bool, userEventBalance: Float) {
        self.eventName = eventName
        self.isCompleted = isCompleted
        self.userEventBalance = userEventBalance
    }
}
