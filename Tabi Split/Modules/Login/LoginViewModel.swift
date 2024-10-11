//
//  LoginViewModel.swift
//  Tabi
//
//  Created by ahmad naufal alfakhar on 09/10/24.
//

import Foundation

@Observable
class LoginViewModel {
    var phoneNumber: String = ""
    var password: String = ""
    
    func login() {
        // Implement login logic
        print("Logging in with phone number: \(phoneNumber) and password: \(password)")
    }
}
