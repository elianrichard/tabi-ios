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
    case tokenMissing
    
    var errorDescription: String? {
        switch self {
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
        }
    }
}
