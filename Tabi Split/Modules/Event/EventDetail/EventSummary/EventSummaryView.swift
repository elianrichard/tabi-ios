//
//  EventDetailSummaryView.swift
//  Tabi
//
//  Created by Elian Richard on 07/10/24.
//

import SwiftUI

struct EventSummaryView: View {
    @Environment(Routes.self) private var routes
    
    var body: some View {
        VStack (spacing: 18) {
            VStack (spacing: 4) {
                Text("You owe")
                    .font(.subheadline)
                Text("Rp 200.000")
                    .font(.title)
            }
            .padding(.horizontal, 72)
            .padding(.vertical, 18)
            .background(Color(UIColor(hex: "#EBEBEB")))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            
            VStack (spacing: 16) {
                HStack {
                    Text("Your Expense History")
                    Spacer()
                    Button {
                        routes.navigate(to: .EventSummaryDetailView)
                    } label: {
                        Text("See Details")
                            .font(.caption)
                            .underline(true)
                            .foregroundStyle(.black)
                    }
                }
                ScrollView (showsIndicators: false) {
                    VStack (spacing: 0) {
                        EventSummaryHistoryCard(itemName: "KFC", amount: 500000, date: Date())
                        EventSummaryHistoryCard(itemName: "McDonald", amount: -500000, date: Date().yesterday())
                        EventSummaryHistoryCard(itemName: "Marugame Udon", amount: 500000, date: Date(dateString: "2024-10-11"))
                        EventSummaryHistoryCard(itemName: "Hokben", amount: 500000, date: Date(dateString: "2024-10-11"))
                        EventSummaryHistoryCard(itemName: "Pizza Hut", amount: 500000, date: Date(dateString: "2024-10-11"), isLast: true)
                    }
                }
            }
            .padding([.top, .leading, .trailing], 16)
            .background(Color(UIColor(hex: "#F7F7F7")))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            
            HStack (alignment: .top, spacing: 12) {
                EventSummarySpendingCard(text: "Group Spending", amount: 7_900_000)
                EventSummarySpendingCard(text: "Your Spending", amount: 2_080_000)
            }
        }
    }
}

#Preview {
    EventSummaryView()
        .environment(Routes())
}
