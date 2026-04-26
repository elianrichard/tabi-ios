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
        let request = EditProfileRequest(name: user.userName, phone: user.userPhone, avatar_url: user.userImage)
        let response: EditProfileResponse = try await apiClient.patch(endpoint: "/user/edit", body: request)
        
        return response
    }
    
    func getCurrentProfile () async throws -> UserBase {
        guard let user = UserDefaultsService.shared.getCurrentUser() else { throw ProfileAPIError.userNotFound }
        let request: GetProfileRequest = GetProfileRequest(phones: [user.userPhone])
        let response: GetProfileResponse = try await apiClient.post(endpoint: "/user/check", body: request)
        
        guard let apiUser = response.users.first else {
            throw ProfileAPIError.userNotFoundInResponse
        }
        
        return apiUser
    }
    
    func deleteUser() async throws {
        let _: DeleteResponse = try await apiClient.delete(endpoint: "/user/delete")
    }
    
    func checkUsers(phoneNumbers: [String]) async throws -> CheckUsersResponse {
        let request: CheckUsersRequest = CheckUsersRequest(phones: phoneNumbers)
        let response: CheckUsersResponse = try await apiClient.post(endpoint: "/user/check", body: request)
        
        return response
    }
}
