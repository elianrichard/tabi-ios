//
//  EventSummaryDetailView.swift
//  Tabi Split
//
//  Created by Elian Richard on 16/10/24.
//

import SwiftUI

struct EventSummaryDetailView: View {
    @Environment(Routes.self) private var routes
    
    var body: some View {
        VStack (spacing: 24) {
            ZStack {
                Text("Your Expense History")
                    .font(.title2)
                HStack {
                    Button {
                        routes.navigateBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.black)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal)
            ScrollView {
                VStack {
                    EventSummaryHistoryCard(itemName: "KFC", amount: 500000, date: Date())
                    EventSummaryHistoryCard(itemName: "McDonald", amount: -500000, date: Date().yesterday())
                    EventSummaryHistoryCard(itemName: "Marugame Udon", amount: 500000, date: Date(dateString: "2024-10-11"))
                    EventSummaryHistoryCard(itemName: "Hokben", amount: 500000, date: Date(dateString: "2024-10-11"))
                    EventSummaryHistoryCard(itemName: "KFC", amount: 500000, date: Date())
                    EventSummaryHistoryCard(itemName: "McDonald", amount: -500000, date: Date().yesterday())
                    EventSummaryHistoryCard(itemName: "Marugame Udon", amount: 500000, date: Date(dateString: "2024-10-11"))
                    EventSummaryHistoryCard(itemName: "Hokben", amount: 500000, date: Date(dateString: "2024-10-11"))
                    EventSummaryHistoryCard(itemName: "KFC", amount: 500000, date: Date())
                    EventSummaryHistoryCard(itemName: "McDonald", amount: -500000, date: Date().yesterday())
                    EventSummaryHistoryCard(itemName: "Marugame Udon", amount: 500000, date: Date(dateString: "2024-10-11"))
                    EventSummaryHistoryCard(itemName: "Hokben", amount: 500000, date: Date(dateString: "2024-10-11"))
                    EventSummaryHistoryCard(itemName: "Pizza Hut", amount: 500000, date: Date(dateString: "2024-10-11"), isLast: true)
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.top)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    EventSummaryDetailView()
        .environment(Routes())
}
