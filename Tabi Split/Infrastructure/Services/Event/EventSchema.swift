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
    let expenses: [ExpenseEventBase]?
}

struct GetEventsResponse: Codable {
    let message: String
    let events: [EventBase]
}

struct EditEventRequest: Codable {
    let name: String
    let participants: [String]
    let event_image: String
    let dummy_names: [String]
}

struct EditEventResponse: Codable {
    let message: String
    let dummy_user_info: [DummyInfoBase]
}

struct DummyInfoBase: Codable {
    let dummy_user_id: String
    let dummy_name: String
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
