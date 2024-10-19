//
//  EventFormViewModel.swift
//  Tabi
//
//  Created by Elian Richard on 06/10/24.
//

import SwiftUI

@Observable
final class EventViewModel {
    var eventName: String = ""

    var isEventCompleted: Bool = false
    var completionDate: Date?

    var selectedEvent: EventData? {
        didSet {
            eventName = self.selectedEvent?.eventName ?? ""
            selectedSection = .expenses
        }
    }
    var selectedSection: EventSectionEnum = .summary

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

    @MainActor
    func completeEvent() {
        isEventCompleted = true
        completionDate = Date()
    }
}
