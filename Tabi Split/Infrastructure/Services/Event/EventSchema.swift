//
//  EventSchema.swift
//  Tabi Split
//
//  Created by Elian Richard on 20/11/24.
//

import Foundation

enum EventAPIError: LocalizedError {
    case eventIdNotFound
    
    var errorDescription: String? {
        switch self {
        case .eventIdNotFound:
            return "Event ID not found"
        }
    }
}

struct CreateEventRequest: Codable {
    let name: String
    let event_image: String
}

struct CreateEventResponse: Codable {
    let message: String
    let event_id: String
}

struct EventBase: Codable {
    let id: String
    let completion_date: String?
    let name: String
    let avatar_url: String
    let creator_id: String
    let created_at: String
    let participants: [UserBase]
    let expenses: [ExpenseEventBase]
}

struct GetEventsResponse: Codable {
    let message: String
    let events: [EventBase]
}

struct EditEventRequest: Codable {
    let name: String
    let participants: [String]
    let event_image: String
    let dummy_users: [DummyUserInput]
}

// A new (unregistered) participant being invited by name, with the avatar the
// client chose for them so the backend stores that image instead of a random one.
struct DummyUserInput: Codable {
    let name: String
    let avatar: String
}

struct EditEventResponse: Codable {
    let message: String
    let dummy_user_info: [DummyInfoBase]
}

struct DummyInfoBase: Codable {
    let dummy_user_id: String
    let dummy_name: String
    // Built-in avatar identifier assigned by the backend at first invite, so the
    // client anchors a stable image instead of re-randomizing it on every edit.
    // Optional to stay decodable against older backends that omit it.
    let avatar_url: String?
}

// Edits one participant: name + avatar, and optionally an email to link the
// participant to an existing registered account.
struct EditParticipantRequest: Codable {
    let name: String
    let avatar: String
    let email: String?
}

struct EditParticipantResponse: Codable {
    let message: String
    let participant: UserBase
}

struct RemoveParticipantResponse: Codable {
    let message: String
}

struct CompleteEventRequest: Codable {
    let is_completed: Bool
}

struct CompleteEventResponse: Codable {
    let message: String
    let completion_date: String?
}

struct DeleteEventResponse: Codable {
    let message: String
}

struct JoinEventResponse: Codable {
    let message: String
}

struct JoinEventByTokenResponse: Codable {
    let message: String
    let event_id: String
}

struct InviteTokenResponse: Codable {
    let token: String
    let expires_at: Int
}
