//
//  Float+Ext.swift
//  Tabi Split
//
//  Created by Elian Richard on 14/10/24.
//

import Foundation

extension Float {
    func formatPrice() -> String {
        return String(Int(self)).formatPrice()
    }
    
    func properRound() -> Float {
        return self.rounded(.toNearestOrAwayFromZero)
    }
}
