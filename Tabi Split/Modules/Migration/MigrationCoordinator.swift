//
//  MigrationCoordinator.swift
//  Tabi Split
//
//  Orchestrates one-shot bulk upload of local SwiftData events to /migrate.
//

import Foundation
import SwiftData

@Observable
@MainActor
final class MigrationCoordinator {
    static let shared = MigrationCoordinator()

    static let batchSize = 20

    var isRunning: Bool = false
    var lastError: Error?
    var lastSyncedAt: Date?

    private init() {}

    var hasUnsynced: Bool {
        guard let events = SwiftDataService.shared.fetchAllEvents() else { return false }
        return events.contains(where: { !$0.isSynced })
    }

    @discardableResult
    func runIfNeeded(ownerPhone: String, ownerName: String) async -> Bool {
        guard !isRunning else { return false }
        guard !ownerPhone.isEmpty, ownerPhone != "Guest" else {
            lastError = MigrateAPIError.ownerPhoneMissing
            return false
        }

        let allEvents = SwiftDataService.shared.fetchAllEvents() ?? []
        let pending = allEvents.filter { !$0.isSynced }
        guard !pending.isEmpty else { return true }

        isRunning = true
        defer { isRunning = false }

        rewriteGuestPhones(events: pending, ownerPhone: ownerPhone)
        SwiftDataService.shared.saveModelContext()

        let batches = stride(from: 0, to: pending.count, by: Self.batchSize).map {
            Array(pending[$0..<min($0 + Self.batchSize, pending.count)])
        }

        for batch in batches {
            do {
                try await migrateBatch(batch, ownerPhone: ownerPhone, ownerName: ownerName)
            } catch {
                lastError = error
                print("Migration batch failed: \(error)")
                return false
            }
        }

        lastSyncedAt = Date()
        lastError = nil
        return true
    }

    private func migrateBatch(_ events: [EventData], ownerPhone: String, ownerName: String) async throws {
        var migrateEvents: [MigrateEvent] = []
        for event in events {
            try migrateEvents.append(buildMigrateEvent(from: event))
        }

        let request = MigrateRequest(
            owner_phone: ownerPhone,
            owner_name: ownerName,
            events: migrateEvents
        )

        let response: MigrateResponse
        do {
            response = try await MigrateService.shared.migrate(request)
        } catch APIError.requestFailed(let message) where message.lowercased().contains("conflict") || message.contains("409") {
            // BE returns 409 when these events were already migrated; mark synced so we never retry.
            for event in events { event.isSynced = true }
            SwiftDataService.shared.saveModelContext()
            return
        }

        let resultByLocalId = Dictionary(uniqueKeysWithValues: response.events.map { ($0.local_id, $0.event_id) })
        for event in events {
            if let serverId = resultByLocalId[event.localId] {
                event.eventId = serverId
            }
            // BE response only maps event-level IDs; expense IDs get filled on the next /event GET.
            event.isSynced = true
            for expense in event.expenses {
                expense.isSynced = true
            }
        }
        SwiftDataService.shared.saveModelContext()
    }

    private func buildMigrateEvent(from event: EventData) throws -> MigrateEvent {
        var seenPhones: Set<String> = []
        var migrateParticipants: [MigrateParticipant] = []
        for user in event.participants {
            let phone = user.phone
            guard !phone.isEmpty, phone != "Guest" else {
                throw MigrateAPIError.participantPhoneMissing(eventName: event.eventName)
            }
            if !seenPhones.contains(phone) {
                seenPhones.insert(phone)
                migrateParticipants.append(MigrateParticipant(phone: phone, name: user.name))
            }
        }

        let migrateExpenses = try event.expenses.map { try buildMigrateExpense(from: $0) }

        return MigrateEvent(
            local_id: event.localId,
            name: event.eventName,
            avatar_url: event.eventIcon,
            date_completed: event.completionDate?.iso8601String,
            participants: migrateParticipants,
            expenses: migrateExpenses,
            payments: []
        )
    }

    private func buildMigrateExpense(from expense: Expense) throws -> MigrateExpense {
        let covererPhone = expense.coverer.phone
        guard !covererPhone.isEmpty, covererPhone != "Guest" else {
            throw MigrateAPIError.covererPhoneMissing(expenseName: expense.name)
        }

        let items = try expense.items.map { item -> MigrateItem in
            let assignees = try item.assignees.map { person -> MigrateAssignee in
                let phone = person.user.phone
                guard !phone.isEmpty, phone != "Guest" else {
                    throw MigrateAPIError.assigneePhoneMissing(itemName: item.itemName)
                }
                return MigrateAssignee(phone: phone, share: person.share)
            }
            return MigrateItem(
                local_id: item.localId,
                name: item.itemName,
                price: item.itemPrice,
                quantity: item.itemQuantity,
                assignees: assignees
            )
        }

        let charges = expense.additionalCharges.map {
            MigrateAdditionalCharge(name: $0.additionalChargeType, amount: $0.amount)
        }

        return MigrateExpense(
            local_id: expense.localId,
            name: expense.name,
            split_method: expense.splitMethod,
            coverer_phone: covererPhone,
            receipt_url: nil,
            date: expense.dateOfCreation.iso8601String,
            items: items,
            additional_charges: charges
        )
    }

    private func rewriteGuestPhones(events: [EventData], ownerPhone: String) {
        for event in events {
            for user in event.participants where user.phone == "Guest" || user.phone.isEmpty {
                user.phone = ownerPhone
            }
            for expense in event.expenses {
                if expense.coverer.phone == "Guest" || expense.coverer.phone.isEmpty {
                    expense.coverer.phone = ownerPhone
                }
                for item in expense.items {
                    for assignee in item.assignees where assignee.user.phone == "Guest" || assignee.user.phone.isEmpty {
                        assignee.user.phone = ownerPhone
                    }
                }
            }
        }
    }
}

private extension Date {
    var iso8601String: String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f.string(from: self)
    }
}
