//
//  AppError.swift
//  Tabi Split
//

import Foundation

enum AppError: LocalizedError, Equatable {
    case network(String)
    case storage(String)
    case validation(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .network(let msg):    return msg
        case .storage(let msg):    return msg
        case .validation(let msg): return msg
        case .unknown(let msg):    return msg
        }
    }

    static func from(_ error: Error) -> AppError {
        if let apiError = error as? APIError {
            return .network(apiError.localizedDescription)
        }
        return .unknown(error.localizedDescription)
    }
}
