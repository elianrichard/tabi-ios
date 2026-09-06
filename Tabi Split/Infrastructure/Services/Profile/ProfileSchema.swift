//
//  ProfileSchema.swift
//  Tabi Split
//
//  Created by Elian Richard on 17/11/24.
//

import Foundation

enum ProfileAPIError: LocalizedError {
    case userNotFound
    case userNotFoundInResponse
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .userNotFoundInResponse:
            return "User not found in response"
        }
    }
}

struct EditProfileRequest: Codable {
    let name: String
    let avatar_url: String
}

struct EditProfileResponse: Codable {
    let message: String
}

struct GetProfileRequest: Codable {
    let emails: [String]
}

struct GetProfileResponse: Codable {
    let message: String
    let users: [UserBase]
}

struct CheckUsersRequest: Codable {
    let emails: [String]
}

struct CheckUsersResponse: Codable {
    let message: String
    let users: [UserBase]
}

struct UserBase: Codable {
    let user_id: String
    let email: String?
    let name: String
    let avatar_url: String
    // Account type: "real", "dummy", or "guest". Optional so payloads that omit
    // it still decode; a nil/absent kind is treated as an unlinked dummy.
    let kind: String?
}

struct UserGetResponse: Codable {
    let message: String?
    let user_id: String?
    let name: String?
    let email: String?
    let profile_image: String?
    // Account type: "real", "dummy", or "guest".
    let kind: String?
}
