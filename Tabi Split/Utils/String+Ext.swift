//
//  String+Ext.swift
//  Tabi
//
//  Created by Elian Richard on 06/10/24.
//

import Foundation

extension String {
    func formatPrice(isShowSign: Bool = true) -> String {
        var price = self
        let isNegative = price.hasPrefix("-")
        if isNegative {
            price = String(self.dropFirst())
        }
        let cleanPrice = price.replacingOccurrences(of: ".", with: "")
        let reversed = String(cleanPrice.reversed())
        var formatted = ""
        for (index, char) in reversed.enumerated() {
            if index != 0 && index % 3 == 0 {
                formatted.append(".")
            }
            formatted.append(char)
        }
        let final = String(formatted.reversed())
        if isNegative && isShowSign {
            return "-\(final)"
        }
        return final
    }
    
    func removeDots() -> String {
        return self.replacingOccurrences(of: ".", with: "")
    }
    
    func convertToFloat() -> Float? {
        return Float(self.removeDots())
    }
    
    func getFirstName() -> String {
        return String(self.split(separator: " ").first ?? "")
    }
    
    func validatePhoneNumber () -> String? {
        let phoneNumberLengthRegex = /^[0-9]{10,13}$/
        if !self.contains(phoneNumberLengthRegex) {
            return "Phone number should contain 10-13 digits"
        }
        
        return nil
    }
    
    func formattedAsPhoneNumber() -> String {
        // Step 1: Detect the country code for the current region
        let countryCode = Locale.current.region?.identifier ?? "ID" // Default to "ID" for Indonesia
        let dialingCode = Self.dialingCode(for: countryCode)
        
        // Step 2: Trim whitespace and check if the number needs the country code
        var formattedNumber = self.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // remove + sign in front of the phone
        if (formattedNumber.hasPrefix("+")) {
            formattedNumber.remove(at: formattedNumber.startIndex)
        }
        
        formattedNumber = formattedNumber.replacingOccurrences(of: "-", with: "")
        formattedNumber = formattedNumber.replacingOccurrences(of: "(", with: "")
        formattedNumber = formattedNumber.replacingOccurrences(of: ")", with: "")
        formattedNumber = formattedNumber.replacingOccurrences(of: " ", with: "")
        
        if formattedNumber.hasPrefix(dialingCode) {
            // Already starts with the country code, so return as is
            return formattedNumber
        } else if formattedNumber.hasPrefix("0") {
            // Starts with "0", replace it with the country code
            formattedNumber.remove(at: formattedNumber.startIndex)
            return dialingCode + formattedNumber
        } else {
            // Doesn't start with the country code or "0", so prepend the country code
            return dialingCode + formattedNumber
        }
        
    }
    
    /// Helper function to get dialing code based on country code
    private static func dialingCode(for countryCode: String) -> String {
        let dialingCodes = [
            "ID": "62", // Indonesia
            "US": "1",  // United States
            "GB": "44", // United Kingdom
            "AU": "61", // Australia
            "IN": "91", // India
            // Add other country codes as needed
        ]
        
        // Default to "62" if the country code is not found
        return dialingCodes[countryCode] ?? "62"
    }
}
