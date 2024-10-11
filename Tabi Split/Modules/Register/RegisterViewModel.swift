//
//  RegisterViewModel.swift
//  Tabi
//
//  Created by ahmad naufal alfakhar on 09/10/24.
//

import Foundation

@Observable
class RegisterViewModel {
    var name: String = ""
    var phoneNumber: String = ""
    var password: String = "" 
    var confirmPassword: String = "" {
        didSet {
            validateConfirmPassword()
        }
    }
    
    var nameError: String?
    var phoneNumberError: String?
    var passwordError: String?
    var confirmPasswordError: String?
    
    var hasAttemptedValidation = false
    
    func validateName() {
        if name.isEmpty {
            nameError = "Name cannot be empty"
        } else {
            nameError = nil
        }
    }
    
    func validatePhoneNumber() {
        let digitsOnly = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        if !digitsOnly.hasPrefix("62") {
            phoneNumberError = "Phone number must start with 62"
        } else if digitsOnly.count < 12 || digitsOnly.count > 15 {
            phoneNumberError = "Phone number must be 10-13 digits long"
        } else {
            phoneNumberError = nil
        }
    }
    
    func validatePassword() {
        if password.count < 8 {
            passwordError = "Password must be at least 8 characters long"
        } else {
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
                confirmPasswordError = nil
            }
        }
    }
    
    func validateAllFields() {
        hasAttemptedValidation = true
        validateName()
        validatePhoneNumber()
        validatePassword()
        validateConfirmPassword()
    }
    
    func isFormValid() -> Bool {
        validateAllFields()
        return nameError == nil &&
        phoneNumberError == nil &&
        passwordError == nil &&
        confirmPasswordError == nil
    }
    
    func register() {
        guard isFormValid() else {
            print("Cannot register: form is invalid")
            return
        }
        print("Registering with name: \(name), phone number: \(phoneNumber), password: \(password)")
    }
}
