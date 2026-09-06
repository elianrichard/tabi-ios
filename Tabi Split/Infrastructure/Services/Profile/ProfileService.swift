//
//  ProfileService.swift
//  Tabi Split
//
//  Created by Elian Richard on 17/11/24.
//

import Foundation

final class ProfileService {
    static let shared = ProfileService()
    private let apiClient: APIClient = APIService.shared
    
    func editProfile(user: CurrentUserDefaults) async throws -> EditProfileResponse {
        let request = EditProfileRequest(name: user.userName, avatar_url: user.userImage)
        let response: EditProfileResponse = try await apiClient.patch(endpoint: "/user", body: request)

        return response
    }

    func getCurrentProfile () async throws -> UserBase {
        // Resolve the current user from the session (GET /user), not by email.
        // A guest account has no email, so the old email-lookup via /user/check
        // returned no rows and failed for guests.
        let response: UserGetResponse = try await apiClient.get(endpoint: "/user")
        guard let userId = response.user_id, let name = response.name else {
            throw ProfileAPIError.userNotFoundInResponse
        }
        return UserBase(
            user_id: userId,
            email: response.email,
            name: name,
            avatar_url: response.profile_image ?? "",
            kind: response.kind
        )
    }

    func deleteUser() async throws {
        let _: DeleteResponse = try await apiClient.delete(endpoint: "/user")
    }

    func probeSession() async throws -> UserGetResponse {
        let response: UserGetResponse = try await apiClient.get(endpoint: "/user")
        return response
    }

    func checkUsers(emails: [String]) async throws -> CheckUsersResponse {
        let request: CheckUsersRequest = CheckUsersRequest(emails: emails)
        let response: CheckUsersResponse = try await apiClient.post(endpoint: "/user/check", body: request)

        return response
    }
}
