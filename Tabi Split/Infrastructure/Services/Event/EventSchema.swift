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
//    TODO: Set image for event
//    let image: String
}

struct CreateEventResponse: Codable {
    let message: String
//    TODO: Get EventID
//    let eventId: String
}

struct EventBase: Codable {
    let id: String
    let date: String?
    let name: String
    let avatar_url: String
    let creator_id: String
    let participants: [UserBase]
}

struct GetEventsResponse: Codable {
    let message: String
    let events: [EventBase]
}

struct EditEventRequest: Codable {
    let name: String
    let participants: [String]
}

struct EditEventResponse: Codable {
    let message: String
}
