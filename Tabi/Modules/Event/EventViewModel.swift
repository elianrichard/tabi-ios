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
        }
    }
    var selectedSection: EventSectionEnum = .expenses
    
    var expenses: [Expense] = [
        Expense(name: "Sate", coverer: "Naufal", dateOfCreation: .now, price: 100000),
        Expense(name: "Bakso", coverer: "Elian", dateOfCreation: .distantPast, price: 50000),
        Expense(name: "Micin", coverer: "Rafael Mario Omar Zhang", dateOfCreation: Date.now.addingTimeInterval(-86400), price: 200000),
        Expense(name: "Hotel", coverer: "Dharmawan Ruslan", dateOfCreation: Date.now.addingTimeInterval(-86400*2), price: 300000),
        Expense(name: "Tayo", coverer: "Elvina Vincensia", dateOfCreation: Date.now.addingTimeInterval(-86400*3), price: 75000),
    ]

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
}
