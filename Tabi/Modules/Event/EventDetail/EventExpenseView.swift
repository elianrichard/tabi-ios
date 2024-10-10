//
//  EventExpenseView.swift
//  Tabi
//
//  Created by Elian Richard on 07/10/24.
//

import SwiftUI

struct EventExpenseView: View {
    @EnvironmentObject var eventViewModel: EventViewModel
    var body: some View {
        ScrollView (showsIndicators: false) {
            VStack {
                ForEach(eventViewModel.expenses) { expense in
                    EventDetailCardView(expense: expense)
                }
            }
        }
    }
}

#Preview {
    EventExpenseView()
}
