//
//  ProfileSchema.swift
//  Tabi Split
//
//  Created by Elian Richard on 17/11/24.
//

import Foundation

enum ProfileAPIError: LocalizedError {
    case userNotFound
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        }
    }
}

struct EditProfileRequest: Codable {
    let name: String
    let phone: String
    let avatar_url: String
}

struct EditProfileResponse: Codable {
    let message: String
}

struct BaseProfile: Codable {
    let user_id: String
    let phone: String
    let name: String
    let avatar_url: String
}

struct GetProfileRequest: Codable {
    let phones: [String]
}

struct GetProfileResponse: Codable {
    let message: String
    let users: [BaseProfile]
}
