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
    var isApiCallLoading = false
    var selectedExpense: Expense? = nil {
        didSet {
            populateViewModel()
        }
    }
    var isEdit = false
    var isEditView: Bool {
        return selectedExpense == nil || isEdit
    }
    var isQuickScanned = false
    
    var expenseName: String = ""
    var expenseTotalInput: Float = 0
    var selectedParticipants: [UserData] = []
    var selectedMethod: SplitMethod?
    var selectedCoverer: UserData?
    
    var peopleItems: [PersonItem] = []
    var totalItemCosts: Float = 0
    var totalAdditionalCharges: Float = 0
    var totalSpending: Float = 0
    
    var items: [ExpenseItem] = [
        ExpenseItem(itemName: "", itemPrice: 0, itemQuantity: 1),
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
        peopleItems.removeAll()
        calculateTotal()
        for person in selectedParticipants {
            var personItems: [ExpenseItem] = []
            var additional: [AdditionalCharge] = []
            var totalSpentPerson: Float = 0
            for item in items {
                if item.assignees.filter({ $0.user.id == person.id }).count > 0 {
                    let itemName = item.itemName
                    let itemPrice = item.itemPrice
                    let itemQuantity = item.itemQuantity / item.assignees.map({$0.share}).reduce(0, +) * (item.assignees.first(where: { $0.user.id == person.id })?.share ?? 0)
                    totalSpentPerson += itemPrice * Float(itemQuantity)
                    personItems.append(ExpenseItem(itemName: itemName, itemPrice: itemPrice, itemQuantity: itemQuantity))
                }
            }
            for additionalCharge in additionalCharges {
                let amount = (additionalCharge.amount) * totalSpentPerson / totalItemCosts
                additional.append(AdditionalCharge(additionalChargeType: AdditionalChargeType(rawValue: additionalCharge.additionalChargeType) ?? .other, amount: amount.properRound() ))
            }
            peopleItems.append(PersonItem(user: person, items: personItems, additional: additional))
        }
    }
    func calculateEqualSplit() -> Float {
        return Float(totalSpending / Float(selectedParticipants.count))
    }
    func resetViewModel() {
        selectedExpense = nil
        isEdit = false
        expenseName = ""
        expenseTotalInput = 0
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
            expenseName = expense.name
            isEdit = false
            selectedCoverer = expense.coverer
            selectedMethod = SplitMethod(rawValue: expense.splitMethod)
            items = expense.items
            additionalCharges = expense.additionalCharges
            selectedParticipants = expense.participants
            if (expense.splitMethod == SplitMethod.equally.id) {
                totalSpending = expense.price
                expenseTotalInput = expense.price
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
        let cleanedString2 = cleanedString.lowercased().replacingOccurrences(of: "[rp|rp.|rp. |rp .]", with: "", options: .regularExpression)
        
        // Convert the cleaned string to Float
        return Float(cleanedString2) ?? 0
    }
    func performOCROnImage(_ image: UIImage) throws {
        var itemsAndPrice: [[String]] = []
        self.words.removeAll()
        var totalFound: Bool = false
        var subTotalFound: Bool = false
        var serviceFound: Bool = false
        var taxFound: Bool = false
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
        
        firstLoop: for word in words {
            if let topCandidate = word.topCandidates(1).first {
                let recognizedText = topCandidate.string.replacingOccurrences(of: " ", with: "")
                print(recognizedText)
                let pattern = "^((Rp|rp|RP)?\\d{1,3})(((,|\\.)\\d{3})*((,|\\.)\\d{2})?)$"
                let regex = try? NSRegularExpression(pattern: pattern)
                let range = NSRange(location: 0, length: recognizedText.utf16.count)
                if regex?.firstMatch(in: recognizedText, options: [], range: range) != nil {
                    if word.boundingBox.maxX > 0.7 { // find the prices that is on the right (TBD: find a better solution than 0.7)
                        for (index, word2) in words.enumerated() {
                            var currentIndex = index
                            if (((word2.boundingBox.midY) <= word.boundingBox.maxY) && ((word2.boundingBox.midY) >= (word.boundingBox.minY))){ // find the closest item that is parallel in the same row
                                if let recognizedText2 = word2.topCandidates(1).first?.string{
                                    if recognizedText2 != recognizedText {
                                        
                                        let isItTax = taxKeywords.contains { additionalChargeKeywords in
                                            normalizeString(recognizedText2).contains(additionalChargeKeywords)
                                        }
                                        let isItService = serviceKeywords.contains { serviceKeywords in
                                            normalizeString(recognizedText2).contains(serviceKeywords)
                                        }
                                        
                                        if normalizeString(recognizedText2).range(of: "[a-zA-Z0-9]*", options: .regularExpression) != nil && !isItTax && !isItService  && isValidNumberGreaterThanAlphabets(recognizedText2){ // if the item contains a symbol or number likely it isnt the item name
                                            var recognizedText3 = words[currentIndex-1].topCandidates(1).first?.string
                                            while normalizeString(recognizedText3 ?? "").range(of: "[a-zA-Z0-9]*", options: .regularExpression) != nil && isValidNumberGreaterThanAlphabets(recognizedText3 ?? "") {
                                                currentIndex -= 1
                                                recognizedText3 = words[currentIndex-1].topCandidates(1).first?.string
                                            }// when the while loop ends recognized text 3 should be an item name
                                            itemsAndPrice.append([recognizedText3 ?? "", normalizeString(recognizedText3 ?? ""), recognizedText])
                                            continue firstLoop
                                        }else{
                                            let recognizedText2 = word2.topCandidates(1).first?.string
                                            itemsAndPrice.append([recognizedText2 ?? "", normalizeString(recognizedText2 ?? ""), recognizedText])
                                            continue firstLoop
                                        }
                                    }
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
                taxFound.toggle()
                if !item[1].contains("dasar") || !item[1].contains("sebelum") || !item[1].contains("incl") {
                    additionalCharges.append(AdditionalCharge(additionalChargeType: .tax, amount: stringToFloat(item[2])))
                    itemsAndPrice.remove(item)
                    continue
                }else{
                    itemsAndPrice.remove(item)
                    continue
                }
            }
            
            let isItService = serviceKeywords.contains { serviceKeywords in
                item[1].contains(serviceKeywords)
            }
            if isItService {
                serviceFound.toggle()
                additionalCharges.append(AdditionalCharge(additionalChargeType: .service, amount: stringToFloat(item[2])))
                itemsAndPrice.remove(item)
                continue
            }
            
            if (item[1].contains("total") && item[1] != "subtotal"){
                if (item[1].contains("food") || item[1].contains("beverage")){
                    itemsAndPrice.remove(item)
                    continue
                }
                totalFound.toggle()
                self.totalSpending = stringToFloat(item[2])
                itemsAndPrice.remove(item)
                break
            }
            
            if !subTotalFound && !serviceFound && !taxFound{
                if (item[1].contains("subtotal")){
                    subTotalFound.toggle()
                    continue
                }
                items.append(ExpenseItem(itemName: item[0], itemPrice: stringToFloat(item[2]), itemQuantity: 1))
                itemsAndPrice.remove(item)
            }
        }
    }
    func removeZeroShareAssignee(item: ExpenseItem) {
        if let item = items.first(where: { $0.id == item.id }){
            for person in item.assignees{
                if person.share == 0{
                    item.assignees.remove(person)
                }
            }
        }
    }
    func isValidNumberGreaterThanAlphabets(_ string: String) -> Bool {
        let numbersRegex = try! NSRegularExpression(pattern: "\\d") // Match digits
        let alphabetsRegex = try! NSRegularExpression(pattern: "[a-zA-Z]") // Match alphabets
        
        let numbersCount = numbersRegex.numberOfMatches(in: string, range: NSRange(location: 0, length: string.utf16.count))
        let alphabetsCount = alphabetsRegex.numberOfMatches(in: string, range: NSRange(location: 0, length: string.utf16.count))
        
        return numbersCount >= alphabetsCount
    }
    @MainActor
    func finalizeExpense(_ event: EventData, isGuest: Bool) async -> Bool {
        guard let selectedCoverer, let selectedMethod else {
            print("Error")
            return false
        }
        
        do {
            let expense = Expense(name: expenseName, coverer: selectedCoverer, price: totalSpending, splitMethod: selectedMethod, participants: selectedParticipants)
            event.expenses.append(expense)
            if (selectedMethod == .equally) {
                let assignees = selectedParticipants.map{ ExpensePerson(user: $0, share: 1) }
                let expenseItem = ExpenseItem(itemName: expenseName, itemPrice: totalSpending, itemQuantity: 1, assignees: [])
                // TODO: FIX THIS UNUSUAL BEHAVIOUR
                let uniqueAsignees = assignees.reduce(into: [ExpensePerson]()) { result, item in
                    if !result.contains(where: { $0.user.userId == item.user.userId }) {
                        result.append(item)
                    }
                }
                expense.items.append(expenseItem)
                expenseItem.assignees.append(contentsOf: uniqueAsignees)
            } else {
                expense.items = items
                expense.additionalCharges = additionalCharges
            }
            if !isGuest {
                isApiCallLoading = true
                let response = try await ExpenseService.shared.createExpense(event: event, expense: expense)
                expense.expenseId = response.expense_id
            }
            SwiftDataService.shared.saveModelContext()
        } catch {
            print("Create expense failed: \(error)")
            isApiCallLoading = false
            return false
        }
        isApiCallLoading = false
        return true
    }
    
    @MainActor
    func handleDeleteExpense(event: EventData?, isGuest: Bool) async -> Bool {
        guard let expense = selectedExpense, let event else { return false }
        if !isGuest {
            do {
                isApiCallLoading = true
                try await ExpenseService.shared.deleteExpense(expense: expense)
            } catch {
                print("Expense delete failed: \(error)")
                isApiCallLoading = false
                return false
            }
        }
        event.expenses.removeAll(where: { $0 == expense })
        SwiftDataService.shared.saveModelContext()
        isApiCallLoading = false
        return true
    }
    
    @MainActor
    func handleUpdateExpense (event: EventData, isGuest: Bool) async -> Bool {
        guard let expense = selectedExpense, let selectedCoverer = selectedCoverer, let selectedMethod = selectedMethod else { return false }
        do {
            if !isGuest {
                isApiCallLoading = true
                try await ExpenseService.shared.updateExpense(expense: expense)
            }
            expense.coverer = selectedCoverer
            expense.price = totalSpending
            expense.splitMethod = selectedMethod.id
            expense.items = items
            expense.additionalCharges = additionalCharges
            expense.participants = selectedParticipants
            SwiftDataService.shared.saveModelContext()
        } catch {
            print("Update expense failed: \(error)")
            isApiCallLoading = false
            return false
        }
        isApiCallLoading = false
        return true
    }
}
