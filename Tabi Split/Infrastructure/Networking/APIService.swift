//
//  APIService.swift
//  Tabi Split
//
//  Created by ahmad naufal alfakhar on 29/10/24.
//

import Foundation
import os.log

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
        request.setValue(ENV.API_SECRET_KEY, forHTTPHeaderField: ENV.API_SECRET_HEADER)

        if let body = body {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(body)
        }

        os_log(.debug, log: .api, "API Request %{public}@ %{public}@ body: %{public}@", method, endpoint, String(describing: body))
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
        await MainActor.run { LoadingViewModel.shared.beginRequest() }
        defer { Task { @MainActor in LoadingViewModel.shared.endRequest() } }
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
                // A 401 on the refresh endpoint itself means the refresh token is
                // dead ("Invalid refresh token"). Do NOT recurse into refresh() —
                // that spins forever and hangs the loading screen. End the session.
                if endpoint == "/auth/refresh" {
                    try? tokenManager.clearTokens()
                    NotificationCenter.default.post(name: .sessionExpired, object: nil)
                    throw APIError.unauthorized
                }

                do {
                    try await authService.refresh()
                } catch {
                    try? tokenManager.clearTokens()
                    NotificationCenter.default.post(name: .sessionExpired, object: nil)
                    throw APIError.unauthorized
                }

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
            let result = try JSONDecoder().decode(Response.self, from: data)
//            print("\(result)")
            
            return result
        } catch {
            // A cancelled request is not a user-facing failure: it happens when the
            // Task is torn down (e.g. navigating away mid-refresh) or superseded.
            // Rethrow it as-is without the blocking error dialog.
            if error.isCancellation {
                throw error
            }
            os_log(.error, log: .api, "API Error: %{public}@", String(describing: error))
            let apiError = (error as? APIError) ?? .requestFailed(message: error.localizedDescription)
            notifyError(apiError)
            throw apiError
        }
    }

    private func notifyError(_ error: APIError) {
        // .unauthorized is handled by the session-expired flow (banner + logout);
        // surfacing it here would be redundant/noisy.
        if case .unauthorized = error { return }
        let message = error.errorDescription ?? "Something went wrong. Please try again."
        // Errors are shown in a blocking dialog (demands acknowledgment); the toast
        // is reserved for success/info messages.
        Task { @MainActor in ErrorDialogViewModel.shared.show(message) }
    }
}

struct Empty: Codable {}

private extension Error {
    /// True when this error is a task/URL cancellation, in any of its forms:
    /// Swift's CancellationError, or URLError/NSURLError with the cancelled code.
    var isCancellation: Bool {
        if self is CancellationError { return true }
        if let urlError = self as? URLError { return urlError.code == .cancelled }
        let nsError = self as NSError
        return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled
    }
}

struct ErrorResponse: Codable {
    let errors: String
}

extension Notification.Name {
    static let sessionExpired = Notification.Name("TabiSessionExpired")
}


private extension OSLog {
    static let api = OSLog(subsystem: ENV.APP_BUNDLE_ID, category: "API")
}
