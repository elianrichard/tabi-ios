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
    
    var isEventCompleted: Bool = false
    var completionDate: Date?
    
    var selectedEvent: EventData? {
        didSet {
            eventName = self.selectedEvent?.eventName ?? ""
            selectedSection = .expenses
        }
    }
    var selectedSection: EventSectionEnum = .expenses
    
    @MainActor
    func handleCreateEditEvent () {
        if (selectedEvent != nil) {
            selectedEvent?.eventName = eventName
        } else {
            SwiftDataService.shared.addEvent(EventData(eventName: eventName))
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
