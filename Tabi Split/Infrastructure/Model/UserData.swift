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
    var userId: String = ""
    var name: String
    var phone: String
    var image: ProfileImageEnum.ID
    var imageUrl: String?
    @Relationship(deleteRule: .nullify, inverse: \EventData.participants) var events: [EventData]? = []
    @Relationship(deleteRule: .nullify, inverse: \Expense.participants) var expenses: [Expense]? = []
    @Relationship(deleteRule: .nullify, inverse: \Expense.coverer) var coveredExpenses: [Expense]? = []
    @Relationship(deleteRule: .cascade, inverse: \ExpensePerson.user) var expenseShare: [ExpensePerson]? = []
    
    init(userId: String = "", name: String, phone: String, image: ProfileImageEnum? = nil, imageUrl: String? = nil) {
        self.userId = userId
        self.name = name != "" ? name : "Deleted User"
        self.phone = phone
        self.image = (image ?? ProfileImageEnum.allCases.randomElement() ?? .owl).id
        self.imageUrl = imageUrl
    }
    
    init(userBase: UserBase) {
        self.userId = userBase.user_id
        self.name = userBase.name != "" ? userBase.name : "Deleted User"
        self.phone = userBase.phone ?? ""
        if let image = ProfileImageEnum(rawValue: userBase.avatar_url) {
            self.image = image.id
            self.imageUrl = ""
        } else {
            self.image = ProfileImageEnum.owl.id
            self.imageUrl = userBase.avatar_url
        }
    }
    
    func update(from user: UserData) {
        self.userId = user.userId
        self.name = user.name
        self.phone = user.phone
        self.image = user.image
        self.imageUrl = user.imageUrl
    }
    
    func update(fromUserBase user: UserBase) {
        self.update(from: UserData(userBase: user))
    }
}

enum ProfileImageEnum: String, Identifiable, CaseIterable {
    case owl, dragon, wallet, octopus
    
    var id: String { rawValue }
    
    var resource: ImageResource {
        switch self {
        case .owl:
                .owl
        case .dragon:
                .dragon
        case .wallet:
                .wallet
        case .octopus:
                .octopus
        }
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
                .mandiri
        }
    }
    
}
