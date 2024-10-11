//
//  HomeViewModel.swift
//  Tabi
//
//  Created by Elian Richard on 03/10/24.
//

import Foundation

@Observable
final class HomeViewModel {
    var selectedFilter: HomeFilterEnum {
        didSet {
            filterEvents(by: selectedFilter)
        }
    }
    var events: [EventData]
    var filteredEvents: [EventData]
    
    init() {
        self.selectedFilter = .all
        self.events = []
        self.filteredEvents = []
    }
    
    func populateEvents (data: [EventData]) {
        events = data
        filteredEvents = data
        selectedFilter = .all
    }
    
    func filterEvents(by filter: HomeFilterEnum) {
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
