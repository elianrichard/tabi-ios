//
//  AddExpenseViewModel.swift
//  Tabi
//
//  Created by Dharmawan Ruslan on 08/10/24.
//

import Foundation
import SwiftUI
import PhotosUI

@Observable
class AddExpenseViewModel{
    var eventName: String = "Japan Trip"
    var peoples: [People] = [
        People(name: "Dharma"),
        People(name: "Mario"),
        People(name: "Renaldi"),
        People(name: "Leo"),
    ]
    var expense: Expense = Expense(name: "Sate", coverer: "Naufal", dateOfCreation: .now, price: 100000)
    var expenseName: String = ""
    var selectedParticipants: [People] = []
    var methods: [String] = ["Split Equally", "Custom"]
    var selectedMethod: String = ""
    var selectedCoverer: People?
    var gridItem: [GridItem] = []
    var expenseTotal: Int?
    var receiptImage: PhotosPickerItem? = nil
}
