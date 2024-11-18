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
    
    func register(name: String, phone: String, password: String) async throws -> RegisterResponse {
        let registerRequest = RegisterRequest(name: name, phone: phone, password: password)
        let response: RegisterResponse = try await apiClient.post(endpoint: "/auth/register", body: registerRequest)
        
        return response
    }
    
    func login(phone: String, password: String) async throws -> LoginResponse {
        let loginRequest = LoginRequest(phone: phone, password: password)
        let response: LoginResponse = try await apiClient.post(endpoint: "/auth/login", body: loginRequest)
        
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
