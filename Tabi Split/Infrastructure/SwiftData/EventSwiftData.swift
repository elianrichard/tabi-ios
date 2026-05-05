//
//  EventDataService.swift
//  Tabi
//
//  Created by Elian Richard on 30/09/24.
//

import Foundation
import SwiftData
import OSLog

private let eventLogger = Logger(subsystem: "com.tabi.split", category: "SwiftData.Event")

extension SwiftDataService {
    @MainActor
    func addEvent(_ event: EventData) {
        modelContext.insert(event)
        saveModelContext()
    }

    @MainActor
    func fetchAllEvents() -> [EventData]? {
        let fetchDescriptor = FetchDescriptor<EventData>()
        do {
            return try modelContext.fetch(fetchDescriptor)
        } catch {
            eventLogger.error("fetchAllEvents failed: \(error.localizedDescription)")
            return nil
        }
    }

    @MainActor
    func updateEvent(_ event: EventData, index: Int) {
        guard let allEvents = fetchAllEvents(), index < allEvents.count else { return }
        let target = allEvents[index]
        target.eventName = event.eventName
        target.eventIcon = event.eventIcon
        target.participants = event.participants
        target.completionDate = event.completionDate
        saveModelContext()
    }

    @MainActor
    func deleteEvent(at index: Int) {
        if let allEvents = fetchAllEvents() {
            let event = allEvents[index]
            modelContext.delete(event)
            saveModelContext()
        }
    }

    @MainActor
    func deleteEvent(_ event: EventData) {
        modelContext.delete(event)
    }

    @MainActor
    func completeEvent(_ event: EventData) {
        if let target = fetchAllEvents()?.first(where: { $0 == event }) {
            target.completionDate = Date()
            saveModelContext()
        }
    }

    @MainActor
    func incompleteEvent(_ event: EventData) {
        if let target = fetchAllEvents()?.first(where: { $0 == event }) {
            target.completionDate = nil
            saveModelContext()
        }
    }

    @MainActor
    func deleteAllEvents() {
        deleteModelContext(type: EventData.self)
    }
}
