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
        await signIn { mergeToken in
            let credential = try await ProviderSignIn.shared.signInWithGoogle()
            let response = try await AuthenticationService.shared.loginWithGoogle(
                idToken: credential.idToken, name: credential.name, email: credential.email,
                mergeFromGuestToken: mergeToken)
            return (response, credential)
        }
    }

    @MainActor
    func signInWithApple() async -> Bool {
        await signIn { mergeToken in
            let credential = try await ProviderSignIn.shared.signInWithApple()
            let response = try await AuthenticationService.shared.loginWithApple(
                idToken: credential.idToken, name: credential.name, email: credential.email,
                mergeFromGuestToken: mergeToken)
            return (response, credential)
        }
    }

    /// When the current session is a guest, its access token — sent to the backend
    /// as `merge_from_guest_token` so the guest's events/expenses are absorbed into
    /// the provider account being signed into. Nil for a normal (non-guest) sign-in.
    private func guestMergeToken() -> String? {
        guard UserDefaultsService.shared.getCurrentUser()?.kind == "guest" else { return nil }
        return try? KeychainService.shared.getAccessToken()
    }

    @MainActor
    private func signIn(_ perform: (_ mergeToken: String?) async throws -> (LoginResponse, ProviderCredential)) async -> Bool {
        isLoading = true
        errorMessage = nil
        // Capture the guest merge token BEFORE the provider login overwrites the
        // stored tokens/current user.
        let mergeToken = guestMergeToken()
        do {
            let (response, credential) = try await perform(mergeToken)
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
                userId: userId,
                kind: "real"
            )
            UserDefaultsService.shared.saveCurrentUser(user: user)
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

    /// Creates a server-backed guest session. The guest is a real (credential-less)
    /// backend account, so it runs every authed endpoint and — unlike the old
    /// local-only "Guest" — its data is server-persisted from the first tap. On
    /// success the current user is stored with a real userId and kind == "guest".
    /// Returns the created UserData on success, or nil (with `errorMessage` set) on
    /// failure; guest mode now requires connectivity.
    @MainActor
    func guestLogin() async -> UserData? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await AuthenticationService.shared.guestSignIn()
            let jwt = try decode(jwt: response.token)
            guard let userId = jwt["userId"].string else {
                errorMessage = "User ID not found in Token"
                return nil
            }
            let user = CurrentUserDefaults(
                userName: response.full_name,
                userEmail: response.email ?? "",
                userImage: response.profile_image,
                userId: userId,
                kind: "guest"
            )
            UserDefaultsService.shared.saveCurrentUser(user: user)
            SwiftDataService.shared.saveCurrentUser(user: user)
            let image = ProfileImageEnum(rawValue: response.profile_image)
            return UserData(userId: userId, name: response.full_name, email: response.email ?? "", image: image, imageUrl: nil)
        } catch {
            print("Guest sign-in failed: \(error)")
            errorMessage = "Couldn't start a guest session. Check your connection and try again."
            return nil
        }
    }
}
