//
//  AddExpenseViewModel.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 25/10/24.
//

import Foundation
import SwiftUI
import PhotosUI
import Vision

@Observable
class AddExpenseViewModel{
    var toggleSeeAll: Bool = false
    var settingsDetent = PresentationDetent.medium
    var toggleReceiptSheet: Bool = false
    var receiptSheetHeight: CGFloat = 0
    var toggleScannerSheet: Bool = false
    
    var eventExpenseViewModel: EventExpenseViewModel?
    var expenseNameError: String?
    var paidByError: String?
    var participantsError: String?
    var selectParticipantsError: String?
    var splitBillMethodError: String?
    var totalBillError: String?
    var isValid: Bool = true
    
    init(eventExpenseViewModel: EventExpenseViewModel? = EventExpenseViewModel()) {
        self.eventExpenseViewModel = eventExpenseViewModel
    }
    
    func validateInput() {
        isValid = true
        expenseNameError = nil
        paidByError = nil
        participantsError = nil
        selectParticipantsError = nil
        splitBillMethodError = nil
        
        if eventExpenseViewModel?.expenseName == "" {
            expenseNameError = "Please enter the expense name"
            isValid = false
        }
        
        if eventExpenseViewModel?.selectedCoverer == nil {
            paidByError = "Please select who paid for the bill"
            isValid = false
        }

        if eventExpenseViewModel?.selectedParticipants == [] {
            participantsError = "Please select the participants"
            isValid = false
        }
        
        if eventExpenseViewModel?.selectedMethod == nil {
            splitBillMethodError = "Please select the split bill method"
            isValid = false
        }
        
        if eventExpenseViewModel?.selectedMethod == .equally && (eventExpenseViewModel?.expenseTotalInput == 0 || eventExpenseViewModel?.expenseTotalInput == nil) {
            totalBillError = "Please enter the total bill amount"
            isValid = false
        }
    }
}
