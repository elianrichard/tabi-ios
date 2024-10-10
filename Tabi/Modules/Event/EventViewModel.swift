//
//  EventFormViewModel.swift
//  Tabi
//
//  Created by Elian Richard on 06/10/24.
//

import SwiftUI

@Observable
final class EventViewModel: ObservableObject {
    var selectedEvent: EventData? {
        didSet {
            selectedSection = .expenses
        }
    }
    var selectedSection: EventSectionEnum = .expenses

    @MainActor
    func handleCreateEditEvent (name: String, selectedContacts: [UserData]) {
        if (selectedEvent != nil) {
            selectedEvent?.eventName = name
        } else {
            SwiftDataService.shared.addEvent(EventData(eventName: name, participants: selectedContacts))
        }
    }
    
    @MainActor
    func handleDeleteEvent () {
        if let selectedEvent {
            SwiftDataService.shared.deleteEvent(selectedEvent)            
        }
    }
}
