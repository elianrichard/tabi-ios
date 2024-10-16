//
//  SettlementPaymentMethodViewModel.swift
//  Tabi Split
//
//  Created by Elian Richard on 16/10/24.
//

import Foundation

@Observable
final class SettlementPaymentMethodViewModel {
    var personName: String = "Elian"
    var paymentMethods: [PaymentMethod] = [
        PaymentMethod(name: "Elian Richard", bankName: "Bank BCA", bankNumber: "000123456789", isFavorite: false),
        PaymentMethod(name: "Elian Richard", bankName: "Bank Jago", bankNumber: "000123456789", isFavorite: false),
        PaymentMethod(name: "Elian Richard", bankName: "Bank BNI", bankNumber: "000123456789"),
        PaymentMethod(name: "Elian Richard", bankName: "Bank Mandiri", bankNumber: "000123456789"),
        PaymentMethod(name: "Elian Richard", bankName: "Bank BRI", bankNumber: "000123456789"),
        PaymentMethod(name: "Elian Richard", bankName: "Bank BTPN", bankNumber: "000123456789"),
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
