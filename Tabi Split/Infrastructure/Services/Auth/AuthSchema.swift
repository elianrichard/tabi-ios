//
//  AuthScheme.swift
//  Tabi Split
//
//  Created by ahmad naufal alfakhar on 29/10/24.
//

import Foundation

struct RegisterRequest: Codable {
    let name: String
    let phone: String
    let password: String
}

struct RegisterResponse: Codable {
    let message: String
}

struct LoginRequest: Codable {
    let phone: String
    let password: String
}

struct LoginResponse: Codable {
    let token: String
    let refresh_token: String
    let message: String
    let full_name: String
    let profile_image: String
}

struct RefreshRequest: Codable {
    let refresh_token: String
}

struct RefreshResponse: Codable {
    let token: String
    let message: String
}
