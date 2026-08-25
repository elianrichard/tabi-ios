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

    var isLoading: Bool = false
    var errorMessage: String? = nil

    /// The email of the account that just signed in, so the view can key the
    /// device-owner wipe check and migration off it.
    private(set) var lastSignedInEmail: String = ""

    @MainActor
    func signInWithGoogle() async -> Bool {
        await signIn {
            let credential = try await ProviderSignIn.shared.signInWithGoogle()
            let response = try await AuthenticationService.shared.loginWithGoogle(
                idToken: credential.idToken, name: credential.name, email: credential.email)
            return (response, credential)
        }
    }

    @MainActor
    func signInWithApple() async -> Bool {
        await signIn {
            let credential = try await ProviderSignIn.shared.signInWithApple()
            let response = try await AuthenticationService.shared.loginWithApple(
                idToken: credential.idToken, name: credential.name, email: credential.email)
            return (response, credential)
        }
    }

    @MainActor
    private func signIn(_ perform: () async throws -> (LoginResponse, ProviderCredential)) async -> Bool {
        isLoading = true
        errorMessage = nil
        do {
            let (response, credential) = try await perform()
            let jwt = try decode(jwt: response.token)
            guard let userId = jwt["userId"].string else {
                errorMessage = "User ID not found in Token"
                isLoading = false
                return false
            }
            // Prefer the email the backend echoes; fall back to the provider's.
            let email = response.email ?? credential.email ?? ""
            lastSignedInEmail = email
            let user = CurrentUserDefaults(
                userName: response.full_name,
                userEmail: email,
                userImage: response.profile_image,
                userId: userId
            )
            UserDefaultsService.shared.saveCurrentUser(user: user)
            // Promote any pre-existing Guest UserData in place so it matches the
            // freshly-authed identity, avoiding a duplicate UserData row.
            SwiftDataService.shared.promoteGuestUserData(to: user)
            SwiftDataService.shared.saveCurrentUser(user: user)
        } catch let providerError as ProviderSignInError {
            // User backing out of the provider sheet is not an error to surface.
            if case .cancelled = providerError {
                isLoading = false
                return false
            }
            print("Sign-in failed: \(providerError)")
            errorMessage = providerError.localizedDescription
            isLoading = false
            return false
        } catch {
            print("Sign-in failed: \(error)")
            errorMessage = "Sign-in failed. Please try again."
            isLoading = false
            return false
        }
        isLoading = false
        return true
    }

    @MainActor
    func guestLogin() -> Bool {
        let user = CurrentUserDefaults(userName: "Guest", userEmail: "Guest", userImage: "owl", userId: "")
        UserDefaultsService.shared.saveCurrentUser(user: user)
        SwiftDataService.shared.saveCurrentUser(user: user)
        return true
    }
}
