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
    var peoples: [People] = [
        People(name: "Dharma", share: 0.25),
        People(name: "Mario", share: 0.25),
        People(name: "Renaldi", share: 0.25),
        People(name: "Leo", share: 0.25),
    ]
    var totalSpentAll: Float = 0
    var splitMethod: SplitMethod = .custom
    var expenseTitle: String = "Lunch at Yoshinoya"
    
    var items: [Item] = [
        Item(itemName: "Bakmi Goreng", itemPrice: 10000, itemQuantity: 5),
        Item(itemName: "Bakmi Babi", itemPrice: 30000, itemQuantity: 3),
        Item(itemName: "Es krim spesial sosis", itemPrice: 20000, itemQuantity: 3),
        Item(itemName: "Bakmi Kuah", itemPrice: 20000, itemQuantity: 5),
        Item(itemName: "Bakso", itemPrice: 30000, itemQuantity: 5),
        Item(itemName: "Sephaghetti agilio ogolio ogolio ogolio ogolio ogolio ogolio ogolio ogolio ogolio ogolio ogolio ogolio ogolio ogolio ogolio ogolio", itemPrice: 25000, itemQuantity: 2),
        Item(itemName: "Es krim cah kangkung", itemPrice: 50000, itemQuantity: 4),
    ]
    
    var additionalCharges: [AdditionalCharge] = [
        AdditionalCharge(additionalChargeType: .tax, amount: 20000),
        AdditionalCharge(additionalChargeType: .serviceCharge, amount: 30000),
        AdditionalCharge(additionalChargeType: .discount, amount: -20000),
        AdditionalCharge(additionalChargeType: .other, amount: 100000)
    ]
    
    var peopleItems: [PeopleItem] = []
    var isExpanded: Bool = false
    
    init(){
        for index in items.indices{
            items[index].asignees.append(peoples.randomElement()!)
        }
        
        for people in peoples {
            let name = people.name
            peopleItems.append(PeopleItem(name: name, totalSpending: 0, items: []))
            for item in items {
                if item.asignees.contains(people){
                    let itemName = item.itemName
                    let itemPrice = item.itemPrice
                    let itemQuantity = people.share
                    peopleItems[peopleItems.count-1].totalSpending += (itemPrice ?? 0) * itemQuantity
                    totalSpentAll += (itemPrice ?? 0) * itemQuantity
                    peopleItems[peopleItems.count-1].items.append(Item(itemName: itemName, itemPrice: itemPrice, itemQuantity: itemQuantity))
                }
            }
        }
        
        for people in peopleItems {
            let peopleIndex = peopleItems.firstIndex(of: people)
            for additionalCharge in additionalCharges {
                peopleItems[peopleIndex!].totalSpending += (additionalCharge.amount ?? 0) * people.totalSpending / totalSpentAll
            }
        }
    }
}
