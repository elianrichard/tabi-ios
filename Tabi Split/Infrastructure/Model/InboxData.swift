//
//  InboxData.swift
//  Tabi Split
//
//  Created by Elian Richard on 07/11/24.
//

import SwiftUI

enum InboxTypeEnum {
    case NeedPayment, NeedConfirmation
    
    func generateText(targetUser: UserData, amount: Float?, eventName: String) -> String {
        switch self {
        case .NeedPayment:
            if let amount {
                return "You should pay Rp\(amount.formatPrice()) to \(targetUser.name.getFirstName()) for \"\(eventName)\""
            } else {
                return ""
            }
        case .NeedConfirmation:
            return "You should confirm \(targetUser.name.getFirstName())'s payment for \"\(eventName)\""
        }
    }
}

struct InboxData: Identifiable {
    var id: UUID = UUID()
    var type: InboxTypeEnum
    var targetUser: UserData
    var eventName: String
    var dateTime: Date
    var isUnread: Bool = false
    var amount: Float?
}
