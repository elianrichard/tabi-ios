//
//  AssignCustomSplitViewModel.swift
//  Tabi
//
//  Created by Dharmawan Ruslan on 07/10/24.
//

import Foundation
import SwiftUI

@Observable
class ExpenseCustomSplitViewModel: ObservableObject{
    var gridItem: [GridItem] = []
    var items: [Item] = [
        Item(itemName: "Salad", itemPrice: 30500, itemQuantity: 3),
        Item(itemName: "Seblak", itemPrice: 20000, itemQuantity: 1),
        Item(itemName: "Macaroni", itemPrice: 100000, itemQuantity: 2),
        Item(itemName: "Es Krim Goreng", itemPrice: 300500, itemQuantity: 5),
        Item(itemName: "Steak", itemPrice: 10500, itemQuantity: 4),
    ]
    var peoples: [People] = [
        People(name: "Dharma", share: 0.25),
        People(name: "Mario", share: 0.25),
        People(name: "Renaldi", share: 0.25),
        People(name: "Leo", share: 0.25),
        People(name: "Leo", share: 0.25),
        People(name: "Leo", share: 0.25),
        People(name: "Leo", share: 0.25),
        People(name: "Leo", share: 0.25),
        People(name: "Leo", share: 0.25),
        People(name: "Leo", share: 0.25),
        People(name: "Leo", share: 0.25),
        People(name: "Leo", share: 0.25),
        People(name: "Leo", share: 0.25),
    ]
    var selectedAsignee: People = People(name: "")
    var expenseTitle: String = "Lunch at Yoshinoya"
}
