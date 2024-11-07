//
//  UserData.swift
//  Tabi
//
//  Created by Elian Richard on 08/10/24.
//

import SwiftUI
import SwiftData
import SwiftUI

@Model
class UserData {
    var name: String
    var phone: String
    
    init(name: String, phone: String) {
        self.name = name
        self.phone = phone
    }
}

struct PaymentMethod: Identifiable {
    var id: UUID
    var name: String
    var bank: BankEnum
    var bankNumber: String
    var logoImage: UIImage?
    var isFavorite: Bool
    
    init(name: String, bank: BankEnum, bankNumber: String, isFavorite: Bool = false) {
        self.id = UUID()
        self.name = name
        self.bank = bank
        self.bankNumber = bankNumber
        self.isFavorite = isFavorite
    }
}

enum BankEnum: Identifiable, CaseIterable {
    case bca
    case bni
    case bri
    case seabank
    case ovo
    case shopeePay
    case goPay
    case mandiri
    
    var id: String {
        switch self {
        case .bca:
            "bca"
        case .bni:
            "bni"
        case .bri:
            "bri"
        case .seabank:
            "seabank"
        case .ovo:
            "ovo"
        case .shopeePay:
            "shopeepay"
        case .goPay:
            "gopay"
        case .mandiri:
            "mandiri"
        }
    }
    
    var bankName: String {
        switch self {
        case .bca:
            "Bank BCA"
        case .bni:
            "Bank BNI"
        case .bri:
            "Bank BRI"
        case .seabank:
            "Seabank"
        case .ovo:
            "OVO"
        case .shopeePay:
            "Shopee Pay"
        case .goPay:
            "Gopay"
        case .mandiri:
            "Bank Mandiri"
        }
    }
    
    var isPopular: Bool {
        switch self {
        case .bca:
            true
        case .bni:
            true
        case .bri:
            true
        case .seabank:
            false
        case .ovo:
            false
        case .shopeePay:
            false
        case .goPay:
            false
        case .mandiri:
            false
        }
    }
    
    var bankLogo: UIImage{
        switch self {
        case .bca:
                .BCA
        case .bni:
                .BNI
        case .bri:
                .BRI
        case .seabank:
                .seaBank
        case .ovo:
                .OVO
        case .shopeePay:
                .shopeePay
        case .goPay:
                .goPay
        case .mandiri:
                .bankMandiriLogo
        }
    }
    
    static var allCases: [BankEnum] {
        [.bca, .bni, .bri, .seabank, .ovo, .shopeePay, .goPay, .mandiri]
    }
}
