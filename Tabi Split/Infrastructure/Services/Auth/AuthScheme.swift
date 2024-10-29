//
//  AuthScheme.swift
//  Tabi Split
//
//  Created by ahmad naufal alfakhar on 29/10/24.
//

import Foundation

struct TokenPair: Codable {
    let accessToken: String
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "token"
        case refreshToken = "refresh_token"
    }
}

struct LoginRequest: Codable {
    let phone: String
    let password: String
}

struct LoginResponse: Codable {
    let token: String
    let refresh_token: String
    let message: String
}

struct RefreshRequest: Codable {
    let refresh_token: String
}

struct RefreshResponse: Codable {
    let token: String
    let message: String
}
