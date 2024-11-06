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
