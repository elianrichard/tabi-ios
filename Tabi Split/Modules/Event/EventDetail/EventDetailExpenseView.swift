//
//  EventExpenseView.swift
//  Tabi
//
//  Created by Elian Richard on 07/10/24.
//

import SwiftUI

struct EventDetailExpenseView: View {
    @Environment(EventViewModel.self) private var eventViewModel
    var body: some View {
        ScrollView (showsIndicators: false) {
            VStack {
                if let event = eventViewModel.selectedEvent {
                    ForEach(event.expenses) { expense in
                        EventDetailExpenseCard(expense: expense)
                    }
                }
            }
        }
    }
}

#Preview {
    EventDetailExpenseView()
}
