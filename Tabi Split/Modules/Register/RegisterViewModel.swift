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
        didSet { if isSubmitted { validateName() } }
    }
    var phoneNumber: String = "" {
        didSet { if isSubmitted { validatePhoneNumber() } }
    }
    var password: String = "" {
        didSet { if isSubmitted { validatePassword() } }
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
    var error: AppError?

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
        let phoneError = phoneNumber.validatePhoneNumber()
        phoneNumberError = phoneError
        if phoneError == nil { isSignUpEnabled = true }
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
        } else if confirmPassword != password {
            confirmPasswordError = "Passwords do not match"
        } else {
            isSignUpEnabled = true
            confirmPasswordError = nil
        }
    }

    func isFormValid() -> Bool {
        validateName()
        validatePhoneNumber()
        validatePassword()
        validateConfirmPassword()
        return nameError == nil && phoneNumberError == nil && passwordError == nil && confirmPasswordError == nil
    }

    @MainActor
    func register() async -> Bool {
        isSubmitted = true
        guard isFormValid() else {
            isSignUpEnabled = false
            return false
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let phone = phoneNumber.formattedAsPhoneNumber()
            let _ = try await AuthenticationService.shared.register(name: name, phone: phone, password: password)
            let response = try await AuthenticationService.shared.login(phone: phone, password: password)
            let jwt = try decode(jwt: response.token)
            guard let userId = jwt["userId"].string else {
                passwordError = "User ID not found in Token"
                return false
            }
            let user = CurrentUserDefaults(
                userName: response.full_name,
                userPhone: phone,
                userImage: response.profile_image,
                userId: userId
            )
            UserDefaultsService.shared.saveCurrentUser(user: user)
            SwiftDataService.shared.saveCurrentUser(user: user)
        } catch {
            passwordError = error.localizedDescription
            self.error = .from(error)
            return false
        }
        return true
    }
}
