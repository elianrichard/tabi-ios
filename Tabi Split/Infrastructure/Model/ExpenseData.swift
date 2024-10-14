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
    var coverer: String
    var dateOfCreation: Date
    var price: Float
    var items: [ExpenseItem]
    
    init(name: String, coverer: String, dateOfCreation: Date, price: Float, items: [ExpenseItem] = []) {
        self.name = name
        self.coverer = coverer
        self.dateOfCreation = dateOfCreation
        self.price = price
        self.items = items
    }
}

@Model
class ExpenseItem {
    var itemName: String
    var itemPrice: Float?
    var itemQuantity: Float
    var asignees: [ExpensePerson]
    var additionalCharges: [AdditionalCharge]
    
    init(itemName: String, itemPrice: Float? = nil, itemQuantity: Float, asignees: [ExpensePerson] = [], additionalCharges: [AdditionalCharge] = []) {
        self.itemName = itemName
        self.itemPrice = itemPrice
        self.itemQuantity = itemQuantity
        self.asignees = asignees
        self.additionalCharges = additionalCharges
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
    var amount: Float?
    
    init(additionalChargeType: AdditionalChargeType, amount: Float? = nil) {
        self.additionalChargeType = additionalChargeType.id
        self.amount = amount
    }
}

struct PersonItem: Identifiable {
    var id: UUID = UUID()
    var name: String
    var totalSpending: Float
    var items: [ExpenseItem]
}

enum SplitMethod: Identifiable {
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
            "Equally Split"
        case .custom:
            "Custom Split"
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
