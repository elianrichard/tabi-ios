//
//  EventSummaryDetailView.swift
//  Tabi Split
//
//  Created by Elian Richard on 16/10/24.
//

import SwiftUI

struct EventSummaryDetailView: View {
    @Environment(Router.self) private var router
    @Environment(EventViewModel.self) private var eventViewModel
    
    var body: some View {
        VStack (spacing: 0) {
            TopNavigation(title: "Your Transaction History")
                .padding(.horizontal)
            ScrollView {
                LazyVStack {
                    Divided {
                        ForEach(eventViewModel.userTransactionHistory) { data in
                            EventSummaryHistoryCard(data: data)
                        }
                    }
                }
                .padding(.horizontal, .spacingMedium)
            }
        }
        .padding(.top)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    EventSummaryDetailView()
        .environment(Router())
        .environment(EventViewModel())
}
