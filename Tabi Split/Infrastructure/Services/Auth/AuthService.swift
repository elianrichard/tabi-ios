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

    /// Exchanges a Google id_token for a Tabi session, persisting the returned
    /// tokens to the Keychain.
    func loginWithGoogle(idToken: String, name: String?, email: String?) async throws -> LoginResponse {
        try await oauthLogin(endpoint: "/auth/google", idToken: idToken, name: name, email: email)
    }

    /// Exchanges an Apple id_token for a Tabi session, persisting the returned
    /// tokens to the Keychain.
    func loginWithApple(idToken: String, name: String?, email: String?) async throws -> LoginResponse {
        try await oauthLogin(endpoint: "/auth/apple", idToken: idToken, name: name, email: email)
    }

    private func oauthLogin(endpoint: String, idToken: String, name: String?, email: String?) async throws -> LoginResponse {
        let request = OAuthRequest(id_token: idToken, name: name, email: email)
        let response: LoginResponse = try await apiClient.post(endpoint: endpoint, body: request)

        try tokenManager.saveAccessToken(response.token)
        try tokenManager.saveRefreshToken(response.refresh_token)

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
