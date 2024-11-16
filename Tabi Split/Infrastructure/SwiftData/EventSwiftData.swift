//
//  EventDataService.swift
//  Tabi
//
//  Created by Elian Richard on 30/09/24.
//

import Foundation
import SwiftData

extension SwiftDataService {
    func addEvent (_ event: EventData) {
        modelContext.insert(event)
        saveModelContext()
    }
    
    func fetchAllEvents () -> [EventData]? {
        let fetchDescriptor = FetchDescriptor<EventData>()
        do {
            return try modelContext.fetch(fetchDescriptor)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    func updateEvent (_ event: EventData, index: Int) {
        if var allEvents = fetchAllEvents() {
            allEvents[index] = event
            saveModelContext()
        }
    }
    
    func deleteEvent (at index: Int) {
        if let allEvents = fetchAllEvents() {
            let event = allEvents[index]
            modelContext.delete(event)
            saveModelContext()
        }
    }
    func deleteEvent (_ event: EventData) {
        modelContext.delete(event)
    }
    
    func completeEvent(_ event: EventData) {
        if let allEvents = fetchAllEvents() {
            if let selectedEvent = allEvents.first(where: { $0 == event }) {
                selectedEvent.completionDate = Date()
            }
        }
    }
    
    func incompleteEvent(_ event: EventData) {
        if let allEvents = fetchAllEvents() {
            if let selectedEvent = allEvents.first(where: { $0 == event }) {
                selectedEvent.completionDate = nil
            }
        }
    }
}
