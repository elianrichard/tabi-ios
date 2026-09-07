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
import os.log

private extension OSLog {
    /// Receipt OCR diagnostics — filter in Console.app by this category to trace
    /// text recognition and item extraction. `subsystem` matches the app bundle id.
    static let ocr = OSLog(subsystem: ENV.APP_BUNDLE_ID, category: "ReceiptOCR")
}

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
    
    /// The raw OCR rows (grouped, top→bottom) from the last scan, kept so the AI
    /// refinement can re-read the receipt text alongside the on-device draft.
    var lastOCRLines: [String] = []
    var uploadedReceiptImage: UIImage?
    /// The backend image id for the uploaded receipt. Set after the image is
    /// uploaded (just-in-time, at finalize/update time) and persisted as the
    /// expense's `receipt_url`. On edit it is populated from the saved expense so
    /// an already-uploaded receipt is reflected even before its image is loaded.
    var uploadedReceiptId: String?

    /// Whether a receipt is attached — either a freshly picked image (not yet
    /// uploaded) or one already stored on the expense (edit flow, id only).
    var hasReceipt: Bool {
        uploadedReceiptImage != nil || uploadedReceiptId != nil
    }

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
        uploadedReceiptId = nil
    }

    /// Clears the transient receipt state after a successful create/update so the
    /// shared image does not leak into the next flow or re-trigger the review push.
    func clearReceiptState() {
        uploadedReceiptImage = nil
        uploadedReceiptId = nil
    }

    /// Attaches a freshly picked/scanned receipt image. Clears any previously
    /// stored image id so `uploadReceiptIfNeeded` re-uploads the new image — on
    /// edit, `uploadedReceiptId` holds the OLD receipt, and without clearing it the
    /// new image would be silently dropped and the old id kept.
    func attachReceiptImage(_ image: UIImage?) {
        uploadedReceiptImage = image
        uploadedReceiptId = nil
    }

    /// Uploads the pending receipt image (if any) and returns its backend image
    /// id, reusing an already-uploaded id when present. Throws on upload failure
    /// so callers can abort the create/update rather than silently drop the receipt.
    @MainActor
    private func uploadReceiptIfNeeded() async throws -> String? {
        guard let image = uploadedReceiptImage else { return uploadedReceiptId }
        if let existingId = uploadedReceiptId { return existingId }
        let response = try await ImageService.shared.uploadImage(image, folder: "receipt")
        uploadedReceiptId = response.id
        return response.id
    }

    /// Applies the current form's line items and additional charges onto an
    /// expense, according to the selected split method. Single source of truth for
    /// the item shape so create and update never diverge.
    ///
    /// - Equally: the split is represented as one line item covering the whole
    ///   total, assigned to every participant (share 1). The backend requires at
    ///   least one item, so this must never be empty. `reusing` lets an update
    ///   mutate the existing line item in place (preserving its id) instead of
    ///   orphaning it.
    /// - Custom: the user-entered items and additional charges are used verbatim.
    private func applyLineItems(to expense: Expense, method: SplitMethod, reusing existingItem: ExpenseItem? = nil) {
        switch method {
        case .equally:
            let assignees = selectedParticipants.map { ExpensePerson(user: $0, share: 1) }
            let lineItem = existingItem ?? ExpenseItem(itemName: expenseName, itemPrice: totalSpending, itemQuantity: 1)
            lineItem.itemName = expenseName
            lineItem.itemPrice = totalSpending
            lineItem.itemQuantity = 1
            lineItem.assignees = assignees
            expense.items = [lineItem]
            expense.additionalCharges = []
        case .custom:
            expense.items = items
            expense.additionalCharges = additionalCharges
        }
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
            uploadedReceiptId = expense.receiptId
            if (expense.splitMethod == SplitMethod.equally.id) {
                totalSpending = expense.price
                expenseTotalInput = expense.price
            } else if (expense.splitMethod == SplitMethod.custom.id) {
                calculatePeopleItems()
            }
        }
    }
    func normalizeString(_ input: String) -> String {
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
        
        return Float(cleanedString2) ?? 0
    }
    func performOCROnImage(_ image: UIImage) throws {
        var itemsAndPrice: [[String]] = []
        self.words.removeAll()
        let taxKeywords: [String] = ["tax", "ppn", "pb10", "prest10", "pajak", "taxes", "pb1"]
        let serviceKeywords: [String] = ["service", "charge"]
        
        self.items.removeAll()
        self.additionalCharges.removeAll()

        guard let cgImage = image.cgImage else {
            os_log(.error, log: .ocr, "OCR aborted — image has no cgImage (conversion failed)")
            throw ocrError.imageConversionError
        }

        let request = VNRecognizeTextRequest { (request, error) in
            if let error {
                os_log(.error, log: .ocr, "Text recognition error: %{public}@", String(describing: error))
            }
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                os_log(.debug, log: .ocr, "No recognized text.")
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
            os_log(.error, log: .ocr, "Vision request failed: %{public}@", String(describing: error))
            throw ocrError.textRecognizerError
        }

        // Flatten observations to (text, box) once. Working from a plain list keeps
        // the extraction geometry-relative (left-of-price on the same row) instead
        // of relying on an absolute image position — the old `boundingBox.maxX > 0.7`
        // gate failed on uncropped photos where the receipt is small/centred.
        struct RecognizedWord {
            let text: String
            let box: CGRect
        }
        let recognized: [RecognizedWord] = words.compactMap { obs in
            guard let candidate = obs.topCandidates(1).first else { return nil }
            return RecognizedWord(text: candidate.string, box: obs.boundingBox)
        }
        // Reading order (top→bottom, left→right) of the raw words — captured for the
        // single verification dump emitted at the end, not logged line by line here.
        // Vision's origin is bottom-left, so a larger midY is higher on the receipt.
        let readingOrder = recognized.sorted {
            if abs($0.box.midY - $1.box.midY) > 0.01 { return $0.box.midY > $1.box.midY }
            return $0.box.minX < $1.box.minX
        }

        let pricePattern = "^((Rp|rp|RP)?\\s?\\d{1,3})(((,|\\.|\\s)\\d{3})*((,|\\.)\\d{1,2})?)$"
        let priceRegex = try? NSRegularExpression(pattern: pricePattern)
        func isPrice(_ text: String) -> Bool {
            let compact = text.replacingOccurrences(of: " ", with: "")
            let range = NSRange(location: 0, length: compact.utf16.count)
            return priceRegex?.firstMatch(in: compact, options: [], range: range) != nil
        }
        func isRowAligned(_ a: CGRect, _ b: CGRect) -> Bool {
            // Two words share a row when their vertical centres are within ~half a
            // line height. Kept tight so a skewed receipt does not merge adjacent
            // rows into one (which pulls a neighbour's name into the wrong item).
            let tolerance = min(a.height, b.height) * 0.5
            return abs(a.midY - b.midY) <= tolerance
        }
        // A quantity / unit-price line rather than a product name, e.g. "1x @50.000",
        // "2 x 25,000", "@ 12.000". Such a row carries no name — the real product
        // name sits on the line above it.
        func looksLikeQuantityLine(_ text: String) -> Bool {
            let lower = text.lowercased()
            if lower.contains("@") { return true }
            // "<digits> x" or "x <digits>" (the quantity multiplier).
            if lower.range(of: #"(^|\s)\d+\s*x(\s|$)"#, options: .regularExpression) != nil { return true }
            if lower.range(of: #"(^|\s)x\s*\d"#, options: .regularExpression) != nil { return true }
            // Mostly digits/punctuation with almost no letters — not a real name.
            let letters = text.filter { $0.isLetter }.count
            let digits = text.filter { $0.isNumber }.count
            return digits > 0 && letters <= 1
        }
        // The product name on the line directly ABOVE `anchor` (the qty line's left
        // column). Vision's origin is bottom-left, so "above" means a larger midY.
        // Aligns to the anchor's LEFT edge (not the price column, which lives far to
        // the right) and only accepts the immediately-preceding line — a small Y gap
        // — so it never reaches up into the header. Skips prices and qty lines.
        func nameAbove(of anchor: CGRect) -> String? {
            // A comfortable one-line gap: a few line-heights above the anchor.
            let maxGap = max(anchor.height, 0.02) * 3
            let candidate = recognized
                .filter { w in
                    w.box.midY > anchor.midY                       // strictly above
                        && w.box.midY - anchor.midY <= maxGap      // but on the adjacent line
                        && !isPrice(w.text)
                        && !looksLikeQuantityLine(w.text)
                        && w.text.contains(where: { $0.isLetter }) // a real label, not a stray number
                        && w.box.minX <= anchor.minX + 0.06        // shares the left column
                }
                .min { abs($0.box.midY - anchor.midY) < abs($1.box.midY - anchor.midY) }
            return candidate?.text.trimmingCharacters(in: .whitespaces)
        }
        // Pulls the leading quantity out of a qty line, e.g. "1x @50.000" → 1,
        // Strips qty/price fragments that OCR sometimes glues onto a name, e.g.
        // "pete goreng :6.500" → "pete goreng", "1 x nasi" → "nasi". Removes a
        // leading "<n> x", any "@price"/":price" token, and trailing bare numbers.
        func cleanName(_ text: String) -> String {
            var s = text
            s = s.replacingOccurrences(of: #"(?i)\b\d+\s*x\b"#, with: "", options: .regularExpression) // "1 x"
            s = s.replacingOccurrences(of: #"[@:]\s*[\d.,]+"#, with: "", options: .regularExpression)  // "@7.000" / ":6.500"
            s = s.replacingOccurrences(of: #"\b[\d.,]{3,}\b"#, with: "", options: .regularExpression)   // stray amounts
            s = s.replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            return s.trimmingCharacters(in: CharacterSet(charactersIn: " :-"))
        }
        // "2 x 25,000" → 2, "x3" → 3. Returns nil when no quantity is present.
        func parseQuantity(from text: String) -> Int? {
            let lower = text.lowercased()
            // "<n> x" (quantity before the multiplier) is the common receipt form.
            if let match = lower.range(of: #"\d+(?=\s*x)"#, options: .regularExpression),
               let qty = Int(lower[match]) { return qty }
            // "x <n>" fallback.
            if let match = lower.range(of: #"(?<=x)\s*\d+"#, options: .regularExpression),
               let qty = Int(lower[match].trimmingCharacters(in: .whitespaces)) { return qty }
            return nil
        }

        // Detect the PRICE COLUMN — the receipt's right-hand column of line totals.
        // A receipt repeats numbers in two places: inside the "1 x 9.000" qty line
        // (mid-left) and as the line total on the far right. Only the right column is
        // the real price; pairing on every number produces duplicates. The column is
        // found relative to the widest price (no absolute position), so it works on
        // uncropped/off-centre photos.
        let priceWords = recognized.filter { isPrice($0.text) }
        let rightmostPriceX = priceWords.map { $0.box.maxX }.max() ?? 1
        // Keep prices whose right edge sits near the rightmost — the total column.
        let priceColumn = priceWords
            .filter { $0.box.maxX >= rightmostPriceX - 0.12 }
            .sorted { $0.box.midY > $1.box.midY } // top → bottom

        // For each price in the right column, the item's row text is everything to
        // its LEFT on the same row. The name is that text, or the line above when the
        // row is a qty line.
        for priceWord in priceColumn {
            let compactPrice = priceWord.text.replacingOccurrences(of: " ", with: "")
            let leftWords = recognized
                .filter { candidate in
                    candidate.text != priceWord.text
                        && candidate.box.maxX < priceWord.box.minX      // fully left of the price column
                        && isRowAligned(candidate.box, priceWord.box)    // same row
                        && !isPrice(candidate.text)                      // not another number
                }
                .sorted { $0.box.midX < $1.box.midX }

            let sameRowText = leftWords.map { $0.text }.joined(separator: " ").trimmingCharacters(in: .whitespaces)
            var name = sameRowText
            // Default 1; override when the qty line yields an explicit count.
            var quantity = parseQuantity(from: sameRowText) ?? 1

            // Anchor the "line above" search on the LEFT column (the qty line), not
            // the price. The name sits above the qty line at the same left margin;
            // anchoring on the price box would match wide header rows on the right.
            let leftAnchor = leftWords.first?.box ?? priceWord.box

            // If the same-row label is actually a quantity/unit-price line (e.g.
            // "1x @50.000"), the real product name is on the line above — but keep
            // the quantity parsed from that qty line.
            if name.isEmpty || looksLikeQuantityLine(name) {
                if let above = nameAbove(of: leftAnchor), !above.isEmpty {
                    name = above
                }
            } else {
                // A plain product row (no qty line) has quantity 1.
                quantity = 1
            }

            // Strip any qty/price fragments OCR glued onto the name.
            name = cleanName(name)

            // Drop rows with no real name left after cleaning, or with no letters
            // (headers/totals handled separately below).
            guard !name.isEmpty, name.contains(where: { $0.isLetter }) else { continue }
            itemsAndPrice.append([name, normalizeString(name), compactPrice, String(quantity)])
        }

        // Summary / footer lines that are never items or tax. Checked FIRST so a
        // subtotal like "Sub Total (exc. tax)" is not misfiled as tax just because
        // it contains the word "tax".
        let summaryKeywords: [String] = [
            "subtotal", "total", "bayar", "tunai", "kembali", "kembalian",
            "change", "cash", "dibayar", "grandtotal", "jumlah", "uang"
        ]

        for item in itemsAndPrice {
            let normalized = item[1]
            let priceValue = stringToFloat(item[2])

            // 1) Summary/footer line — capture the grand total, otherwise ignore.
            if summaryKeywords.contains(where: { normalized.contains($0) }) {
                // Prefer the "total bayar/dibayar" (amount due) as the spending total,
                // and fall back to a plain "total" — but never a subtotal or change.
                let isGrandTotal = (normalized.contains("bayar") || normalized.contains("dibayar"))
                    || (normalized.contains("total") && !normalized.contains("subtotal") && !normalized.contains("suhtotal"))
                if isGrandTotal && !normalized.contains("kembali") {
                    self.totalSpending = priceValue
                }
                continue
            }

            // 2) Tax.
            if taxKeywords.contains(where: { normalized.contains($0) }) {
                additionalCharges.append(AdditionalCharge(additionalChargeType: .tax, amount: priceValue))
                continue
            }

            // 3) Service charge.
            if serviceKeywords.contains(where: { normalized.contains($0) }) {
                additionalCharges.append(AdditionalCharge(additionalChargeType: .service, amount: priceValue))
                continue
            }

            // 4) A line item. The right-column price is the line TOTAL (qty already
            // applied), so store the per-unit price so price × quantity reconstructs it.
            let quantity = (item.count > 3 ? Int(item[3]) : nil) ?? 1
            let unitPrice = quantity > 1 ? priceValue / Float(quantity) : priceValue
            items.append(ExpenseItem(itemName: item[0], itemPrice: unitPrice, itemQuantity: Float(quantity)))
        }

        // ── Single verification dump ──────────────────────────────────────────
        // The raw OCR rows (grouped by line, top→bottom) plus the parsed result as
        // JSON. Copy from the console (filter "ReceiptOCR") into an AI to re-parse
        // the same receipt and compare against the on-device parse. Sole OCR log.
        var rows: [[RecognizedWord]] = []
        for word in readingOrder {
            if let anchor = rows.last?.first,
               abs(anchor.box.midY - word.box.midY) <= max(anchor.box.height, word.box.height) * 0.6 {
                rows[rows.count - 1].append(word)
            } else {
                rows.append([word])
            }
        }
        let rowLines: [String] = rows.map { row in
            row.sorted { $0.box.midX < $1.box.midX }.map(\.text).joined(separator: "  ")
        }
        // Keep the rows for the AI refinement step (custom split + attached image).
        self.lastOCRLines = rowLines
        let rawLines = rowLines.joined(separator: "\n")

        // JSON in the exact schema the AI should return (integers, no separators),
        // so the on-device output and the AI output are directly comparable.
        func money(_ v: Float) -> String { String(Int(v.rounded())) }
        let itemsJSON = items.map { item in
            let line = item.itemPrice * item.itemQuantity
            return "    { \"name\": \"\(item.itemName)\", \"quantity\": \(Int(item.itemQuantity)), \"unit_price\": \(money(item.itemPrice)), \"line_total\": \(money(line)) }"
        }.joined(separator: ",\n")
        let chargesJSON = additionalCharges.map { charge in
            "    { \"type\": \"\(charge.additionalChargeType)\", \"amount\": \(money(charge.amount)) }"
        }.joined(separator: ",\n")

        let dump = """

        ══════════ RECEIPT OCR — VERIFICATION DUMP ══════════
        RAW LINES (top → bottom):
        \(rawLines)

        PARSED (on-device) as JSON:
        {
          "items": [
        \(itemsJSON)
          ],
          "additional_charges": [
        \(chargesJSON)
          ],
          "total": \(money(totalSpending)),
          "currency": "IDR"
        }

        ↑ Paste RAW LINES to an AI, ask for the same JSON schema, then compare
          against PARSED to confirm the on-device parse.
        ═════════════════════════════════════════════════════
        """
        os_log(.info, log: .ocr, "%{public}@", dump)
    }

    /// Builds an on-device draft from the current OCR result, in the schema the
    /// backend/AI expect.
    private func buildReceiptDraft() -> ReceiptDraft {
        let draftItems = items.map { item in
            ReceiptDraftItem(
                name: item.itemName,
                quantity: Int(item.itemQuantity),
                unit_price: Double(item.itemPrice),
                line_total: Double(item.itemPrice * item.itemQuantity)
            )
        }
        let draftCharges = additionalCharges.map { charge in
            ReceiptDraftCharge(type: charge.additionalChargeType, name: charge.additionalChargeType, amount: Double(charge.amount))
        }
        let subtotal = items.reduce(0) { $0 + Double($1.itemPrice * $1.itemQuantity) }
        return ReceiptDraft(
            items: draftItems,
            additional_charges: draftCharges,
            subtotal: subtotal,
            total: Double(totalSpending),
            currency: "IDR"
        )
    }

    /// Refines the on-device OCR result with the AI (custom-split flow, only when a
    /// receipt image was attached). Sends the raw OCR lines + the heuristic draft
    /// and replaces items/charges with the refined result. Returns false and leaves
    /// the on-device parse untouched on any failure, so the flow degrades gracefully.
    @MainActor
    @discardableResult
    func refineReceiptWithAI() async -> Bool {
        guard ENV.RECEIPT_AI_REFINE_ENABLED, !lastOCRLines.isEmpty else { return false }
        isApiCallLoading = true
        defer { isApiCallLoading = false }
        do {
            let refined = try await ReceiptParseService.shared.parse(lines: lastOCRLines, draft: buildReceiptDraft())
            applyRefinedReceipt(refined)
            return true
        } catch {
            print("Receipt AI refinement failed: \(error)")
            return false
        }
    }

    /// Replaces the current items/charges/total with an AI-refined receipt.
    private func applyRefinedReceipt(_ receipt: ReceiptParseResponse) {
        items = receipt.items.map { item in
            ExpenseItem(itemName: item.name, itemPrice: Float(item.unit_price), itemQuantity: Float(max(item.quantity, 1)))
        }
        additionalCharges = receipt.additional_charges.map { charge in
            AdditionalCharge(
                additionalChargeType: AdditionalChargeType(rawValue: charge.type) ?? .other,
                amount: Float(charge.amount)
            )
        }
        if receipt.total > 0 {
            totalSpending = Float(receipt.total)
        }
        calculateTotal()
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
    func finalizeExpense(_ event: EventData) async -> Bool {
        guard let selectedCoverer, let selectedMethod else {
            print("Error")
            return false
        }
        isApiCallLoading = true
        defer { isApiCallLoading = false }

        do {
            // Upload the receipt just-in-time (only when finishing the expense),
            // so abandoned add-flows never create orphaned images. Aborts the
            // create on upload failure rather than silently dropping the receipt.
            let receiptId = try await uploadReceiptIfNeeded()
            // Creator is the acting user; the backend infers it from auth, we set
            // it locally so the model is correct before the next fetch.
            let creator = SwiftDataService.shared.getCurrentUser()
            let expense = Expense(name: expenseName, coverer: selectedCoverer, creator: creator, price: totalSpending, splitMethod: selectedMethod, participants: selectedParticipants)
            expense.receiptId = receiptId
            applyLineItems(to: expense, method: selectedMethod)

            let response = try await ExpenseService.shared.createExpense(event: event, expense: expense)
            expense.expenseId = response.expense_id
            expense.isSynced = true
            event.expenses.append(expense)
            SwiftDataService.shared.saveModelContext()
        } catch {
            print("Create expense failed: \(error)")
            return false
        }
        // Clear the in-flight receipt state so the shared `uploadedReceiptImage`
        // does not survive the post-finalize popToRoot and re-trigger the
        // receipt-review push from EventDetailView's onChange observer.
        clearReceiptState()
        return true
    }

    @MainActor
    func handleDeleteExpense(event: EventData?) async -> Bool {
        guard let expense = selectedExpense, let event else { return false }
        isApiCallLoading = true
        defer { isApiCallLoading = false }

        do {
            try await ExpenseService.shared.deleteExpense(expense: expense)
            event.expenses.removeAll(where: { $0 == expense })
            SwiftDataService.shared.saveModelContext()
        } catch {
            print("Expense delete failed: \(error)")
            return false
        }
        return true
    }

    @MainActor
    func handleUpdateExpense (event: EventData) async -> Bool {
        guard let expense = selectedExpense, let selectedCoverer = selectedCoverer, let selectedMethod = selectedMethod else { return false }
        isApiCallLoading = true
        defer { isApiCallLoading = false }

        // Snapshot the local model so a failed request can be rolled back — the
        // API is the source of truth, and the on-screen expense must not keep
        // edits that were never persisted.
        let snapshot = ExpenseSnapshot(expense)

        do {
            // Upload a newly attached receipt just-in-time before persisting.
            let receiptId = try await uploadReceiptIfNeeded()
            expense.coverer = selectedCoverer
            expense.price = totalSpending
            expense.splitMethod = selectedMethod.id
            expense.participants = selectedParticipants
            expense.receiptId = receiptId
            // Reuse the current line item on equally-split so the update mutates
            // it in place (keeping its id) rather than orphaning the old row.
            applyLineItems(to: expense, method: selectedMethod, reusing: expense.items.first)

            try await ExpenseService.shared.updateExpense(expense: expense)
            SwiftDataService.shared.saveModelContext()
        } catch {
            snapshot.restore(to: expense)
            print("Update expense failed: \(error)")
            return false
        }
        clearReceiptState()
        return true
    }
}

/// Captures the mutable fields of an `Expense` so an in-place edit can be rolled
/// back when the update request fails. The API is the source of truth; on failure
/// the on-screen model must return to exactly what was last persisted.
private struct ExpenseSnapshot {
    let coverer: UserData
    let price: Float
    let splitMethod: SplitMethod.ID
    let items: [ExpenseItem]
    let additionalCharges: [AdditionalCharge]
    let participants: [UserData]
    let receiptId: String?

    init(_ expense: Expense) {
        coverer = expense.coverer
        price = expense.price
        splitMethod = expense.splitMethod
        items = expense.items
        additionalCharges = expense.additionalCharges
        participants = expense.participants
        receiptId = expense.receiptId
    }

    func restore(to expense: Expense) {
        expense.coverer = coverer
        expense.price = price
        expense.splitMethod = splitMethod
        expense.items = items
        expense.additionalCharges = additionalCharges
        expense.participants = participants
        expense.receiptId = receiptId
    }
}
