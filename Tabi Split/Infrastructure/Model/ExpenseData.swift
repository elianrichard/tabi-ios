//
//  Models.swift
//  Tabi
//
//  Created by Dharmawan Ruslan on 03/10/24.
//

import SwiftData
import SwiftUI

@Model
class Expense {
    var event: EventData?
    var name: String
    var coverer: UserData
    var dateOfCreation: Date
    var price: Float
    var splitMethod: SplitMethod.ID
    var participants: [UserData]
    @Relationship(deleteRule: .cascade, inverse: \ExpenseItem.expense) var items: [ExpenseItem]
    @Relationship(deleteRule: .cascade, inverse: \AdditionalCharge.expense) var additionalCharges: [AdditionalCharge]
    
    init(name: String, coverer: UserData, dateOfCreation: Date? = nil, price: Float, splitMethod: SplitMethod, participants: [UserData] = [], items: [ExpenseItem] = [], additionalCharges: [AdditionalCharge] = []) {
        self.name = name
        self.coverer = coverer
        self.dateOfCreation = dateOfCreation ?? Date()
        self.price = price
        self.splitMethod = splitMethod.id
        self.participants = participants
        self.items = items
        self.additionalCharges = additionalCharges
    }
}

// List of expense item, e.g. Chicken, Rice, etc.
@Model
class ExpenseItem {
    var itemName: String
    var itemPrice: Float
    var itemQuantity: Float
    @Relationship(deleteRule: .cascade, inverse: \ExpensePerson.expenseItem) var assignees: [ExpensePerson]
    var expense: Expense?
    
    init(itemName: String, itemPrice: Float, itemQuantity: Float, assignees: [ExpensePerson] = []) {
        self.itemName = itemName
        self.itemPrice = itemPrice
        self.itemQuantity = itemQuantity
        self.assignees = assignees
    }
}

@Model
class ExpensePerson {
    var user: UserData
    var share: Float
    var expenseItem: ExpenseItem?
    
    init(user: UserData, share: Float = 0) {
        self.user = user
        self.share = share
    }
}

@Model
class AdditionalCharge {
    var additionalChargeType: AdditionalChargeType.ID
    var amount: Float
    var expense: Expense?
    
    init(additionalChargeType: AdditionalChargeType, amount: Float) {
        self.additionalChargeType = additionalChargeType.id
        self.amount = amount
    }
    
    init(additionalChargeBase: ExpenseEventAdditionalChargeBase) {
        self.additionalChargeType = additionalChargeBase.name
        self.amount = additionalChargeBase.amount
    }
}

// This is only used in Expense Result View
struct PersonItem: Identifiable {
    var id: UUID = UUID()
    var user: UserData
    var items: [ExpenseItem]
    var additional: [AdditionalCharge]
}

enum SplitMethod: String, Identifiable {
    case equally = "equally"
    case custom = "custom"
    
    var id: String { rawValue }
    
    var splitName: String {
        switch self {
        case .equally:
            "Equally"
        case .custom:
            "Custom"
        }
    }
    
    var splitDescription: String {
        switch self {
        case .equally:
            "Equally Splitted"
        case .custom:
            "Custom Splitted"
        }
    }
    
    var icon: ImageResource {
        switch self {
        case .equally:
                .equalSplitIcon
        case .custom:
                .customSplitIcon
        }
    }
    
    static var allCases: [SplitMethod] {
        [.equally, .custom]
    }
}

enum AdditionalChargeType: String, Identifiable {
    case tax
    case service
    case discount
    case other
    
    var id: String{
        switch self{
        case .tax:
            "tax"
        case .service:
            "service"
        case .discount:
            "discount"
        case .other:
            "other"
        }
    }
    
    var name: String{
        switch self{
        case .tax:
            "Tax"
        case .service:
            "Service"
        case .discount:
            "Discount"
        case .other:
            "Other"
        }
    }
    
    static var allCases: [AdditionalChargeType]{
        [.tax, .service, .discount, .other]
    }
}
