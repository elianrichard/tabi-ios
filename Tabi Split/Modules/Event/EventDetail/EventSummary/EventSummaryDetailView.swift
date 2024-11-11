//
//  EventSummaryDetailView.swift
//  Tabi Split
//
//  Created by Elian Richard on 16/10/24.
//

import SwiftUI

struct EventSummaryDetailView: View {
    @Environment(Routes.self) private var routes
    @Environment(EventViewModel.self) private var eventViewModel
    
    var body: some View {
        VStack (spacing: .spacingMedium) {
            TopNavigation(title: "Your Transaction History")
                .padding(.horizontal)
            ScrollView {
                VStack {
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
        .environment(Routes())
        .environment(EventViewModel())
}
