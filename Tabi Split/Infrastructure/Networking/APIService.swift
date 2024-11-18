//
//  APIService.swift
//  Tabi Split
//
//  Created by ahmad naufal alfakhar on 29/10/24.
//

import Foundation

protocol APIClient {
    func request<Response: Codable>(
        endpoint: String,
        method: String,
        body: Encodable?
    ) async throws -> Response
    
    func get<Response: Codable>(endpoint: String) async throws -> Response
    func post<Request: Encodable, Response: Codable>(endpoint: String, body: Request) async throws -> Response
    func put<Request: Encodable, Response: Codable>(endpoint: String, body: Request) async throws -> Response
    func patch<Request: Encodable, Response: Codable>(endpoint: String, body: Request) async throws -> Response
    func delete<Response: Codable>(endpoint: String) async throws -> Response
}

final class APIService: APIClient {
    static let shared = APIService()
    
    private let config: APIConfig
    private let tokenManager: TokenManaging = KeychainService.shared
    private var isRefreshing = false
    private var refreshQueue: [(String) -> Void] = []
    
    init(config: APIConfig = .default) {
        self.config = config
    }
    
    func request<Response: Codable>(
        endpoint: String,
        method: String,
        body: Encodable?
    ) async throws -> Response {
        var request = URLRequest(url: URL(string: config.baseURL + endpoint)!)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(body)
        }
        
        return try await requestWithRetry(endpoint: endpoint, request: request)
    }
    
    func get<Response: Codable>(endpoint: String) async throws -> Response {
        return try await request(endpoint: endpoint, method: "GET", body: nil as Empty?)
    }
    
    func post<Request: Encodable, Response: Codable>(
        endpoint: String,
        body: Request
    ) async throws -> Response {
        return try await request(endpoint: endpoint, method: "POST", body: body)
    }
    
    func put<Request: Encodable, Response: Codable>(
        endpoint: String,
        body: Request
    ) async throws -> Response {
        return try await request(endpoint: endpoint, method: "PUT", body: body)
    }
    
    func patch<Request: Encodable, Response: Codable>(
        endpoint: String,
        body: Request
    ) async throws -> Response {
        return try await request(endpoint: endpoint, method: "PATCH", body: body)
    }
    
    func delete<Response: Codable>(endpoint: String) async throws -> Response {
        return try await request(endpoint: endpoint, method: "DELETE", body: nil as Empty?)
    }
    
    private func requestWithRetry<Response: Codable>(
        endpoint: String,
        request: URLRequest
    ) async throws -> Response {
        do {
            let authService = AuthenticationService()
            var modifiedRequest = request
            let url = URL(string: config.baseURL + endpoint)!
            modifiedRequest.url = url
            
            if let accessToken = try? tokenManager.getAccessToken() {
                modifiedRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            }
            
            let (data, response) = try await URLSession.shared.data(for: modifiedRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            if httpResponse.statusCode == 401 {
                try await authService.refresh()
                
                if let newAccessToken = try? tokenManager.getAccessToken() {
                    modifiedRequest.setValue("Bearer \(newAccessToken)", forHTTPHeaderField: "Authorization")
                    let (newData, _) = try await URLSession.shared.data(for: modifiedRequest)
                    return try JSONDecoder().decode(Response.self, from: newData)
                } else {
                    throw APIError.unauthorized
                }
            }
            
            if httpResponse.statusCode == 500 {
                let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                throw APIError.internalServerError(message: errorResponse?.errors ?? "Unknown server error")
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    if config.unauthorizedMessages.contains(errorResponse.errors) {
                        try? tokenManager.clearTokens()
                        throw APIError.unauthorized
                    }
                    throw APIError.requestFailed(message: errorResponse.errors)
                }
                
                let errorMessage = try? JSONDecoder().decode(String.self, from: data)
                if let message = errorMessage,
                   config.unauthorizedMessages.contains(message) {
                    try? tokenManager.clearTokens()
                    throw APIError.unauthorized
                }
                throw APIError.requestFailed(message: errorMessage ?? "Unknown error")
            }
            
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw (error as? APIError) ?? .requestFailed(message: error.localizedDescription)
        }
    }
}

struct Empty: Codable {}

struct ErrorResponse: Codable {
    let errors: String
}
