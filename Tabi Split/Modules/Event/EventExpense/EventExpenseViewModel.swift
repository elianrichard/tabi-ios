//
//  EventExpenseViewModel.swift
//  Tabi
//
//  Created by Elian Richard on 10/10/24.
//

import Foundation
import SwiftUI
import PhotosUI
import Vision

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
    
    var uploadedReceiptImage: UIImage?
    var words: [VNRecognizedTextObservation] = []
    
    enum ocrError: Error {
        case imageConversionError
        case textRecognizerError
    }
    
    func deleteItem(item: ExpenseItem){
        items.removeAll(where: { $0.id == item.id })
    }
    func deleteAdditionalCharge(item: AdditionalCharge){
        additionalCharges.removeAll(where: { $0.id == item.id })
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
                    let itemQuantity = item.itemQuantity / item.assignees.map({$0.share}).reduce(0, +)
                    totalSpentPerson += itemPrice * Float(itemQuantity)
                    personItems.append(ExpenseItem(itemName: itemName, itemPrice: itemPrice, itemQuantity: itemQuantity))
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
        uploadedReceiptImage = nil
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
            if (expense.splitMethod == SplitMethod.equally.id) {
                totalSpending = expense.price
                expenseTotalInput = expense.price.formatPrice()
            } else if (expense.splitMethod == SplitMethod.custom.id) {
                calculatePeopleItems()
            }
        }
    }
    func normalizeString(_ input: String) -> String {
        // Lowercase the string
        let lowercasedString = input.lowercased()
        
        // Remove whitespaces, punctuation, and symbols
        let filteredString = lowercasedString.unicodeScalars.filter {
            CharacterSet.letters.contains($0) || CharacterSet.decimalDigits.contains($0)
        }
        
        // Convert the filtered result back to a String
        return String(String.UnicodeScalarView(filteredString))
    }
    func stringToFloat(_ input: String) -> Float {
        // Replace commas used for thousand separators with an empty string
        let cleanedString = input.replacingOccurrences(of: "[.,]", with: "", options: .regularExpression)
        
        // Convert the cleaned string to Float
        return Float(cleanedString) ?? 0
    }
    func performOCROnImage(_ image: UIImage) throws {
        var itemsAndPrice: [[String]] = []
        self.words.removeAll()
        var totalFound: Bool = false
        var subTotalFound: Bool = false
        let taxKeywords: [String] = ["tax", "ppn", "pb10", "prest10", "pajak", "taxes", "pb1"]
        let serviceKeywords: [String] = ["service", "charge"]
        
        self.items.removeAll()
        self.additionalCharges.removeAll()
        
        guard let cgImage = image.cgImage else {
            throw ocrError.imageConversionError
        }
        
        let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                print("No recognized text.")
                return
            }
            
            for observation in observations {
                self.words.append(observation)
            }
        }
        
        request.recognitionLevel = .accurate // You can also use .fast for faster but less accurate recognition
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try requestHandler.perform([request])
        } catch {
            throw ocrError.textRecognizerError
        }
        
        for word in words {
            if let topCandidate = word.topCandidates(1).first {
                let recognizedText = topCandidate.string.replacingOccurrences(of: " ", with: "")
                print(recognizedText)
                let pattern = "^((Rp|rp|RP)?\\d{1,3})((,|.)\\d{3})*$"
                let regex = try? NSRegularExpression(pattern: pattern)
                let range = NSRange(location: 0, length: recognizedText.utf16.count)
                if regex?.firstMatch(in: recognizedText, options: [], range: range) != nil {
                    if word.boundingBox.minX > 0.6 {
                        for word2 in words {
                            if (((word2.boundingBox.midY) <= word.boundingBox.maxY) && ((word2.boundingBox.midY) >= (word.boundingBox.minY))){
                                let recognizedText2 = word2.topCandidates(1).first?.string
                                if recognizedText2 != recognizedText {
                                    itemsAndPrice.append([recognizedText2 ?? "", normalizeString(recognizedText2 ?? ""), recognizedText])
                                }
                            }
                        }
                    }
                }
            }
        }
        
        print(itemsAndPrice)
        
        for item in itemsAndPrice {
            let isItTax = taxKeywords.contains { additionalChargeKeywords in
                item[1].contains(additionalChargeKeywords)
            }
            if isItTax {
                if !item[1].contains("dasar") {
                    additionalCharges.append(AdditionalCharge(additionalChargeType: .tax, amount: stringToFloat(item[2])))
                    itemsAndPrice.remove(item)
                    continue
                }
            }
            
            let isItService = serviceKeywords.contains { serviceKeywords in
                item[1].contains(serviceKeywords)
            }
            if isItService {
                additionalCharges.append(AdditionalCharge(additionalChargeType: .service, amount: stringToFloat(item[2])))
                itemsAndPrice.remove(item)
                continue
            }
            
            if (item[1].contains("total") && item[1] != "subtotal"){
                totalFound.toggle()
                self.totalSpending = stringToFloat(item[2])
                itemsAndPrice.remove(item)
                break
            }
            
            if !subTotalFound{
                if (item[1].contains("subtotal")){
                    subTotalFound.toggle()
                    continue
                }
                items.append(ExpenseItem(itemName: item[0], itemPrice: stringToFloat(item[2]), itemQuantity: 1))
                itemsAndPrice.remove(item)
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
}
