//
//  EventFormViewModel.swift
//  Tabi
//
//  Created by Elian Richard on 06/10/24.
//

import SwiftUI

@Observable
final class EventViewModel: ObservableObject {
    var eventName: String = ""
    var selectedEvent: EventData? {
        didSet {
            eventName = self.selectedEvent?.eventName ?? ""
            selectedSection = .expenses
            selectedContacts = self.selectedEvent?.participants ?? []
        }
    }
    var selectedSection: EventSectionEnum = .expenses
    var selectedContacts: [UserData] = []

    @MainActor
    func handleCreateEditEvent () {
        if (selectedEvent != nil) {
            selectedEvent?.eventName = eventName
            selectedEvent?.participants = selectedContacts
        } else {
            SwiftDataService.shared.addEvent(EventData(eventName: eventName, participants: selectedContacts))
        }
    }
    
    @MainActor
    func handleDeleteEvent () {
        if let selectedEvent {
            SwiftDataService.shared.deleteEvent(selectedEvent)            
        }
    }
}
