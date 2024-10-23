//
//  SettlementData.swift
//  Tabi Split
//
//  Created by Elian Richard on 17/10/24.
//

import Foundation

struct OptimizationPersonData: Identifiable {
    var id: UUID
    var name: String
    var debtAmount: Float
    var lentAmount: Float
    
    init(id: UUID = UUID(), name: String, debtAmount: Float, lentAmount: Float) {
        self.id = id
        self.name = name
        self.debtAmount = debtAmount
        self.lentAmount = lentAmount
    }
}

struct OptimizationRecapData: Identifiable {
    var id: UUID
    var sender: String
    var recipient: String
    var amount: Float
    
    init(id: UUID = UUID(), sender: String, recipient: String, amount: Float) {
        self.id = id
        self.sender = sender
        self.recipient = recipient
        self.amount = amount
    }
}
