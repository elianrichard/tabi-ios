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
    var items: [ExpenseItem] = [
        ExpenseItem(itemName: "Salad", itemPrice: 30500, itemQuantity: 3),
        ExpenseItem(itemName: "Seblak", itemPrice: 20000, itemQuantity: 1),
        ExpenseItem(itemName: "Macaroni", itemPrice: 100000, itemQuantity: 2),
        ExpenseItem(itemName: "Es Krim Goreng", itemPrice: 300500, itemQuantity: 5),
        ExpenseItem(itemName: "Steak", itemPrice: 10500, itemQuantity: 4),
    ]
    var peoples: [ExpensePerson] = [
//        People(name: "Dharma", share: 0.25),
//        People(name: "Mario", share: 0.25),
//        People(name: "Renaldi", share: 0.25),
//        People(name: "Leo", share: 0.25),
//        People(name: "Leo", share: 0.25),
//        People(name: "Leo", share: 0.25),
//        People(name: "Leo", share: 0.25),
//        People(name: "Leo", share: 0.25),
//        People(name: "Leo", share: 0.25),
//        People(name: "Leo", share: 0.25),
//        People(name: "Leo", share: 0.25),
//        People(name: "Leo", share: 0.25),
//        People(name: "Leo", share: 0.25),
    ]
    var selectedAsignee: ExpensePerson = ExpensePerson(user: UserData(name: "test", phone: "08123"))
    var expenseTitle: String = "Lunch at Yoshinoya"
}
