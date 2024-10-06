//
//  HomeViewModel.swift
//  Tabi
//
//  Created by Elian Richard on 03/10/24.
//

import Foundation

@Observable class HomeViewModel: ObservableObject {
    var selectedFilter: HomeFilterItems {
        didSet {
            filterEvents(by: selectedFilter)
        }
    }
    var events: [EventData]
    var filteredEvents: [EventData]
    
    init() {
        self.selectedFilter = .all
        self.events = mockEventData
        self.filteredEvents = mockEventData
    }
    
    private func filterEvents(by filter: HomeFilterItems) {
        switch filter {
        case .all:
            filteredEvents = events
        case .youOwe:
            filteredEvents = events.filter { $0.userEventBalance < 0 }
        case .owsYou:
            filteredEvents = events.filter { $0.userEventBalance > 0 }
        case .settled:
            filteredEvents = events.filter { $0.userEventBalance == 0 }
        }
    }
}
