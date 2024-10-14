//
//  ExpenseResultViewModel.swift
//  Tabi
//
//  Created by Dharmawan Ruslan on 08/10/24.
//

import Foundation
import SwiftUI

@Observable
class ExpenseResultViewModel{
    var people: [UserData] = [
        UserData(name: "Dharma", phone: "081234567890"),
        UserData(name: "Mario", phone: "081234567890"),
        UserData(name: "Renaldi", phone: "081234567890"),
        UserData(name: "Leo", phone: "081234567890"),
    ]
    var totalSpentAll: Float = 0
    var totalAdditionalCharges: Float = 0
    var splitMethod: SplitMethod = .custom
    var expenseTitle: String = "Lunch at Yoshinoya"
    
    var items: [ExpenseItem] = [
        ExpenseItem(itemName: "Bakmi Goreng", itemPrice: 10000, itemQuantity: 5, assignees: [
            ExpensePerson(user: UserData(name: "Dharma", phone: "081234567890"), share: 2),
            ExpensePerson(user: UserData(name: "Mario", phone: "081234567890"), share: 1),
            ExpensePerson(user: UserData(name: "Renaldi", phone: "081234567890"), share: 1),
            ExpensePerson(user: UserData(name: "Leo", phone: "081234567890"), share: 1),
        ]),
        ExpenseItem(itemName: "Bakmi Babi", itemPrice: 30000, itemQuantity: 3, assignees: [
            ExpensePerson(user: UserData(name: "Dharma", phone: "081234567890"), share: 1),
            ExpensePerson(user: UserData(name: "Mario", phone: "081234567890"), share: 2),
        ]),
        ExpenseItem(itemName: "Es krim spesial sosis", itemPrice: 20000, itemQuantity: 3, assignees: [
            ExpensePerson(user: UserData(name: "Dharma", phone: "081234567890"), share: 1),
            ExpensePerson(user: UserData(name: "Mario", phone: "081234567890"), share: 1),
            ExpensePerson(user: UserData(name: "Renaldi", phone: "081234567890"), share: 1),
        ]),
        ExpenseItem(itemName: "Bakmi Kuah", itemPrice: 20000, itemQuantity: 5, assignees: [
            ExpensePerson(user: UserData(name: "Dharma", phone: "081234567890"), share: 1),
            ExpensePerson(user: UserData(name: "Mario", phone: "081234567890"), share: 2),
            ExpensePerson(user: UserData(name: "Renaldi", phone: "081234567890"), share: 2),
        ]),
        ExpenseItem(itemName: "Bakso", itemPrice: 30000, itemQuantity: 5, assignees: [
            ExpensePerson(user: UserData(name: "Dharma", phone: "081234567890"), share: 3),
            ExpensePerson(user: UserData(name: "Mario", phone: "081234567890"), share: 2),
        ]),
        ExpenseItem(itemName: "Sephaghetti agilio ogolio ogolio ogolio ogolio ogolio ogolio ogolio ogolio ogolio ogolio ogolio ogolio ogolio ogolio ogolio ogolio", itemPrice: 25000, itemQuantity: 2, assignees: [
            ExpensePerson(user: UserData(name: "Dharma", phone: "081234567890"), share: 1),
            ExpensePerson(user: UserData(name: "Mario", phone: "081234567890"), share: 1),
        ]),
        ExpenseItem(itemName: "Es krim cah kangkung", itemPrice: 50000, itemQuantity: 4, assignees: [
            ExpensePerson(user: UserData(name: "Dharma", phone: "081234567890"), share: 1),
            ExpensePerson(user: UserData(name: "Mario", phone: "081234567890"), share: 2),
            ExpensePerson(user: UserData(name: "Renaldi", phone: "081234567890"), share: 1),
        ]),
    ]
    
    var additionalCharges: [AdditionalCharge] = [
        AdditionalCharge(additionalChargeType: .tax, amount: 20000),
        AdditionalCharge(additionalChargeType: .service, amount: 30000),
        AdditionalCharge(additionalChargeType: .discount, amount: -20000),
        AdditionalCharge(additionalChargeType: .other, amount: 100000)
    ]
    
    var peopleItems: [PersonItem] = []
    var isExpanded: Bool = false
    
    init(){
        for item in items {
            totalSpentAll += (item.itemPrice) * Float(item.itemQuantity)
        }
        for additionalCharge in additionalCharges {
            totalAdditionalCharges += additionalCharge.amount
        }
        for person in people {
            var personItems: [ExpenseItem] = []
            var additional: [AdditionalCharge] = []
            var totalSpentPerson: Float = 0
            for item in items {
                if item.assignees.filter({ $0.user.name == person.name }).count > 0 {
                    let itemName = item.itemName
                    let itemPrice = item.itemPrice
                    if let itemQuantity = item.assignees.first(where: { $0.user.name == person.name })?.share {
                        totalSpentPerson += itemPrice
                        personItems.append(ExpenseItem(itemName: itemName, itemPrice: itemPrice, itemQuantity: itemQuantity))
                    }
                }
            }
            for additionalCharge in additionalCharges {
                let amount = (additionalCharge.amount) * totalSpentPerson / totalSpentAll
                additional.append(AdditionalCharge(additionalChargeType: AdditionalChargeType(rawValue: additionalCharge.additionalChargeType) ?? .other, amount: amount.properRound() ))
            }
            peopleItems.append(PersonItem(name: person.name, items: personItems, additional: additional))
        }
    }
    
    func calculatePersonSpending(person: PersonItem) -> Float {
        let totalSpent = person.items.reduce(0) { $0 + ($1.itemPrice) * Float($1.itemQuantity) }
        return totalSpent + person.additional.reduce(0) { $0 + ($1.amount) }
    }
    
    func calculateAllTotalSpending() -> Float {
        return totalSpentAll + totalAdditionalCharges
    }
}
