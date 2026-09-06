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
    
    func updateEvent(event: EventData, newDummyUsers: [UserData] = []) async throws -> EditEventResponse {
        guard let eventId = event.eventId else { throw EventAPIError.eventIdNotFound }
        // Only participants with a real userId (registered users and already-anchored
        // dummies) go in `participants`; un-anchored dummies have an empty userId and
        // are sent by name+avatar via `dummy_users`. Filtering empties also keeps the
        // backend's uuid validation from rejecting the request.
        let dummyInputs = newDummyUsers.map { DummyUserInput(name: $0.name, avatar: $0.image) }
        let request: EditEventRequest = EditEventRequest(name: event.eventName, participants: event.participants.compactMap{ $0.userId.isEmpty ? nil : $0.userId }, event_image: event.eventIcon, dummy_users: dummyInputs)
        let response : EditEventResponse = try await apiClient.patch(endpoint: "/event/\(eventId)", body: request)
        return response
    }
    
    func editParticipant(eventId: String, participantId: String, name: String, avatar: String, email: String?) async throws -> EditParticipantResponse {
        let request = EditParticipantRequest(name: name, avatar: avatar, email: email)
        let response: EditParticipantResponse = try await apiClient.patch(endpoint: "/event/\(eventId)/participant/\(participantId)", body: request)
        return response
    }

    func removeParticipant(eventId: String, participantId: String) async throws -> RemoveParticipantResponse {
        let response: RemoveParticipantResponse = try await apiClient.delete(endpoint: "/event/\(eventId)/participant/\(participantId)")
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

    // Non-creator leaves the event; the caller is replaced by a placeholder dummy
    // carrying their name, keeping their expense history intact.
    @discardableResult
    func leaveEvent(eventId: String) async throws -> LeaveEventResponse {
        let response: LeaveEventResponse = try await apiClient.post(endpoint: "/event/leave/\(eventId)", body: Empty())
        return response
    }

    @discardableResult
    func joinEventByToken(token: String) async throws -> String {
        let response: JoinEventByTokenResponse = try await apiClient.post(endpoint: "/event/join-by-token/\(token)", body: Empty())
        return response.event_id
    }

    func createInviteToken(eventId: String) async throws -> InviteTokenResponse {
        let response: InviteTokenResponse = try await apiClient.post(endpoint: "/event/\(eventId)/invite-token", body: Empty())
        return response
    }

    // Single-use token that links the joining user to a specific email-less dummy
    // participant (claim), rather than adding a brand-new event member.
    func createParticipantInviteToken(eventId: String, participantId: String) async throws -> InviteTokenResponse {
        let response: InviteTokenResponse = try await apiClient.post(endpoint: "/event/\(eventId)/participant/\(participantId)/invite-token", body: Empty())
        return response
    }

    // Polls whether an email-less dummy participant has been claimed via its
    // invite link; when claimed, the response carries the account that took over.
    func participantClaimStatus(eventId: String, participantId: String) async throws -> ParticipantClaimStatusResponse {
        let response: ParticipantClaimStatusResponse = try await apiClient.get(endpoint: "/event/\(eventId)/participant/\(participantId)/status")
        return response
    }
}
