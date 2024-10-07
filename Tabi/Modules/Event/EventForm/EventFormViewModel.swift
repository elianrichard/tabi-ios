//
//  EventFormViewModel.swift
//  Tabi
//
//  Created by Elian Richard on 06/10/24.
//

import SwiftUI

@Observable
final class EventFormViewModel: ObservableObject {
    var eventName: String = ""

    @MainActor
    func handleCreateEvent () {
        SwiftDataService.shared.addEvent(EventData(eventName: eventName))
    }
}
