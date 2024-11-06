//
//  SettlementPaymentMethodViewModel.swift
//  Tabi Split
//
//  Created by Elian Richard on 16/10/24.
//

import Foundation

@Observable
final class SettlementPaymentMethodViewModel {
    var user: UserData = UserData(name: "Elian", phone: "phone")
    var paymentMethods: [PaymentMethod] = [
        PaymentMethod(name: "Elian Richard", bank: .bca, bankNumber: "000123456789", isFavorite: true),
        PaymentMethod(name: "Elian Richard", bank: .bni, bankNumber: "000123456789", isFavorite: true),
        PaymentMethod(name: "Elian Richard", bank: .mandiri, bankNumber: "000123456789"),
        PaymentMethod(name: "Elian Richard", bank: .bca, bankNumber: "000123456789"),
        PaymentMethod(name: "Elian Richard", bank: .bni, bankNumber: "000123456789"),
        PaymentMethod(name: "Elian Richard", bank: .mandiri, bankNumber: "000123456789"),
    ]
    
    var favoritePaymentMethods: [PaymentMethod] {
        return paymentMethods.filter { $0.isFavorite }
    }
    
    var otherPaymentMethods: [PaymentMethod] {
        return paymentMethods.filter { !$0.isFavorite }
    }
    
    var isHasFavorite: Bool {
        return favoritePaymentMethods.count > 0
    }
}
