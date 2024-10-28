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
        VStack (spacing: UIConfig.Spacing.Regular) {
            HStack (spacing: 20) {
                Spacer()
                    .frame(width: 30)
                VStack (spacing: UIConfig.Spacing.XSmall) {
                    Text("You should pay")
                        .font(.tabiBody)
                    Text("Rp 250.000")
                        .font(.tabiTitle)
                }
                Icon(systemName: "chevron.right", color: .textWhite, size: 8)
                    .offset(x: 2)
                    .frame(width: 30, height: 30, alignment: .center)
                    .background(.buttonGreenShadow.opacity(0.5))
                    .clipShape(Circle())
            }
            .foregroundStyle(.white)
            .padding(.vertical, UIConfig.Spacing.Tight)
            .frame(maxWidth: .infinity)
            .background(.buttonGreen)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .padding(.bottom, 6)
            .background(.buttonGreenShadow)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .onTapGesture {
                routes.navigate(to: .EventSettlementView)
            }
            
            VStack (spacing: 16) {
                HStack {
                    Text("Your Transaction History")
                        .font(.tabiHeadline)
                    Spacer()
                    Button {
                        routes.navigate(to: .EventSummaryDetailView)
                    } label: {
                        Text("See Details")
                            .font(.tabiBody)
                            .foregroundStyle(.textBlue)
                    }
                }
                VStack (spacing: 0) {
                    EventSummaryHistoryCard(itemName: "KFC", amount: 500000, date: Date())
                    EventSummaryHistoryCard(itemName: "McDonald", amount: -500000, date: Date().yesterday())
                    EventSummaryHistoryCard(itemName: "Marugame Udon", amount: 500000, date: Date(dateString: "2024-10-11"))
                }
            }
            .padding(UIConfig.Spacing.Regular)
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(.uiGray, lineWidth: 1)
            }
            .padding(1)
            
            
            HStack (alignment: .top) {
                EventSummarySpendingCard(text: "Your total spending", amount: 2_080_000)
            }
        }
    }
}

#Preview {
    EventSummaryView()
        .environment(Routes())
}
