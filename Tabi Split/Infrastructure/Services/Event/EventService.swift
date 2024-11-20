//
//  EventService.swift
//  Tabi Split
//
//  Created by Elian Richard on 20/11/24.
//

final class EventService {
    static let shared = EventService()
    
    private let apiClient: APIClient = APIService.shared
    private let tokenManager: TokenManaging = KeychainService.shared
    
    func createEvent(name: String) async throws {
        let request: CreateEventRequest = CreateEventRequest(name: name)
        let _ : CreateEventResponse = try await apiClient.post(endpoint: "/event", body: request)
    }
}
