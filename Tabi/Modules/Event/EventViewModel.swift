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
        if let selectedEvent = selectedEvent {
            selectedEvent.eventName = name
            selectedEvent.participants = selectedContacts
        } else {
            SwiftDataService.shared.addEvent(EventData(eventName: name, participants: [UserData(name: "You", phone: "08123456789")] + selectedContacts))
        }
    }
    
    @MainActor
    func handleDeleteEvent () {
        if let selectedEvent {
            SwiftDataService.shared.deleteEvent(selectedEvent)            
        }
    }
}
