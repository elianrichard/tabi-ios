//
//  EventService.swift
//  Tabi Split
//
//  Created by Elian Richard on 20/11/24.
//

final class EventService {
    static let shared = EventService()
    private let apiClient: APIClient = APIService.shared
    
    func createEvent(name: String, image: String) async throws -> CreateEventResponse {
        let request: CreateEventRequest = CreateEventRequest(name: name, event_image: image)
        let response : CreateEventResponse = try await apiClient.post(endpoint: "/event", body: request)
        
        return response
    }
    
    func getAllEvents() async throws -> GetEventsResponse {
        let response: GetEventsResponse = try await apiClient.get(endpoint: "/event")
        
        return response
    }
    
    func updateEvent(event: EventData, dummyNames: [String] = []) async throws -> EditEventResponse {
        guard let eventId = event.eventId else { throw EventAPIError.eventIdNotFound }
        let request: EditEventRequest = EditEventRequest(name: event.eventName, participants: event.participants.compactMap{ $0.userId }, event_image: event.eventIcon, dummy_names: dummyNames)
        let response : EditEventResponse = try await apiClient.patch(endpoint: "/event/\(eventId)", body: request)
        return response
    }
    
    func completeEvent(event: EventData) async throws {
        guard let eventId = event.eventId else { throw EventAPIError.eventIdNotFound }
        let request = CompleteEventRequest(is_completed: true)
        let _ : CompleteEventResponse = try await apiClient.post(endpoint: "/event/complete/\(eventId)", body: request)
    }
    
    func incompleteEvent(event: EventData) async throws {
        guard let eventId = event.eventId else { throw EventAPIError.eventIdNotFound }
        let request = CompleteEventRequest(is_completed: false)
        let _ : CompleteEventResponse = try await apiClient.post(endpoint: "/event/complete/\(eventId)", body: request)
    }
    
    func deleteEvent(event: EventData) async throws {
        guard let eventId = event.eventId else { throw EventAPIError.eventIdNotFound }
        let _ : DeleteEventResponse = try await apiClient.delete(endpoint: "/event/\(eventId)")
    }
    
    func joinEvent(eventId: String) async throws {
        let _ : JoinEventResponse = try await apiClient.post(endpoint: "/event/join/\(eventId)", body: Empty())
    }
}
