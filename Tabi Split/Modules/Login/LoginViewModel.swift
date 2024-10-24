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
    
    var phoneNumberError: String? = nil
    var passwordError: String? = nil
    
    func login() {
        guard validateInput() else { return }
        if password == "invalid" {
            passwordError = "Password incorrect"
            return
        }
        // Implement login logic
        print("Logging in with phone number: \(phoneNumber) and password: \(password)")
    }
    
    func validateInput () -> Bool {
        var isValid = true
        phoneNumberError = nil
        passwordError = nil
        
        if phoneNumber == "" {
            phoneNumberError = "Please input your phone number"
            isValid = false
        }
        
        if password == "" {
            passwordError = "Please input your password"
            isValid = false
        }

        if let phoneValidationError = phoneNumber.validatePhoneNumber() {
            phoneNumberError = phoneValidationError
            isValid = false
        }
        
        return isValid
    }
}
