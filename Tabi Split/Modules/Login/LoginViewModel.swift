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
    
    @MainActor
    func login() async -> Bool {
        guard validateInput() else {
            print("Cannot register: form is invalid")
            return false
        }
        
        var isSuccess = false
        isLoading = true
        do {
            let response = try await AuthenticationService.shared.login(phone: phoneNumber.formattedAsPhoneNumber(), password: password)
            isSuccess = true
            let user = CurrentUserDefaults(userName: response.full_name, userPhone: phoneNumber.formattedAsPhoneNumber(), userImage: response.profile_image, userId: "userId")
            UserDefaultsService.shared.saveCurrentUser(user: user)
            SwiftDataService.shared.saveCurrentUser(user: user)
        } catch {
            print("Login failed: \(error)")
            passwordError = "\(error)"
            isSuccess = false
        }
        isLoading = false
        return isSuccess
    }
    
    @MainActor
    func guestLogin() -> Bool {
        let user = CurrentUserDefaults(userName: "Guest", userPhone: "Guest", userImage: "owl", userId: "")
        UserDefaultsService.shared.saveCurrentUser(user: user)
        SwiftDataService.shared.saveCurrentUser(user: user)
        return true
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
