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
    func refreshEventData (isGuest: Bool) {
        Task {
            if !isGuest {
                do {
                    isLoading = true
                    let data = try await EventService.shared.getAllEvents()
                    // TODO: Migrate instead of delete, do this after expense CRUD is done
                    SwiftDataService.shared.deleteAllEvents()
                    for event in data.events {
                        let image = EventIconEnum(rawValue: event.avatar_url) ?? .icon1
                        var participants: [UserData] = []
                        
                        if let users = SwiftDataService.shared.getAllUsers() {
                            for dataUser in event.participants {
                                if let targetUser = users.first(where: { dataUser.user_id == $0.userId }) {
                                    targetUser.update(fromUserBase: dataUser)
                                    participants.append(targetUser)
                                } else {
                                    participants.append(UserData(userBase: dataUser))
                                }
                            }
                        }
                        
                        let newEvent = EventData(eventId: event.id, eventName: event.name, completionDate: (event.completion_date ?? "").convertIsoToDate(), eventIcon: image, participants: participants, createdAt: event.created_at.convertIsoToDate(), creatorId: event.creator_id)
                        SwiftDataService.shared.addEvent(newEvent)
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
        }
    }
}
