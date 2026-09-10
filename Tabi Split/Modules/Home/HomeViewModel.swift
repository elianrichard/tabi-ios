//
//  HomeViewModel.swift
//  Tabi
//
//  Created by Elian Richard on 03/10/24.
//

import SwiftUI

@Observable
final class HomeViewModel {
    var selectedFilter: HomeFilterEnum = .all {
        didSet {
            filterEvents(by: selectedFilter)
        }
    }
    var events: [EventData] = []
    var filteredEvents: [EventData] = []
    var notificationCount: Int = 0
    var isLoading: Bool = false
    
    func filterEvents(by filter: HomeFilterEnum) {
        var eventData: [EventData] = []
        switch filter {
        case .all:
            eventData = events
        case .youOwe:
            eventData = events.filter { $0.userEventBalance < 0 }
        case .owsYou:
            eventData = events.filter { $0.userEventBalance > 0 }
        case .settled:
            eventData = events.filter { $0.userEventBalance == 0 }
        }
        filteredEvents = eventData
    }
    
    @MainActor
    func refreshEventData (currentUser: UserData, isShowLoading: Binding<Bool>) async -> Bool {
        if (!isLoading) {
            do {
                isLoading = true
                isShowLoading.wrappedValue = true
                let data = try await EventService.shared.getAllEvents()

                // Drop synced rows only; unsynced rows stay queued for retry.
                let existing = SwiftDataService.shared.fetchAllEvents() ?? []
                for event in existing where event.isSynced {
                    SwiftDataService.shared.deleteEvent(event)
                }
                SwiftDataService.shared.saveModelContext()

                for event in data.events {
                    EventData.insertSynced(from: event, currentUser: currentUser, in: SwiftDataService.shared.modelContext)
                    SwiftDataService.shared.saveModelContext()
                }
            } catch {
                print("Fetch event failed: \(error)")
            }
        }
        
        if let data = SwiftDataService.shared.fetchAllEvents() {
            let eventData = data.sorted(by: { $0.createdAt > $1.createdAt })
            events = eventData
            filteredEvents = eventData
            selectedFilter = .all
        }
        
        isLoading = false
        isShowLoading.wrappedValue = false
        return true
    }
    
}
