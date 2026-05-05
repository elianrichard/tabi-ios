//
//  LoginViewModel.swift
//  Tabi
//
//  Created by ahmad naufal alfakhar on 09/10/24.
//

import Foundation
import JWTDecode

@Observable
class LoginViewModel {
    static var shared = LoginViewModel()
    var phoneNumber: String = ""
    var password: String = ""

    var phoneNumberError: String?
    var passwordError: String?
    var error: AppError?

    var isLoading: Bool = false

    @MainActor
    func login() async -> Bool {
        guard validateInput() else { return false }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await AuthenticationService.shared.login(
                phone: phoneNumber.formattedAsPhoneNumber(),
                password: password
            )
            let jwt = try decode(jwt: response.token)
            guard let userId = jwt["userId"].string else {
                passwordError = "User ID not found in Token"
                return false
            }
            let user = CurrentUserDefaults(
                userName: response.full_name,
                userPhone: phoneNumber.formattedAsPhoneNumber(),
                userImage: response.profile_image,
                userId: userId
            )
            UserDefaultsService.shared.saveCurrentUser(user: user)
            SwiftDataService.shared.saveCurrentUser(user: user)
        } catch {
            passwordError = "Account credential is invalid"
            self.error = .from(error)
            return false
        }
        return true
    }

    @MainActor
    func guestLogin() -> Bool {
        let user = CurrentUserDefaults(userName: "Guest", userPhone: "Guest", userImage: "owl", userId: "")
        UserDefaultsService.shared.saveCurrentUser(user: user)
        SwiftDataService.shared.saveCurrentUser(user: user)
        return true
    }

    func validateInput() -> Bool {
        var isValid = true
        phoneNumberError = nil
        passwordError = nil

        if phoneNumber.isEmpty {
            phoneNumberError = "Please input your phone number"
            isValid = false
        }

        if password.isEmpty {
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
