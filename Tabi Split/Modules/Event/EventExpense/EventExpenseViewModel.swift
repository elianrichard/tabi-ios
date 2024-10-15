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
    var selectedExpense: Expense? = nil {
        didSet {
           populateViewModel()
        }
    }
    var isEdit = false
    
    var expenseName: String = ""
    var expenseTotalInput: String = ""
    var selectedParticipants: [UserData] = []
    var selectedMethod: SplitMethod?
    var selectedCoverer: UserData?
    
    var peopleItems: [PersonItem] = []
    var totalItemCosts: Float = 0
    var totalAdditionalCharges: Float = 0
    var totalSpending: Float = 0
    
    var items: [ExpenseItem] = [
        ExpenseItem(itemName: "", itemPrice: 0, itemQuantity: 1)
    ]
    var additionalCharges: [AdditionalCharge] = [
        AdditionalCharge(additionalChargeType: .tax, amount: 0)
    ]
    
    func deleteItem(item: ExpenseItem){
        items.removeAll(where: { $0 == item })
    }
    func calculateTotal() {
        var total: Float = 0
        var totalCosts: Float = 0
        var totalAdditional: Float = 0
        for item in items {
            total += (item.itemPrice) * Float(item.itemQuantity)
            totalCosts += (item.itemPrice) * Float(item.itemQuantity)
        }
        for charge in additionalCharges{
            total += (charge.amount)
            totalAdditional += (charge.amount)
        }
        totalSpending = total
        totalItemCosts = totalCosts
        totalAdditionalCharges = totalAdditional
    }
    func createNewExpenseItem () {
        items.append(ExpenseItem(itemName: "", itemPrice: 0, itemQuantity: 1))
    }
    func calculatePersonSpending(person: PersonItem) -> Float {
        let totalSpent = person.items.reduce(0) { $0 + ($1.itemPrice) * Float($1.itemQuantity) }
        return totalSpent + person.additional.reduce(0) { $0 + ($1.amount) }
    }
    func calculatePeopleItems() {
        calculateTotal()
        for person in selectedParticipants {
            var personItems: [ExpenseItem] = []
            var additional: [AdditionalCharge] = []
            var totalSpentPerson: Float = 0
            for item in items {
                if item.assignees.filter({ $0.user.id == person.id }).count > 0 {
                    let itemName = item.itemName
                    let itemPrice = item.itemPrice
                    if let itemQuantity = item.assignees.first(where: { $0.user.id == person.id })?.share {
                        totalSpentPerson += itemPrice * Float(itemQuantity)
                        personItems.append(ExpenseItem(itemName: itemName, itemPrice: itemPrice, itemQuantity: itemQuantity))
                    }
                }
            }
            for additionalCharge in additionalCharges {
                let amount = (additionalCharge.amount) * totalSpentPerson / totalItemCosts
                additional.append(AdditionalCharge(additionalChargeType: AdditionalChargeType(rawValue: additionalCharge.additionalChargeType) ?? .other, amount: amount.properRound() ))
            }
            peopleItems.append(PersonItem(name: person.name, items: personItems, additional: additional))
        }
    }
    func calculateEqualSplit() -> Float {
        return Float(totalSpending / Float(selectedParticipants.count))
    }
    func resetViewModel() {
        selectedExpense = nil
        isEdit = false
        expenseName = ""
        expenseTotalInput = ""
        selectedParticipants = []
        selectedMethod = nil
        selectedCoverer = nil
        peopleItems = []
        totalItemCosts = 0
        totalAdditionalCharges = 0
        totalSpending = 0
        items = [
            ExpenseItem(itemName: "", itemPrice: 0, itemQuantity: 1)
        ]
        additionalCharges = [
            AdditionalCharge(additionalChargeType: .tax, amount: 0)
        ]
    }
    func populateViewModel() {
        if let expense = selectedExpense {
            print("populating expense: \(expense.name)")
            expenseName = expense.name
            isEdit = false
            selectedCoverer = expense.coverer
            selectedMethod = SplitMethod(rawValue: expense.splitMethod)
            items = expense.items
            additionalCharges = expense.additionalCharges
            selectedParticipants = expense.participants
            print("participatns", expense.participants, expense.items, expense.coverer, expense.name, expense.splitMethod)
            if (expense.splitMethod == SplitMethod.equally.id) {
                totalSpending = expense.price
                expenseTotalInput = expense.price.formatPrice()
            } else if (expense.splitMethod == SplitMethod.custom.id) {
                calculatePeopleItems()
            }
        }
    }
    @MainActor
    func finalizeExpense(_ event: EventData) {
        guard let selectedCoverer, let selectedMethod else {
            print("Error")
            return
        }
        let expense = Expense(name: expenseName, coverer: selectedCoverer, price: totalSpending, splitMethod: selectedMethod, participants: selectedParticipants, items: items, additionalCharges: additionalCharges)
        SwiftDataService.shared.addExpenseToEvent(event, expense)
    }
    @MainActor
    func handleDeleteExpense(_ event: EventData) {
        if let expense = selectedExpense {
            event.expenses.removeAll(where: { $0 == expense })
            SwiftDataService.shared.saveModelContext()
        }
    }
    @MainActor
    func handleUpdateExpense (_ event: EventData) {
        if let expense = selectedExpense, let selectedCoverer = selectedCoverer, let selectedMethod = selectedMethod {
            guard let index = event.expenses.firstIndex(of: expense) else { return }
            event.expenses[index] = Expense(name: expenseName, coverer: selectedCoverer, price: totalSpending, splitMethod: selectedMethod, participants: selectedParticipants, items: items, additionalCharges: additionalCharges)
            SwiftDataService.shared.saveModelContext()
        }
    }
    
    var receiptImage: PhotosPickerItem? = nil
}
