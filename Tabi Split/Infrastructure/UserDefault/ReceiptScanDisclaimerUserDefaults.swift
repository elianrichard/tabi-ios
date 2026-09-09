//
//  ReceiptScanDisclaimerUserDefaults.swift
//  Tabi Split
//
//  Persists whether the user ticked "Do not show again" on the receipt-scan
//  disclaimer. Reset on login so each fresh session shows the disclaimer once
//  until dismissed.
//

extension UserDefaultsService {
    func setReceiptScanDisclaimerDismissed(_ value: Bool) {
        setBasicValue(value, forKey: .receiptScanDisclaimerDismissed)
    }

    func getReceiptScanDisclaimerDismissed() -> Bool {
        (getBasicValue(forKey: .receiptScanDisclaimerDismissed) as? Bool) ?? false
    }

    /// Clears the "do not show again" choice so the disclaimer shows again next
    /// time. Called on login.
    func resetReceiptScanDisclaimer() {
        deleteKeyValue(forKey: .receiptScanDisclaimerDismissed)
    }
}
