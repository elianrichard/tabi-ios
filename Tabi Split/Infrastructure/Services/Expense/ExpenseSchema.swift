//
//  ExpenseSchema.swift
//  Tabi Split
//
//  Created by Elian Richard on 23/11/24.
//

struct CreateExpenseRequest: Codable {
    let name: String
    let coverer_id: String
    let split_method: String
    let receipt_url: String
    let items: [ExpenseItemBase]
    let additional_charges: [ExpenseAdditionalChargeBase]
    
    init(name: String, coverer_id: String, split_method: String, receipt_url: String, items: [ExpenseItemBase], additional_charges: [ExpenseAdditionalChargeBase]) {
        self.name = name
        self.coverer_id = coverer_id
        self.split_method = split_method
        self.receipt_url = receipt_url
        self.items = items
        self.additional_charges = additional_charges
    }
    
    init(expense: Expense) {
        self.name = expense.name
        self.coverer_id = expense.coverer.userId
        self.split_method = expense.splitMethod
        self.receipt_url = ""
        self.items = expense.items.map { ExpenseItemBase(expenseItem: $0) }
        self.additional_charges = expense.additionalCharges.map { ExpenseAdditionalChargeBase(expenseAdditionalCharge: $0) }
    }
}

struct ExpenseAdditionalChargeBase: Codable {
    let name: String
    let amount: Float
    
    init(name: String, amount: Float) {
        self.name = name
        self.amount = amount
    }
    
    init(expenseAdditionalCharge: AdditionalCharge) {
        self.name = expenseAdditionalCharge.additionalChargeType
        self.amount = expenseAdditionalCharge.amount
    }
}

struct ExpenseItemBase: Codable {
    let name: String
    let price: Float
    let quantity: Float
    let assignees: [ExpenseItemAssigneeBase]
    
    init(name: String, price: Float, quantity: Float, assignees: [ExpenseItemAssigneeBase]) {
        self.name = name
        self.price = price
        self.quantity = quantity
        self.assignees = assignees
    }
    
    init (expenseItem: ExpenseItem) {
        self.name = expenseItem.itemName
        self.price = expenseItem.itemPrice
        self.quantity = expenseItem.itemQuantity
        self.assignees = expenseItem.assignees.map { ExpenseItemAssigneeBase(expensePerson: $0) }
    }
}

struct ExpenseItemAssigneeBase: Codable {
    let user_id: String
    let share: Float
    
    init(user_id: String, share: Float) {
        self.user_id = user_id
        self.share = share
    }
    
    init(expensePerson: ExpensePerson) {
        self.user_id = expensePerson.user.userId
        self.share = expensePerson.share
    }
}

struct CreateExpenseResponse: Codable {
    let message: String
}


struct ExpenseEventBase: Codable {
    let id: String
    let name: String
    let coverer_id: String
    let total_expense: Float
    let split_method: String
    let receipt_url: String
    let created_at: String
    let additional_charges: [ExpenseEventAdditionalChargeBase]?
    let items: [ExpenseEventItemBase]
    
}

struct ExpenseEventAdditionalChargeBase: Codable {
    let id: String
    let name: String
    let amount: Float
}

struct ExpenseEventItemBase: Codable {
    let name: String
    let price: Float
    let quantity: Float
    let assignees: [ExpenseItemAssigneeBase]
}
