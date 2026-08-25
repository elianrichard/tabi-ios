//
//  MigrateSchema.swift
//  Tabi Split
//

import Foundation

enum MigrateAPIError: LocalizedError {
    case ownerEmailMissing
    case noLocalEvents
    case participantEmailMissing(eventName: String)
    case covererEmailMissing(expenseName: String)
    case assigneeEmailMissing(itemName: String)
    case conflict
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .ownerEmailMissing:
            return "Cannot migrate: missing your email"
        case .noLocalEvents:
            return "No local events to migrate"
        case .participantEmailMissing(let n):
            return "Event \"\(n)\" has a participant without an email"
        case .covererEmailMissing(let n):
            return "Expense \"\(n)\" coverer has no email"
        case .assigneeEmailMissing(let n):
            return "Item \"\(n)\" has an assignee without an email"
        case .conflict:
            return "Some events were already migrated"
        case .unknown(let s):
            return s
        }
    }
}

struct MigrateRequest: Codable {
    let owner_email: String
    let owner_name: String
    let events: [MigrateEvent]
}

struct MigrateEvent: Codable {
    let local_id: String
    let name: String
    let avatar_url: String
    let date_completed: String?
    let participants: [MigrateParticipant]
    let expenses: [MigrateExpense]
    let payments: [MigratePayment]
}

struct MigrateParticipant: Codable {
    let email: String
    let name: String?
}

struct MigrateExpense: Codable {
    let local_id: String
    let name: String
    let split_method: String
    let coverer_email: String
    let receipt_url: String?
    let date: String?
    let items: [MigrateItem]
    let additional_charges: [MigrateAdditionalCharge]
}

struct MigrateItem: Codable {
    let local_id: String
    let name: String
    let price: Float
    let quantity: Float
    let assignees: [MigrateAssignee]
}

struct MigrateAssignee: Codable {
    let email: String
    let share: Float
}

struct MigrateAdditionalCharge: Codable {
    let name: String
    let amount: Float
}

struct MigratePayment: Codable {
    let payer_email: String
    let receiver_email: String
    let amount: Float
    let status: String?
    let date_created: String?
    let receipt_url: String?
}

struct MigrateResponse: Codable {
    let message: String
    let owner_user_id: String?
    let events: [MigrateEventResult]
}

struct MigrateEventResult: Codable {
    let local_id: String
    let event_id: String
}
