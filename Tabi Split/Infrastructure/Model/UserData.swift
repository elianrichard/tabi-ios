//
//  UserData.swift
//  Tabi
//
//  Created by Elian Richard on 08/10/24.
//

import SwiftUI
import SwiftData

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
    var isFavorite: Bool
    
    init(name: String, bank: BankEnum, bankNumber: String, isFavorite: Bool = false) {
        self.id = UUID()
        self.name = name
        self.bank = bank
        self.bankNumber = bankNumber
        self.isFavorite = isFavorite
    }
}

enum BankEnum: String, Identifiable {
    case bca, bni, mandiri
    
    var id: String { rawValue }
    
    var bankName: String {
        switch self {
        case .bca:
            "Bank BCA"
        case .bni:
            "Bank BNI"
        case .mandiri:
            "Bank Mandiri"
        }
    }
    
    var bankLogo: ImageResource {
        switch self {
        case .bca:
                .bankBcaLogo
        case .bni:
                .bankBniLogo
        case .mandiri:
                .bankMandiriLogo
        }
    }
    
    static var allCases: [BankEnum] = [
        .bca, .bni, .mandiri
    ]
}
