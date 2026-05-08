//
//  MigrateService.swift
//  Tabi Split
//

import Foundation

final class MigrateService {
    static let shared = MigrateService()
    private let apiClient: APIClient = APIService.shared

    func migrate(_ request: MigrateRequest) async throws -> MigrateResponse {
        let response: MigrateResponse = try await apiClient.post(endpoint: "/migrate", body: request)
        return response
    }
}
