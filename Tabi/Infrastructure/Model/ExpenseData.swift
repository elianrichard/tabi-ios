//
//  Models.swift
//  Tabi
//
//  Created by Dharmawan Ruslan on 03/10/24.
//

import Foundation
import SwiftUI

struct Item: Identifiable, Codable, Equatable{
    var id: UUID = UUID.init()
    var itemName: String
    var itemPrice: Float?
    var itemQuantity: Int
    var people: [People] = []
}

struct People: Identifiable, Codable, Equatable{
    var id: UUID = UUID.init()
    var name: String
    var share: Float = 0
}

struct Expense: Identifiable{
    var id: UUID = UUID.init()
    var name: String
    var coverer: String
    var dateOfCreation: Date
    var price: Int
}

struct AdditionalCharge: Identifiable, Equatable{
    var id: UUID = UUID.init()
    var additionalChargeType: AdditionalChargeType
    var amount: Float?
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

enum AdditionalChargeType: Identifiable, Equatable{
    case tax
    case serviceCharge
    case discount
    case other
    
    var id: String{
        switch self{
        case .tax:
            "tax"
        case .serviceCharge:
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
        case .serviceCharge:
            "Service"
        case .discount:
            "Discount"
        case .other:
            "Other"
        }
    }
    
    static var allCases: [AdditionalChargeType]{
        [.tax, .serviceCharge, .discount, .other]
    }
}
