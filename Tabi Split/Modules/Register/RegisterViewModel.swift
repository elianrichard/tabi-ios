//
//  RegisterViewModel.swift
//  Tabi
//
//  Created by ahmad naufal alfakhar on 09/10/24.
//

import Foundation

@Observable
class RegisterViewModel {
    var name: String = "" {
        didSet {
            if isSubmitted {
                validateName()
            }
        }
    }
    var phoneNumber: String = "" {
        didSet {
            if isSubmitted {
                validatePhoneNumber()
            }
        }
    }
    var password: String = ""  {
        didSet {
            if isSubmitted {
                validatePassword()
            }
        }
    }
    var confirmPassword: String = "" {
        didSet {
            if isSubmitted {
                validatePassword()
                validateConfirmPassword()
            }
        }
    }
    
    var nameError: String?
    var phoneNumberError: String?
    var passwordError: String?
    var confirmPasswordError: String?
    
    var isLoading: Bool = false
    var isSubmitted: Bool = false
    
    var isSignUpEnabled: Bool = true
    
    func validateName() {
        if name.isEmpty {
            nameError = "Name cannot be empty"
        } else {
            isSignUpEnabled = true
            nameError = nil
        }
    }
    
    func validatePhoneNumber() {
        let error = phoneNumber.validatePhoneNumber()
        phoneNumberError = error
        if error == nil {
            isSignUpEnabled = true
        }
    }
    
    func validatePassword() {
        if password.count < 8 {
            passwordError = "Password must be at least 8 characters long"
        } else {
            isSignUpEnabled = true
            passwordError = nil
        }
    }
    
    func validateConfirmPassword() {
        if password.isEmpty {
            confirmPasswordError = "Password cannot be empty"
        } else {
            if confirmPassword != password {
                confirmPasswordError = "Passwords do not match"
            } else {
                isSignUpEnabled = true
                confirmPasswordError = nil
            }
        }
    }
    
    func isFormValid() -> Bool {
        validateName()
        validatePhoneNumber()
        validatePassword()
        validateConfirmPassword()
        
        return (
            nameError == nil &&
            phoneNumberError == nil &&
            passwordError == nil &&
            confirmPasswordError == nil
        )
    }
    
    func register() async -> Bool {
        isSubmitted = true
        guard isFormValid() else {
            isSignUpEnabled = false
            print("Cannot register: form is invalid")
            return false
        }
        var isSuccess = false
        isLoading = true
        do {
            let _ = try await AuthenticationService.shared.register(name: name, phone: phoneNumber.formattedAsPhoneNumber(), password: password)
            isSuccess = true
        } catch {
            print("Register failed: \(error)")
            passwordError = "\(error)"
            isSuccess = false
        }
        isLoading = false
        return isSuccess
    }
}
