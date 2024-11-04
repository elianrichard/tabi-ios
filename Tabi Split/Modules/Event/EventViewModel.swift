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
    var eventIcon: EventIconEnum = .icon1

    var isEventCompleted: Bool = false
    var completionDate: Date?

    var selectedEvent: EventData? {
        didSet {
            eventName = self.selectedEvent?.eventName ?? ""
            eventIcon = EventIconEnum(rawValue: self.selectedEvent?.eventIcon ?? EventIconEnum.icon1.id) ?? .icon1
            selectedSection = .expenses
        }
    }
    var selectedSection: EventSectionEnum = .expenses
    var isNoParticipants: Bool {
        selectedEvent?.participants.count ?? 1 == 1
    }

    @MainActor
    func handleCreateEditEvent (selectedContacts: [UserData]) {
        if let selectedEvent = selectedEvent {
            selectedEvent.eventName = eventName
            selectedEvent.eventIcon = eventIcon.id
            selectedEvent.participants = selectedContacts
        } else {
            SwiftDataService.shared.addEvent(EventData(eventName: eventName, eventIcon: eventIcon, participants: [UserData(name: "You", phone: "08123456789")] + selectedContacts))
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
