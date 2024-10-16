//
//  UserData.swift
//  Tabi
//
//  Created by Elian Richard on 08/10/24.
//

import Foundation
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
    var bankName: String
    var bankNumber: String
    var isFavorite: Bool
    
    init(name: String, bankName: String, bankNumber: String, isFavorite: Bool = false) {
        self.id = UUID()
        self.name = name
        self.bankName = bankName
        self.bankNumber = bankNumber
        self.isFavorite = isFavorite
    }
}
