//
//  AssignCustomSplitViewModel.swift
//  Tabi
//
//  Created by Dharmawan Ruslan on 07/10/24.
//

import Foundation
import SwiftUI

@Observable
class ExpenseAssignViewModel {
    var selectedAsignee: UserData? = nil
    var isShowingQuantityChangeSheet: Bool = false
    var selectedItem: ExpenseItem = ExpenseItem(itemName: "", itemPrice: 0, itemQuantity: 0)
    var settingsDetent = PresentationDetent.medium
    
    func assignExpenseItem(item: ExpenseItem) {
        let isAssigned = item.assignees.contains (where: { $0.user == selectedAsignee })
        if let user = selectedAsignee {
            if !isAssigned {
                item.assignees.append(ExpensePerson(user: user, share: 1))
            } else {
                item.assignees.removeAll(where: { $0.user == user })
            }
        }
    }
    
    func toggleAsignee(user: UserData) {
        if selectedAsignee != user {
            selectedAsignee = user
        } else {
            selectedAsignee = nil
        }
    }
}
