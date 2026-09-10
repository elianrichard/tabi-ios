//
//  APIError.swift
//  Tabi Split
//
//  Created by ahmad naufal alfakhar on 29/10/24.
//

import Foundation

enum APIError: LocalizedError {
    case invalidResponse
    case refreshFailed
    case unauthorized
    case requestFailed(message: String)
    /// 404 — the resource is gone (e.g. an event deleted by its creator).
    case notFound(message: String)
    /// 403 — the caller may no longer access the resource (e.g. removed from an event).
    case forbidden(message: String)
    case tokenMissing
    case internalServerError(message: String)
    
    var errorDescription: String? {
        switch self {
        case .notFound(let message), .forbidden(let message):
            return message
        case .invalidResponse:
            return "Invalid response from server"
        case .refreshFailed:
            return "Failed to refresh authentication token"
        case .unauthorized:
            return "Unauthorized access"
        case .requestFailed(let message):
            return message
        case .tokenMissing:
            return "Authentication token not found"
        case .internalServerError(let message):
            return "Internal Server Error: \(message)"
        }
    }
}
