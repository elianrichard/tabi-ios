//
//  RegisterViewModel.swift
//  Tabi
//
//  Created by ahmad naufal alfakhar on 09/10/24.
//

import Foundation
import JWTDecode

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
        
        print(nameError, phoneNumberError, passwordError, confirmPasswordError)
        
        return (
            nameError == nil &&
            phoneNumberError == nil &&
            passwordError == nil &&
            confirmPasswordError == nil
        )
    }
    
    @MainActor
    func register() async -> Bool {
        isSubmitted = true
        print(isFormValid())
        guard isFormValid() else {
            isSignUpEnabled = false
            print("Cannot register: form is invalid")
            isLoading = false
            return false
        }
        isLoading = true
        do {
            let phone = phoneNumber.formattedAsPhoneNumber()
            let _ = try await AuthenticationService.shared.register(name: name, phone: phone, password: password)
            let response = try await AuthenticationService.shared.login(phone: phoneNumber.formattedAsPhoneNumber(), password: password)
            let jwt = try decode(jwt: response.token)
            guard let userId = jwt["userId"].string else {
                passwordError = "User ID not found in Token"
                return false
            }
            let user = CurrentUserDefaults(userName: response.full_name, userPhone: phoneNumber.formattedAsPhoneNumber(), userImage: response.profile_image, userId: userId)
            UserDefaultsService.shared.saveCurrentUser(user: user)
            SwiftDataService.shared.saveCurrentUser(user: user)
        } catch {
            print("Register failed: \(error)")
            passwordError = "\(error)"
            isLoading = false
            return false
        }
        isLoading = false
        return true
    }
}
