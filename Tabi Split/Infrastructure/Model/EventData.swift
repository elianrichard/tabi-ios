//
//  EventData.swift
//  Tabi
//
//  Created by Elian Richard on 30/09/24.
//

import SwiftData
import SwiftUI

@Model
class EventData {
    var eventId: String?
    var eventName: String
    var completionDate: Date?
    var eventIcon: EventIconEnum.ID
    var userEventBalance: Float
    var participants: [UserData]
    @Relationship(deleteRule: .nullify, inverse: \Expense.event) var expenses: [Expense]
    var createdAt: Date
    var creatorId: String = ""
    
    init(eventId: String? = nil, eventName: String, completionDate: Date? = nil, eventIcon: EventIconEnum = .icon1, userEventBalance: Float = 0, participants: [UserData] = [], expenses: [Expense] = [], createdAt: Date? = nil, creatorId: String) {
        self.eventId = eventId
        self.eventName = eventName
        self.completionDate = completionDate
        self.eventIcon = eventIcon.id
        self.userEventBalance = userEventBalance
        self.participants = participants
        self.expenses = expenses
        self.createdAt = createdAt ?? Date()
        self.creatorId = creatorId
    }
    
    func calculateUserEventBalance(currentUser: UserData) {
        self.userEventBalance = BalanceCalculator.userBalance(for: currentUser, in: self.expenses)
    }
}

enum EventIconEnum: String, Identifiable, CaseIterable {
    case icon1, icon2, icon3, icon4, icon5, icon6, icon7,icon8
    
    var id: String { rawValue }
    
    var resource: ImageResource {
        switch self {
        case .icon1:
                .eventIcon1
        case .icon2:
                .eventIcon2
        case .icon3:
                .eventIcon3
        case .icon4:
                .eventIcon4
        case .icon5:
                .eventIcon5
        case .icon6:
                .eventIcon6
        case .icon7:
                .eventIcon7
        case .icon8:
                .eventIcon8
        }
    }
    
    var bannerResource: ImageResource {
        switch self {
        case .icon1:
                .eventBanner1
        case .icon2:
                .eventBanner2
        case .icon3:
                .eventBanner3
        case .icon4:
                .eventBanner1
        case .icon5:
                .eventBanner1
        case .icon6:
                .eventBanner2
        case .icon7:
                .eventBanner3
        case .icon8:
                .eventBanner2
        }
    }
    
}

enum EventSection: String, Identifiable, CaseIterable {
    case expenses
    case summary
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .expenses:
            "Expenses"
        case .summary:
            "Summary"
        }
    }
    
}

enum EventCardStatus: String {
    case debt
    case credit
    case settled
    
    var id: String { rawValue }
    
    var statusDisplay: String {
        switch self {
        case .credit:
            "Receive"
        case .debt:
            "Pay"
        case .settled:
            "Settled"
        }
    }
    
    var statusColor: Color {
        switch self {
        case .credit:
                .highlightGreen
        case .debt:
                .highlightRed
        case .settled:
                .uiWhite
        }
    }
    
    var summaryCardText: String {
        switch self {
        case .credit:
            "You Should Recieve"
        case .debt:
            "You Should Pay"
        case .settled:
            "You are all Settled!"
        }
    }
    
    var summaryCardBgColor: Color {
        switch self {
        case .credit:
                .buttonGreen
        case .debt:
                .buttonRed
        case .settled:
                .uiWhite
        }
    }
    
    var summaryCardBgShadow: Color {
        switch self {
        case .credit:
                .buttonGreenShadow
        case .debt:
                .buttonRedShadow
        case .settled:
                .uiGray
        }
    }
}
