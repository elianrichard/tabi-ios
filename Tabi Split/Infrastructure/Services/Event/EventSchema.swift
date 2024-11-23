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
}

struct EventBase: Codable {
    let id: String
    let date: String?
    let name: String
    let avatar_url: String
    let creator_id: String
//    TODO: Created At Response for Event
//    let created_at: String
    let participants: [UserBase]
}

struct GetEventsResponse: Codable {
    let message: String
    let events: [EventBase]
}

struct EditEventRequest: Codable {
    let name: String
    let participants: [String]
    let event_image: String
}

struct EditEventResponse: Codable {
    let message: String
}

struct CompleteEventResponse: Codable {
    let message: String
    let completed_at: String
}

struct DeleteEventResponse: Codable {
    let message: String
}
