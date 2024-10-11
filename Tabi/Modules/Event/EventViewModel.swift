//
//  EventFormViewModel.swift
//  Tabi
//
//  Created by Elian Richard on 06/10/24.
//

import SwiftUI

@Observable
class EventViewModel {
    var eventName: String = ""
    var selectedEvent: EventData? {
        didSet {
            selectedSection = .expenses
        }
    }
    var selectedSection: EventSectionEnum = .expenses

    @MainActor
    func handleCreateEditEvent (selectedContacts: [UserData]) {
        if let selectedEvent = selectedEvent {
            selectedEvent.eventName = eventName
            selectedEvent.participants = selectedContacts
        } else {
            SwiftDataService.shared.addEvent(EventData(eventName: eventName, participants: [UserData(name: "You", phone: "08123456789")] + selectedContacts))
        }
    }
    
    @MainActor
    func handleDeleteEvent () {
        if let selectedEvent {
            SwiftDataService.shared.deleteEvent(selectedEvent)            
        }
    }
}
