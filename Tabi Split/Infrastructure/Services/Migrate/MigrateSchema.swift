//
//  MigrateSchema.swift
//  Tabi Split
//

import Foundation

enum MigrateAPIError: LocalizedError {
    case ownerPhoneMissing
    case noLocalEvents
    case participantPhoneMissing(eventName: String)
    case covererPhoneMissing(expenseName: String)
    case assigneePhoneMissing(itemName: String)
    case conflict
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .ownerPhoneMissing:
            return "Cannot migrate: missing your phone number"
        case .noLocalEvents:
            return "No local events to migrate"
        case .participantPhoneMissing(let n):
            return "Event \"\(n)\" has a participant without a phone number"
        case .covererPhoneMissing(let n):
            return "Expense \"\(n)\" coverer has no phone number"
        case .assigneePhoneMissing(let n):
            return "Item \"\(n)\" has an assignee without a phone number"
        case .conflict:
            return "Some events were already migrated"
        case .unknown(let s):
            return s
        }
    }
}

struct MigrateRequest: Codable {
    let owner_phone: String
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
    let phone: String
    let name: String?
}

struct MigrateExpense: Codable {
    let local_id: String
    let name: String
    let split_method: String
    let coverer_phone: String
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
    let phone: String
    let share: Float
}

struct MigrateAdditionalCharge: Codable {
    let name: String
    let amount: Float
}

struct MigratePayment: Codable {
    let payer_phone: String
    let receiver_phone: String
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
