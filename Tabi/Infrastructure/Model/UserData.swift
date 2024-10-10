//
//  UserData.swift
//  Tabi
//
//  Created by Elian Richard on 10/10/24.
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
