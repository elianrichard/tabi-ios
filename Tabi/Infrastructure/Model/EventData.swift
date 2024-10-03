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
    var name: String
    
    init(name: String) {
        self.name = name
    }
}

var defaultEventData = EventData(name: "Travel")
