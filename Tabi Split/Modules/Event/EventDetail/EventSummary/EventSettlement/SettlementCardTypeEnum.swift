//
//  SettlementCardTypeEnum.swift
//  Tabi Split
//
//  Created by Elian Richard on 16/10/24.
//

import SwiftUI

enum SettlementCardTypeEnum {
    case WaitingPayment, NeedPayment, WaitingConfirmation, NeedConfirmation

    var statusColor: Color {
        switch self {
        case .WaitingPayment:
            return .purple
        case .NeedPayment:
            return .red
        case .WaitingConfirmation:
            return .purple
        case .NeedConfirmation:
            return .red
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
    
    var actionIcon: String {
        switch self {
        case .WaitingPayment:
            return ""
        case .NeedPayment:
            return "square.and.arrow.up"
        case .WaitingConfirmation:
            return ""
        case .NeedConfirmation:
            return "checkmark.circle"
        }
    }

    var actionText: String {
        switch self {
        case .WaitingPayment:
            return ""
        case .NeedPayment:
            return "Upload payment receipt"
        case .WaitingConfirmation:
            return ""
        case .NeedConfirmation:
            return "Confirm payment"
        }
    }
}
