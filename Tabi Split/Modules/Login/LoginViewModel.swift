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
    
    var isLoading: Bool = false
    let authService = AuthenticationService()
    
    func login() async -> Bool {
        guard validateInput() else {
            print("Cannot register: form is invalid")
            return false
        }
        
        var isSuccess = false
        isLoading = true
        do {
            try await authService.login(phone: phoneNumber.formattedAsPhoneNumber(), password: password)
            isSuccess = true
            print("Login successful!")
        } catch {
            print("Login failed: \(error)")
            isSuccess = false
        }
        isLoading = false
        return isSuccess
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
