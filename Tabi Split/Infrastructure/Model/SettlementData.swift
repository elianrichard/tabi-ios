//
//  SettlementData.swift
//  Tabi Split
//
//  Created by Elian Richard on 17/10/24.
//

import Foundation

struct OptimizationPersonData: Identifiable {
    var id: UUID
    var user: UserData
    var debtAmount: Float
    var lentAmount: Float
    
    init(id: UUID = UUID(), user: UserData, debtAmount: Float, lentAmount: Float) {
        self.id = id
        self.user = user
        self.debtAmount = debtAmount
        self.lentAmount = lentAmount
    }
}

struct OptimizationRecapData: Identifiable {
    var id: UUID
    var sender: UserData
    var recipient: UserData
    var amount: Float
    
    init(id: UUID = UUID(), sender: UserData, recipient: UserData, amount: Float) {
        self.id = id
        self.sender = sender
        self.recipient = recipient
        self.amount = amount
    }
}
