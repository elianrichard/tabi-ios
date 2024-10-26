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
            validateName()
        }
    }
    var phoneNumber: String = "" {
        didSet {
            validatePhoneNumber()
        }
    }
    var password: String = ""  {
        didSet {
            validatePassword()
            validateConfirmPassword()
        }
    }
    var confirmPassword: String = "" {
        didSet {
            validatePassword()
            validateConfirmPassword()
        }
    }
    
    var nameError: String?
    var phoneNumberError: String?
    var passwordError: String?
    var confirmPasswordError: String?
    
    var isSignUpEnabled: Bool {
        if (!hasSubmitted) { return true }
        else { return isFormValid() }
    }
    var hasSubmitted = false
    
    func validateName() {
        guard hasSubmitted else { return }
        if name.isEmpty {
            nameError = "Name cannot be empty"
        } else {
            nameError = nil
        }
    }
    
    func validatePhoneNumber() {
        guard hasSubmitted else { return }
        phoneNumberError = phoneNumber.validatePhoneNumber()
    }
    
    func validatePassword() {
        guard hasSubmitted else { return }
        if password.count < 8 {
            passwordError = "Password must be at least 8 characters long"
        } else {
            passwordError = nil
        }
    }
    
    func validateConfirmPassword() {
        guard hasSubmitted else { return }
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
    
    func register() {
        hasSubmitted = true
        guard isFormValid() else {
            print("Cannot register: form is invalid")
            return
        }
        print("Registering with name: \(name), phone number: \(phoneNumber), password: \(password)")
    }
}
