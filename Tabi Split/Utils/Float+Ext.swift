//
//  Float+Ext.swift
//  Tabi Split
//
//  Created by Elian Richard on 14/10/24.
//

import Foundation

extension Float {
    func formatPrice(isShowSign: Bool = true) -> String {
        guard self.isFinite else { return "0" }
        return String(Int(self)).formatPrice(isShowSign: isShowSign)
    }
    
    func properRound() -> Float {
        return self.rounded(.toNearestOrAwayFromZero)
    }
    
    func rounded(toDecimalPlaces places: Int) -> Float {
        let multiplier = pow(10, Float(places))
        return (self * multiplier).rounded() / multiplier
    }
}
