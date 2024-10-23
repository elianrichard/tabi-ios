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
            isFormValid()
        }
    }
    var phoneNumber: String = "" {
        didSet {
            isFormValid()
        }
    }
    var password: String = ""  {
        didSet {
            isFormValid()
        }
    }
    var confirmPassword: String = "" {
        didSet {
            isFormValid()
        }
    }
    
    var nameError: String?
    var phoneNumberError: String?
    var passwordError: String?
    var confirmPasswordError: String?
    
    var isSignUpEnabled = true
    var hasSubmitted = false
    
    func validateName() {
        if name.isEmpty {
            nameError = "Name cannot be empty"
        } else {
            nameError = nil
        }
    }
    
    func validatePhoneNumber() {
        phoneNumberError = phoneNumber.validatePhoneNumber()
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
        validateName()
        validatePhoneNumber()
        validatePassword()
        validateConfirmPassword()
    }
    
    func isFormValid() -> Bool {
        guard hasSubmitted else { return true }
        validateAllFields()
        if (nameError == nil &&
            phoneNumberError == nil &&
            passwordError == nil &&
            confirmPasswordError == nil
        ) {
            isSignUpEnabled = true
            return true
        } else {
            isSignUpEnabled = false
            return false
        }
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
