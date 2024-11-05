//
//  UserData.swift
//  Tabi
//
//  Created by Elian Richard on 08/10/24.
//

import Foundation
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
    var name: String?
    var bankName: String
    var bankNumber: String
    var logoImage: UIImage?
    var isFavorite: Bool
    
    init(name: String, bankName: String, bankNumber: String, logoImage: UIImage = UIImage(), isFavorite: Bool = false) {
        self.id = UUID()
        self.name = name
        self.bankName = bankName
        self.bankNumber = bankNumber
        self.logoImage = logoImage
        self.isFavorite = isFavorite
    }
}

enum TemplatePaymentMethod: Identifiable, CaseIterable {
    case bca
    case bni
    case bri
    case seabank
    case ovo
    case shopeePay
    case goPay
    
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
        }
    }
    
    var name: String {
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
        }
    }
    
    var logoImage: UIImage{
        switch self {
        case .bca:
            UIImage(named: "BCA") ?? UIImage()
        case .bni:
            UIImage(named: "BNI") ?? UIImage()
        case .bri:
            UIImage(named: "BRI") ?? UIImage()
        case .seabank:
            UIImage(named: "SeaBank") ?? UIImage()
        case .ovo:
            UIImage(named: "OVO") ?? UIImage()
        case .shopeePay:
            UIImage(named: "ShopeePay") ?? UIImage()
        case .goPay:
            UIImage(named: "GoPay") ?? UIImage()
        }
    }
    
    static var allCases: [TemplatePaymentMethod] {
        [.bca, .bni, .bri, .seabank, .ovo, .shopeePay, .goPay]
    }
}
