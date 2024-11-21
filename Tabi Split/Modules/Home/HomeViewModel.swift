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
        filteredEvents = eventData.sorted(by: { $0.createdAt < $1.createdAt })
    }
    
    @MainActor
    func refreshEventData (isGuest: Bool) {
        Task {
            if !isGuest {
                do {
                    isLoading = true
                    let data = try await EventService.shared.getAllEvents()
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
                        //                    TODO: Remove this temporary fix for duplication bug on get event list
                        if !isGuest {
                            participants = Array(
                                Dictionary(grouping: participants, by: { $0.userId }).values.map { $0.first! }
                            )
                        }
                        //                    TODO: Add Created add for event from DB
                        let newEvent = EventData(eventId: event.id, eventName: event.name, eventIcon: image, participants: participants)
                        SwiftDataService.shared.addEvent(newEvent)
                    }
                } catch {
                    print("Fetch event failed: \(error)")
                }
            }
            if let data = SwiftDataService.shared.fetchAllEvents() {
                let sortedData = data.sorted(by: { $0.createdAt < $1.createdAt })
                //                TODO: Remove this temporary fix for duplication bug on get event list
                var eventData: [EventData] = sortedData
                if !isGuest {
                    eventData = Array(
                        Dictionary(grouping: sortedData, by: { $0.eventId }).values.map { $0.first! }
                    )
                }
                events = eventData
                filteredEvents = eventData
                selectedFilter = .all
            }
            isLoading = false
        }
    }
}
