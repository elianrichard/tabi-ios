//
//  EventExpenseViewModel.swift
//  Tabi
//
//  Created by Elian Richard on 10/10/24.
//

import Foundation
import SwiftUI
import PhotosUI

@Observable
final class EventExpenseViewModel {
    var expenseName: String = ""
    var selectedParticipants: [UserData] = []
    var selectedMethod: SplitMethod?
    var selectedCoverer: UserData?
    var expenseTotalInput: String = ""
    
    var totalSpending: Float? = 0

    var items: [ExpenseItem] = [
        ExpenseItem(itemName: "", itemPrice: nil, itemQuantity: 1)
    ] {
        didSet {
            calculateTotal()
        }
    }
    
    var additionalCharges: [AdditionalCharge] = [
        AdditionalCharge(additionalChargeType: .tax, amount: nil)
    ] {
        didSet {
            calculateTotal()
        }
    }
    
    func deleteItem(item: ExpenseItem){
        if let itemIndex = items.firstIndex(of: item){
            items.remove(at: itemIndex)
        }
    }
    
    func calculateTotal(){
        var total: Float = 0
        for item in items {
            total += (item.itemPrice ?? 0) * Float(item.itemQuantity)
        }
        for charge in additionalCharges{
            total += (charge.amount ?? 0)
        }
        totalSpending = total
    }
    
    func createNewExpenseItem () {
        items.append(ExpenseItem(itemName: "", itemPrice: nil, itemQuantity: 1))
    }
    
    var gridItem: [GridItem] = []
    var receiptImage: PhotosPickerItem? = nil
}
