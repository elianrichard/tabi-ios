//
//  Models.swift
//  Tabi
//
//  Created by Dharmawan Ruslan on 03/10/24.
//

import Foundation

struct Item: Identifiable, Codable, Equatable{
    var id: UUID = UUID.init()
    var itemName: String
    var itemPrice: String
    var itemQuantity: String
    var people: [people] = []
}

struct people: Identifiable, Codable, Equatable{
    var id: UUID = UUID.init()
    var name: String
    var totalSpending: Int = 0
}

struct Expense: Identifiable{
    var id: UUID = UUID.init()
    var name: String
    var coverer: String
    var dateOfCreation: Date
    var price: Int
}
