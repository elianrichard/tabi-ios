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
    var name: String
    var coverer: UserData
    var dateOfCreation: Date
    var price: Float
    var splitMethod: SplitMethod.ID
    var participants: [UserData]
    var items: [ExpenseItem]
    var additionalCharges: [AdditionalCharge]
    
    init(name: String, coverer: UserData, dateOfCreation: Date = Date(), price: Float, splitMethod: SplitMethod, participants: [UserData] = [], items: [ExpenseItem] = [], additionalCharges: [AdditionalCharge] = []) {
        self.name = name
        self.coverer = coverer
        self.dateOfCreation = dateOfCreation
        self.price = price
        self.splitMethod = splitMethod.id
        self.participants = participants
        self.items = items
        self.additionalCharges = additionalCharges
    }
}

@Model
class ExpenseItem {
    var itemName: String
    var itemPrice: Float
    var itemQuantity: Float
    var assignees: [ExpensePerson]
    
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
    
    init(user: UserData, share: Float = 0) {
        self.user = user
        self.share = share
    }
}

@Model
class AdditionalCharge {
    var additionalChargeType: AdditionalChargeType.ID
    var amount: Float
    
    init(additionalChargeType: AdditionalChargeType, amount: Float) {
        self.additionalChargeType = additionalChargeType.id
        self.amount = amount
    }
}

struct PersonItem: Identifiable {
    var id: UUID = UUID()
    var name: String
    var items: [ExpenseItem]
    var additional: [AdditionalCharge]
}

enum SplitMethod: String, Identifiable {
    case equally
    case custom
    
    var id: String{
        switch self{
        case .equally:
            "equally"
        case .custom:
            "custom"
        }
    }

    var splitDescription: String {
        switch self {
        case .equally:
            "Splitted Equally"
        case .custom:
            "Custom Splitted"
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
