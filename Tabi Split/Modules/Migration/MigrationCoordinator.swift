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
    func runIfNeeded(ownerEmail: String, ownerName: String) async -> Bool {
        guard !isRunning else { return false }
        guard !ownerEmail.isEmpty, ownerEmail != "Guest" else {
            lastError = MigrateAPIError.ownerEmailMissing
            return false
        }

        let allEvents = SwiftDataService.shared.fetchAllEvents() ?? []
        let pending = allEvents.filter { !$0.isSynced }
        guard !pending.isEmpty else { return true }

        isRunning = true
        defer { isRunning = false }

        rewriteGuestEmails(events: pending, ownerEmail: ownerEmail)
        SwiftDataService.shared.saveModelContext()

        let batches = stride(from: 0, to: pending.count, by: Self.batchSize).map {
            Array(pending[$0..<min($0 + Self.batchSize, pending.count)])
        }

        for batch in batches {
            do {
                try await migrateBatch(batch, ownerEmail: ownerEmail, ownerName: ownerName)
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

    private func migrateBatch(_ events: [EventData], ownerEmail: String, ownerName: String) async throws {
        // Dedupe by localId in case SwiftData has phantom duplicates.
        var seenLocalIds: Set<String> = []
        let uniqueEvents = events.filter { seenLocalIds.insert($0.localId).inserted }
        if uniqueEvents.count != events.count {
            print("Migration: dropped \(events.count - uniqueEvents.count) duplicate localId rows")
        }

        var migrateEvents: [MigrateEvent] = []
        for event in uniqueEvents {
            try migrateEvents.append(buildMigrateEvent(from: event))
        }

        let request = MigrateRequest(
            owner_email: ownerEmail,
            owner_name: ownerName,
            events: migrateEvents
        )

        let response: MigrateResponse
        do {
            response = try await MigrateService.shared.migrate(request)
        } catch APIError.requestFailed(let message) where message.lowercased().contains("conflict") || message.contains("409") {
            // BE returns 409 when these events were already migrated; mark synced so we never retry.
            for event in uniqueEvents { event.isSynced = true }
            SwiftDataService.shared.saveModelContext()
            return
        }

        let resultByLocalId = Dictionary(response.events.map { ($0.local_id, $0.event_id) }, uniquingKeysWith: { first, _ in first })
        for event in uniqueEvents {
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
        var seenEmails: Set<String> = []
        var migrateParticipants: [MigrateParticipant] = []
        for user in event.participants {
            let email = user.email
            guard !email.isEmpty, email != "Guest" else {
                throw MigrateAPIError.participantEmailMissing(eventName: event.eventName)
            }
            if !seenEmails.contains(email) {
                seenEmails.insert(email)
                migrateParticipants.append(MigrateParticipant(email: email, name: user.name))
            }
        }

        // Skip already-synced expenses to avoid BE-side duplicates when a Guest event gets a post-login expense.
        let migrateExpenses = try event.expenses.filter { !$0.isSynced }.map { try buildMigrateExpense(from: $0) }

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
        let covererEmail = expense.coverer.email
        guard !covererEmail.isEmpty, covererEmail != "Guest" else {
            throw MigrateAPIError.covererEmailMissing(expenseName: expense.name)
        }

        let items = try expense.items.map { item -> MigrateItem in
            let assignees = try item.assignees.map { person -> MigrateAssignee in
                let email = person.user.email
                guard !email.isEmpty, email != "Guest" else {
                    throw MigrateAPIError.assigneeEmailMissing(itemName: item.itemName)
                }
                return MigrateAssignee(email: email, share: person.share)
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
            coverer_email: covererEmail,
            receipt_url: nil,
            date: expense.dateOfCreation.iso8601String,
            items: items,
            additional_charges: charges
        )
    }

    private func rewriteGuestEmails(events: [EventData], ownerEmail: String) {
        for event in events {
            for user in event.participants where user.email == "Guest" || user.email.isEmpty {
                user.email = ownerEmail
            }
            for expense in event.expenses {
                if expense.coverer.email == "Guest" || expense.coverer.email.isEmpty {
                    expense.coverer.email = ownerEmail
                }
                for item in expense.items {
                    for assignee in item.assignees where assignee.user.email == "Guest" || assignee.user.email.isEmpty {
                        assignee.user.email = ownerEmail
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
