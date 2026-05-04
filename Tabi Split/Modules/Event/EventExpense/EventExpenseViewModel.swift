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
    var error: AppError?
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

    // Prices whose bounding box right-edge exceeds this threshold are treated as column-aligned totals.
    private static let ocrRightEdgeThreshold: CGFloat = 0.7
    
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
        isQuickScanned = false
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
        self.items.removeAll()
        self.additionalCharges.removeAll()
        self.words.removeAll()

        guard let cgImage = image.cgImage else { throw ocrError.imageConversionError }
        words = try extractObservations(from: cgImage)
        let pairs = parseReceiptPairs(from: words)
        applyParsedItems(pairs)
    }

    // Runs Vision text recognition and returns the raw observations.
    private func extractObservations(from cgImage: CGImage) throws -> [VNRecognizedTextObservation] {
        var observations: [VNRecognizedTextObservation] = []
        let request = VNRecognizeTextRequest { req, _ in
            observations = (req.results as? [VNRecognizedTextObservation]) ?? []
        }
        request.recognitionLevel = .accurate
        do {
            try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
        } catch {
            throw ocrError.textRecognizerError
        }
        return observations
    }

    // Extracts (displayName, normalizedName, priceString) triples from OCR observations.
    private func parseReceiptPairs(from observations: [VNRecognizedTextObservation]) -> [[String]] {
        let pricePattern = "^((Rp|rp|RP)?\\d{1,3})(((,|\\.)\\d{3})*((,|\\.)\\d{2})?)$"
        let priceRegex = try? NSRegularExpression(pattern: pricePattern)
        var pairs: [[String]] = []

        firstLoop: for (_, word) in observations.enumerated() {
            guard let candidate = word.topCandidates(1).first else { continue }
            let text = candidate.string.replacingOccurrences(of: " ", with: "")
            let range = NSRange(location: 0, length: text.utf16.count)
            guard priceRegex?.firstMatch(in: text, options: [], range: range) != nil else { continue }
            guard word.boundingBox.maxX > Self.ocrRightEdgeThreshold else { continue }

            for (index, word2) in observations.enumerated() {
                var currentIndex = index
                let isOnSameRow = word2.boundingBox.midY <= word.boundingBox.maxY
                    && word2.boundingBox.midY >= word.boundingBox.minY
                guard isOnSameRow else { continue }
                guard let label = word2.topCandidates(1).first?.string, label != text else { continue }

                let normalizedLabel = normalizeString(label)
                let labelHasMoreNumbers = isValidNumberGreaterThanAlphabets(label)

                if normalizedLabel.range(of: "[a-zA-Z0-9]*", options: .regularExpression) != nil
                    && !isTax(normalizedLabel) && !isService(normalizedLabel)
                    && labelHasMoreNumbers {
                    // Label looks like a quantity/code — walk backwards for the real name
                    var name = observations[currentIndex - 1].topCandidates(1).first?.string
                    while let n = name,
                          normalizeString(n).range(of: "[a-zA-Z0-9]*", options: .regularExpression) != nil,
                          isValidNumberGreaterThanAlphabets(n) {
                        currentIndex -= 1
                        name = observations[currentIndex - 1].topCandidates(1).first?.string
                    }
                    pairs.append([name ?? "", normalizeString(name ?? ""), text])
                } else {
                    pairs.append([label, normalizedLabel, text])
                }
                continue firstLoop
            }
        }
        return pairs
    }

    // Categorises parsed pairs into items, additional charges, and total spending.
    private func applyParsedItems(_ pairs: [[String]]) {
        let taxKeywords = ["tax", "ppn", "pb10", "prest10", "pajak", "taxes", "pb1"]
        let serviceKeywords = ["service", "charge"]
        var remaining = pairs
        var subTotalFound = false
        var serviceFound = false
        var taxFound = false

        for item in remaining {
            let normalized = item[1]
            let price = stringToFloat(item[2])

            if taxKeywords.contains(where: { normalized.contains($0) }) {
                taxFound = true
                let isSummaryRow = normalized.contains("dasar") || normalized.contains("sebelum") || normalized.contains("incl")
                if !isSummaryRow {
                    additionalCharges.append(AdditionalCharge(additionalChargeType: .tax, amount: price))
                }
                remaining.remove(item)
                continue
            }

            if serviceKeywords.contains(where: { normalized.contains($0) }) {
                serviceFound = true
                additionalCharges.append(AdditionalCharge(additionalChargeType: .service, amount: price))
                remaining.remove(item)
                continue
            }

            if normalized.contains("total") && normalized != "subtotal" {
                if normalized.contains("food") || normalized.contains("beverage") {
                    remaining.remove(item)
                    continue
                }
                totalSpending = price
                remaining.remove(item)
                break
            }

            if !subTotalFound && !serviceFound && !taxFound {
                if normalized.contains("subtotal") {
                    subTotalFound = true
                    continue
                }
                items.append(ExpenseItem(itemName: item[0], itemPrice: price, itemQuantity: 1))
                remaining.remove(item)
            }
        }
    }

    private func isTax(_ normalized: String) -> Bool {
        ["tax", "ppn", "pb10", "prest10", "pajak", "taxes", "pb1"].contains { normalized.contains($0) }
    }

    private func isService(_ normalized: String) -> Bool {
        ["service", "charge"].contains { normalized.contains($0) }
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
            self.error = .validation("Coverer and split method are required")
            return false
        }
        isApiCallLoading = true
        defer { isApiCallLoading = false }
        
        do {
            let expense = Expense(name: expenseName, coverer: selectedCoverer, price: totalSpending, splitMethod: selectedMethod, participants: selectedParticipants)
            if (selectedMethod == .equally) {
                let assignees = selectedParticipants.map{ ExpensePerson(user: $0, share: 1) }
                let expenseItem = ExpenseItem(itemName: expenseName, itemPrice: totalSpending, itemQuantity: 1, assignees: [])
                expense.items.append(expenseItem)
                expenseItem.assignees.append(contentsOf: assignees)
            } else {
                expense.items = items
                expense.additionalCharges = additionalCharges
            }
            if !isGuest {
                let response = try await ExpenseService.shared.createExpense(event: event, expense: expense)
                expense.expenseId = response.expense_id
            }
            event.expenses.append(expense)
            SwiftDataService.shared.saveModelContext()
        } catch {
            self.error = .from(error)
            return false
        }
        return true
    }
    
    @MainActor
    func handleDeleteExpense(event: EventData?, isGuest: Bool) async -> Bool {
        guard let expense = selectedExpense, let event else { return false }
        isApiCallLoading = true
        defer { isApiCallLoading = false }
        
        do {
            if !isGuest {
                try await ExpenseService.shared.deleteExpense(expense: expense)
            }
            event.expenses.removeAll(where: { $0 == expense })
            SwiftDataService.shared.saveModelContext()
        } catch {
            self.error = .from(error)
            return false
        }
        return true
    }
    
    @MainActor
    func handleUpdateExpense (event: EventData, isGuest: Bool) async -> Bool {
        guard let expense = selectedExpense, let selectedCoverer = selectedCoverer, let selectedMethod = selectedMethod else { return false }
        isApiCallLoading = true
        defer { isApiCallLoading = false }
        
        let originalCoverer = expense.coverer
        let originalPrice = expense.price
        let originalSplitMethod = expense.splitMethod
        let originalItems = expense.items
        let originalAdditionalCharges = expense.additionalCharges
        let originalParticipants = expense.participants
        
        do {
            expense.coverer = selectedCoverer
            expense.price = totalSpending
            expense.splitMethod = selectedMethod.id
            expense.items = items
            expense.additionalCharges = additionalCharges
            expense.participants = selectedParticipants
            
            if !isGuest {
                try await ExpenseService.shared.updateExpense(expense: expense)
            }
            SwiftDataService.shared.saveModelContext()
        } catch {
            expense.coverer = originalCoverer
            expense.price = originalPrice
            expense.splitMethod = originalSplitMethod
            expense.items = originalItems
            expense.additionalCharges = originalAdditionalCharges
            expense.participants = originalParticipants
            self.error = .from(error)
            return false
        }
        return true
    }
}
