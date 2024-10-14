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
    var peoples: [ExpensePerson] = [
        ExpensePerson(user: UserData(name: "Dharma", phone: "081234567890"), share: 0.25),
        ExpensePerson(user: UserData(name: "Mario", phone: "081234567890"), share: 0.25),
        ExpensePerson(user: UserData(name: "Renaldi", phone: "081234567890"), share: 0.25),
        ExpensePerson(user: UserData(name: "Leo", phone: "081234567890"), share: 0.25),
    ]
    var totalSpentAll: Float = 0
    var splitMethod: SplitMethod = .custom
    var expenseTitle: String = "Lunch at Yoshinoya"
    
    var items: [ExpenseItem] = [
        ExpenseItem(itemName: "Bakmi Goreng", itemPrice: 10000, itemQuantity: 5),
        ExpenseItem(itemName: "Bakmi Babi", itemPrice: 30000, itemQuantity: 3),
        ExpenseItem(itemName: "Es krim spesial sosis", itemPrice: 20000, itemQuantity: 3),
        ExpenseItem(itemName: "Bakmi Kuah", itemPrice: 20000, itemQuantity: 5),
        ExpenseItem(itemName: "Bakso", itemPrice: 30000, itemQuantity: 5),
        ExpenseItem(itemName: "Sephaghetti agilio ogolio ogolio ogolio ogolio ogolio ogolio ogolio ogolio ogolio ogolio ogolio ogolio ogolio ogolio ogolio ogolio", itemPrice: 25000, itemQuantity: 2),
        ExpenseItem(itemName: "Es krim cah kangkung", itemPrice: 50000, itemQuantity: 4),
    ]
    
    var additionalCharges: [AdditionalCharge] = [
        AdditionalCharge(additionalChargeType: .tax, amount: 20000),
        AdditionalCharge(additionalChargeType: .service, amount: 30000),
        AdditionalCharge(additionalChargeType: .discount, amount: -20000),
        AdditionalCharge(additionalChargeType: .other, amount: 100000)
    ]
    
    var peopleItems: [PersonItem] = []
    var isExpanded: Bool = false
    
//    init(){
//        for index in items.indices{
//            items[index].asignees.append(peoples.randomElement()!)
//        }
//        
//        for people in peoples {
//            let name = people.user.name
//            peopleItems.append(PersonItem(name: name, totalSpending: 0, items: []))
//            for item in items {
//                if item.asignees.contains(where: people){
//                    let itemName = item.itemName
//                    let itemPrice = item.itemPrice
//                    let itemQuantity = people.share
//                    peopleItems[peopleItems.count-1].totalSpending += (itemPrice ?? 0) * itemQuantity
//                    totalSpentAll += (itemPrice ?? 0) * itemQuantity
//                    peopleItems[peopleItems.count-1].items.append(ExpenseItem(itemName: itemName, itemPrice: itemPrice, itemQuantity: itemQuantity))
//                }
//            }
//        }
//        
//        for people in peopleItems {
//            let peopleIndex = peopleItems.firstIndex(of: people)
//            for additionalCharge in additionalCharges {
//                peopleItems[peopleIndex!].totalSpending += (additionalCharge.amount ?? 0) * people.totalSpending / totalSpentAll
//            }
//        }
//    }
}
