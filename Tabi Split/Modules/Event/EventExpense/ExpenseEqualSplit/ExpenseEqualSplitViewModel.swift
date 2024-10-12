//
//  ExpenseSplitViewModel.swift
//  Tabi
//
//  Created by Dharmawan Ruslan on 07/10/24.
//

import Foundation

@Observable
class ExpenseEqualSplitViewModel : ObservableObject{
    var expenseTitle: String = "Lunch at Yoshinoya"
    var peoples: [People] = [
        People(name: "Dharma", share: 0.25),
        People(name: "Mario", share: 0.25),
        People(name: "Renaldi", share: 0.25),
        People(name: "Leo", share: 0.25),
    ]
    var totalSpending: Float? = 0
    var items: [Item] = [
        Item(itemName: "", itemPrice: nil, itemQuantity: 1)
    ]
    var itemCount: Int = 1
    var additionalCharges: [AdditionalCharge] = [
        AdditionalCharge(additionalChargeType: .tax, amount: nil)
    ]
    
    func deleteItem(item: Item){
        let itemIndex = items.firstIndex(of: item)
        items.remove(at: itemIndex!)
    }
    
    func calculateTotal(){
        totalSpending = 0
        for item in items{
            totalSpending! += item.itemPrice ?? 0 * Float(item.itemQuantity)
        }
        for charge in additionalCharges{
            totalSpending! += charge.amount ?? 0
        }
    }
}
