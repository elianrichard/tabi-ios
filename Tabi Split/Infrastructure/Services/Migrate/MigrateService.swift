//
//  MigrateService.swift
//  Tabi Split
//

import Foundation

final class MigrateService {
    static let shared = MigrateService()
    private let apiClient: APIClient = APIService.shared

    func migrate(_ request: MigrateRequest) async throws -> MigrateResponse {
        let sentLocalIds = request.events.map { $0.local_id }
        print("Migrate REQ event count=\(request.events.count) localIds=\(sentLocalIds)")

        let response: MigrateResponse = try await apiClient.post(endpoint: "/migrate", body: request)

        let returnedLocalIds = response.events.map { $0.local_id }
        let returnedEventIds = response.events.map { $0.event_id }
        print("Migrate RES event count=\(response.events.count) localIds=\(returnedLocalIds) eventIds=\(returnedEventIds) message=\(response.message)")

        let dupLocalIds = Dictionary(grouping: returnedLocalIds, by: { $0 }).filter { $1.count > 1 }.keys
        if !dupLocalIds.isEmpty {
            print("Migrate RES WARNING: duplicate local_id keys returned: \(Array(dupLocalIds))")
        }
        let unsent = Set(returnedLocalIds).subtracting(sentLocalIds)
        if !unsent.isEmpty {
            print("Migrate RES WARNING: response contains local_ids that were NOT in the request: \(unsent)")
        }
        let unmapped = Set(sentLocalIds).subtracting(returnedLocalIds)
        if !unmapped.isEmpty {
            print("Migrate RES WARNING: request local_ids missing from response: \(unmapped)")
        }

        return response
    }
}
