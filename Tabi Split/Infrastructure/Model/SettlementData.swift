//
//  SettlementData.swift
//  Tabi Split
//
//  Created by Elian Richard on 17/10/24.
//

import SwiftUI

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
    var balance: Float {
        didSet {
            if (balance > 0) {
                status = .credit
            } else if (balance < 0) {
                status = .debt
            } else {
                status = .settled
            }
        }
    }
    var settlement: [PersonSettlementData]
    var status: EventCardStatus
    
    init(user: UserData) {
        self.id = UUID()
        self.user = user
        self.lent = 0
        self.debt = 0
        self.calculationBalance = 0
        self.balance = 0
        self.settlement = []
        self.status = .settled
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

struct SummarySettlementData: Identifiable {
    var id: UUID = UUID()
    var targetUser: UserData
    var amount: Float
    var status: SettlementCardTypeEnum
}

enum SettlementCardTypeEnum {
    case WaitingPayment, NeedPayment, WaitingConfirmation, NeedConfirmation

    var statusColor: Color {
        switch self {
        case .WaitingPayment:
            return .buttonPurple
        case .NeedPayment:
            return .buttonRed
        case .WaitingConfirmation:
            return .buttonPurple
        case .NeedConfirmation:
            return .buttonRed
        }
    }

    var statusText: String {
        switch self {
        case .WaitingPayment:
            return "Waiting for payment"
        case .NeedPayment:
            return "Need payment"
        case .WaitingConfirmation:
            return "Waiting for confirmation"
        case .NeedConfirmation:
            return "Need confirmation"
        }
    }
    
    var actionIcon: ImageResource? {
        switch self {
        case .WaitingPayment:
            return nil
        case .NeedPayment:
            return .uploadIcon
        case .WaitingConfirmation:
            return nil
        case .NeedConfirmation:
            return nil
        }
    }

    var actionText: String {
        switch self {
        case .WaitingPayment:
            return ""
        case .NeedPayment:
            return "Upload Payment Receipt"
        case .WaitingConfirmation:
            return ""
        case .NeedConfirmation:
            return "See Payment Receipt"
        }
    }
}
