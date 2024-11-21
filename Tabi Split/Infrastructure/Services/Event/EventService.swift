//
//  EventService.swift
//  Tabi Split
//
//  Created by Elian Richard on 20/11/24.
//

final class EventService {
    static let shared = EventService()
    private let apiClient: APIClient = APIService.shared
    
    func createEvent(name: String) async throws {
        let request: CreateEventRequest = CreateEventRequest(name: name)
        let _ : CreateEventResponse = try await apiClient.post(endpoint: "/event", body: request)
    }
    
    func getAllEvents() async throws -> GetEventsResponse {
        let response: GetEventsResponse = try await apiClient.get(endpoint: "/event")
        
        return response
    }
    
    func updateEvent(event: EventData) async throws {
        guard let eventId = event.eventId else { throw EventAPIError.eventIdNotFound }
        let request: EditEventRequest = EditEventRequest(name: event.eventName, participants: event.participants.compactMap{ $0.userId })
        let _ : EditEventResponse = try await apiClient.patch(endpoint: "/event/\(eventId)", body: request)
    }
}
