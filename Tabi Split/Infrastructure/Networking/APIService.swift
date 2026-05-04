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

// Serialises concurrent 401 token refreshes so only one network call is made.
private actor TokenRefreshCoordinator {
    private var refreshTask: Task<Void, Error>?

    func refresh(using authService: AuthenticationService) async throws {
        if let existing = refreshTask {
            try await existing.value
            return
        }
        let task = Task<Void, Error> { try await authService.refresh() }
        refreshTask = task
        defer { refreshTask = nil }
        try await task.value
    }
}

final class APIService: APIClient {
    static let shared = APIService()

    private let config: APIConfig
    private let tokenManager: TokenManaging = KeychainService.shared
    private let refreshCoordinator = TokenRefreshCoordinator()

    init(config: APIConfig = .default) {
        self.config = config
    }

    func request<Response: Codable>(
        endpoint: String,
        method: String,
        body: Encodable?
    ) async throws -> Response {
        guard let url = URL(string: config.baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(ENV.API_SECRET_KEY, forHTTPHeaderField: "X-Api-Secret")

        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        return try await requestWithRetry(request: request)
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

    private func requestWithRetry<Response: Codable>(request: URLRequest) async throws -> Response {
        var modifiedRequest = request
        if let accessToken = try? tokenManager.getAccessToken() {
            modifiedRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: modifiedRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            try await refreshCoordinator.refresh(using: AuthenticationService.shared)
            if let newToken = try? tokenManager.getAccessToken() {
                modifiedRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
            }
            let (newData, _) = try await URLSession.shared.data(for: modifiedRequest)
            return try JSONDecoder().decode(Response.self, from: newData)
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
            if let message = errorMessage, config.unauthorizedMessages.contains(message) {
                try? tokenManager.clearTokens()
                throw APIError.unauthorized
            }
            throw APIError.requestFailed(message: errorMessage ?? "Unknown error")
        }

        return try JSONDecoder().decode(Response.self, from: data)
    }
}

struct Empty: Codable {}

struct ErrorResponse: Codable {
    let errors: String
}
