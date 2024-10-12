//
//  String+Ext.swift
//  Tabi
//
//  Created by Elian Richard on 06/10/24.
//

extension String {
    func formatPrice() -> String {
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
        if isNegative {
            return "-\(final)"
        }
        return final
    }
    
    func removeDots() -> String {
        return self.replacingOccurrences(of: ".", with: "")
    }
    
    func getFirstName() -> String {
        return String(self.split(separator: " ").first ?? "")
    }
}
