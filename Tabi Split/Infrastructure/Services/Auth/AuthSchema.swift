//
//  AuthScheme.swift
//  Tabi Split
//
//  Created by ahmad naufal alfakhar on 29/10/24.
//

import Foundation

/// Body for POST /auth/google and /auth/apple. The client runs the native
/// provider sign-in, then sends the resulting id_token here. `name`/`email` are
/// optional hints used only when the backend creates a brand-new account (Apple
/// returns them reliably only on the user's first authorization).
struct OAuthRequest: Codable {
    let id_token: String
    let name: String?
    let email: String?
}

struct LoginResponse: Codable {
    let token: String
    let refresh_token: String
    let message: String
    let full_name: String
    let email: String?
    let profile_image: String
}

struct RefreshRequest: Codable {
    let refresh_token: String
}

struct RefreshResponse: Codable {
    let token: String
    let message: String
}

struct DeleteResponse: Codable {
    let message: String
}
