//
//  AuthService.swift
//  Tabi Split
//
//  Created by ahmad naufal alfakhar on 29/10/24.
//

import Foundation

protocol AuthenticationServicing {
    func register(name: String, phone: String, password: String) async throws
    func login(phone: String, password: String) async throws
    func logout() async throws
    func refresh() async throws
}

final class AuthenticationService: AuthenticationServicing {
    private let apiClient: APIClient
    private let tokenManager: TokenManaging
    
    init(apiClient: APIClient = APIService.shared, tokenManager: TokenManaging = KeychainService.shared) {
        self.apiClient = apiClient
        self.tokenManager = tokenManager
    }
    
    func register(name: String, phone: String, password: String) async throws {
        let registerRequest = RegisterRequest(name: name, phone: phone, password: password)
        let response: RegisterResponse = try await apiClient.post(endpoint: "/auth/register", body: registerRequest)
        print(response, "register response")
    }
    
    func login(phone: String, password: String) async throws {
        let loginRequest = LoginRequest(phone: phone, password: password)
        let response: LoginResponse = try await apiClient.post(endpoint: "/auth/login", body: loginRequest)
        
        try tokenManager.saveAccessToken(response.token)
        try tokenManager.saveRefreshToken(response.refresh_token)
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
