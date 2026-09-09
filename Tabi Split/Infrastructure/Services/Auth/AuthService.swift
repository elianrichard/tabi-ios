//
//  AuthService.swift
//  Tabi Split
//
//  Created by ahmad naufal alfakhar on 29/10/24.
//

import Foundation

final class AuthenticationService {
    static let shared = AuthenticationService()

    private let apiClient: APIClient = APIService.shared
    private let tokenManager: TokenManaging = KeychainService.shared

    /// Creates a credential-less guest session, persisting the returned tokens to
    /// the Keychain. The guest is a real server account (kind == "guest") that runs
    /// every authed endpoint and is promoted to a real account on its first
    /// provider sign-in.
    func guestSignIn(name: String? = nil, profileImage: String? = nil) async throws -> LoginResponse {
        let request = GuestRequest(name: name, profile_image: profileImage)
        let response: LoginResponse = try await apiClient.post(endpoint: "/auth/guest", body: request)

        try tokenManager.saveAccessToken(response.token)
        try tokenManager.saveRefreshToken(response.refresh_token)

        // Fresh session: show the receipt-scan disclaimer again until dismissed.
        UserDefaultsService.shared.resetReceiptScanDisclaimer()

        return response
    }

    /// Exchanges a Google id_token for a Tabi session, persisting the returned
    /// tokens to the Keychain. Pass `mergeFromGuestToken` when upgrading a guest
    /// session so the backend absorbs the guest's data into this account.
    func loginWithGoogle(idToken: String, name: String?, email: String?, mergeFromGuestToken: String? = nil) async throws -> LoginResponse {
        try await oauthLogin(endpoint: "/auth/google", idToken: idToken, name: name, email: email, mergeFromGuestToken: mergeFromGuestToken)
    }

    /// Exchanges an Apple id_token for a Tabi session, persisting the returned
    /// tokens to the Keychain. Pass `mergeFromGuestToken` when upgrading a guest
    /// session so the backend absorbs the guest's data into this account.
    func loginWithApple(idToken: String, name: String?, email: String?, mergeFromGuestToken: String? = nil) async throws -> LoginResponse {
        try await oauthLogin(endpoint: "/auth/apple", idToken: idToken, name: name, email: email, mergeFromGuestToken: mergeFromGuestToken)
    }

    private func oauthLogin(endpoint: String, idToken: String, name: String?, email: String?, mergeFromGuestToken: String?) async throws -> LoginResponse {
        let request = OAuthRequest(id_token: idToken, name: name, email: email, merge_from_guest_token: mergeFromGuestToken)
        let response: LoginResponse = try await apiClient.post(endpoint: endpoint, body: request)

        try tokenManager.saveAccessToken(response.token)
        try tokenManager.saveRefreshToken(response.refresh_token)

        // Fresh session: show the receipt-scan disclaimer again until dismissed.
        UserDefaultsService.shared.resetReceiptScanDisclaimer()

        return response
    }

    func logout() async throws {
        try tokenManager.clearTokens()
    }

    func refresh() async throws {
        let refreshToken = try tokenManager.getRefreshToken()
        let refreshRequest = RefreshRequest(refresh_token: refreshToken)
        let response: RefreshResponse = try await apiClient.post(endpoint: "/auth/refresh", body: refreshRequest)

        try tokenManager.saveAccessToken(response.token)
    }
}
