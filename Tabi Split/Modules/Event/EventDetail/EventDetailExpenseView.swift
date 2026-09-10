//
//  EventExpenseView.swift
//  Tabi
//
//  Created by Elian Richard on 07/10/24.
//

import SwiftUI

struct EventDetailExpenseView: View {
    @Environment(EventViewModel.self) private var eventViewModel
    /// Pull-to-refresh handler; the parent decides what "refresh" means.
    var onRefresh: () async -> Void = {}

    var body: some View {
        ScrollView (showsIndicators: false) {
            LazyVStack {
                if let event = eventViewModel.selectedEvent {
                    ForEach(event.expenses.sorted(by: { $0.dateOfCreation > $1.dateOfCreation })) { expense in
                        EventDetailExpenseCard(expense: expense)
                    }
                }
            }
        }
        .refreshable {
            // SwiftUI cancels the refresh action's task when the view owning this
            // modifier is re-evaluated mid-refresh (the parent flips `isSyncing`
            // as soon as the fetch starts), which surfaced as URLError -999
            // "cancelled". Do the work in an unstructured task so cancelling the
            // gesture task doesn't abort the fetch; the pull spinner still waits
            // for the result.
            await Task { await onRefresh() }.value
        }
    }
}

#Preview {
    EventDetailExpenseView()
        .environment(EventViewModel())
}
