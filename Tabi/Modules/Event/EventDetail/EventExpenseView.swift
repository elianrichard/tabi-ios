//
//  EventExpenseView.swift
//  Tabi
//
//  Created by Elian Richard on 07/10/24.
//

import SwiftUI

struct EventExpenseView: View {
    @Environment(EventViewModel.self) private var eventViewModel
    var body: some View {
        ScrollView (showsIndicators: false) {
            VStack {
                ForEach(eventViewModel.selectedEvent?.expenses ?? []) { expense in
                    EventDetailCardView(expense: expense)
                }
            }
        }
    }
}

#Preview {
    EventExpenseView()
}
