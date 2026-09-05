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
    /// When signing in from a guest session, the guest's access token. The backend
    /// merges the guest's owned data into the resolved provider account and retires
    /// the guest. Nil for a normal sign-in.
    let merge_from_guest_token: String?
}

/// Body for POST /auth/guest. Both optional: when omitted the backend generates
/// an "Adjective Animal" name and a random avatar.
struct GuestRequest: Codable {
    let name: String?
    let profile_image: String?
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
