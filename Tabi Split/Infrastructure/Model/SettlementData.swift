//
//  SettlementData.swift
//  Tabi Split
//
//  Created by Elian Richard on 17/10/24.
//

import Foundation

class PersonBalanceData: Identifiable {
    var id: UUID
    var user: UserData
    var lent: Float {
        didSet {
            balance = lent - debt
            calculationBalance = balance
        }
    }
    var debt: Float {
        didSet {
            balance = lent - debt
            calculationBalance = balance
        }
    }
    var calculationBalance: Float
    var balance: Float
    var settlement: [PersonSettlementData]
    
    init(user: UserData) {
        self.id = UUID()
        self.user = user
        self.lent = 0
        self.debt = 0
        self.calculationBalance = 0
        self.balance = 0
        self.settlement = []
    }
}

struct PersonSettlementData: Identifiable {
    var id: UUID = UUID()
    var userPaid: UserData
    var amount: Float
}

struct SummaryHistoryData: Identifiable {
    var id: UUID = UUID()
    var expenseName: String
    var expenseDate: Date
    var amount: Float
}

struct OptimizationPersonData: Identifiable {
    var id: UUID = UUID()
    var user: UserData
    var debtAmount: Float
    var lentAmount: Float
}

struct OptimizationRecapData: Identifiable {
    var id: UUID = UUID()
    var sender: UserData
    var recipient: UserData
    var amount: Float
}
