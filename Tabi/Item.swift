//
//  Item.swift
//  Tabi
//
//  Created by Elian Richard on 19/09/24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
