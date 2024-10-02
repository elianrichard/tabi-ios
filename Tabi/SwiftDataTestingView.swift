//
//  SwiftDataTesting.swift
//  Tabi
//
//  Created by Elian Richard on 02/10/24.
//

import SwiftUI
import SwiftData

struct SwiftDataTestingView: View {
    var swiftDataTestingViewModel = SwiftDataTestingViewModel()
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(swiftDataTestingViewModel.events) { event in
                    NavigationLink {
                        Text("Event: \(event.name)")
                    } label: {
                        Text("\(event.name)")
                    }
                }
                .onDelete(perform: { offsetIndex in
                    swiftDataTestingViewModel.deleteEvent(offsetIndex)
                })
            }
            
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        swiftDataTestingViewModel.addEvent()
                    }) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
    }
}

#Preview {
    SwiftDataTestingView()
}

@Observable class SwiftDataTestingViewModel {
    var events: [EventData] = []
    
    @MainActor
    init() {
        self.events = SwiftDataService.shared.fetchAllEvents() ?? []
    }
    
    @MainActor
    func addEvent() {
        let new = EventData(name: "New Event")
        SwiftDataService.shared.addEvent(new)
        events.append(new)
    }
    
    @MainActor
    func deleteEvent(_ indexSet: IndexSet) {
        for index in indexSet {
            SwiftDataService.shared.deleteEvent(at: index)
            events.remove(at: index)
        }
    }
}
