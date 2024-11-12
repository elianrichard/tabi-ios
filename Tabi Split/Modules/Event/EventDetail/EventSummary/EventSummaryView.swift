//
//  EventDetailSummaryView.swift
//  Tabi
//
//  Created by Elian Richard on 07/10/24.
//

import SwiftUI

struct EventSummaryView: View {
    @Environment(Routes.self) private var routes
    @Environment(EventViewModel.self) private var eventViewModel
    
    
    var body: some View {
        VStack (spacing: .spacingRegular) {
            VStack {
                if (eventViewModel.userBalance.status != .settled) {
                    HStack (spacing: 20) {
                        Spacer()
                            .frame(width: 30)
                        VStack (spacing: .spacingXSmall) {
                            Text(eventViewModel.userBalance.status.summaryCardText)
                                .font(.tabiBody)
                            Text("Rp\((eventViewModel.userBalance.balance).formatPrice(isShowSign: false))")
                                .font(.tabiTitle)
                        }
                        Icon(systemName: "chevron.right", color: .textWhite, size: 12)
                            .offset(x: 1)
                            .frame(width: 30, height: 30, alignment: .center)
                            .background(eventViewModel.userBalance.status.summaryCardBgShadow.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .background(eventViewModel.userBalance.status.summaryCardBgColor)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding(.bottom, 6)
                    .background(eventViewModel.userBalance.status.summaryCardBgShadow)
                } else {
                    HStack {
                        Text(eventViewModel.userBalance.status.summaryCardText)
                            .font(.tabiSubtitle)
                    }
                    .foregroundStyle(.textGrey)
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .background(.uiWhite)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(.uiGray, lineWidth: 2)
                    }
                }
            }
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
                    ForEach(Array(eventViewModel.userTransactionHistory.prefix(3))) { data in
                        EventSummaryHistoryCard(data: data)
                    }
                }
            }
            .padding(.spacingRegular)
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(.uiGray, lineWidth: 1)
            }
            .padding(1)
            
            
            HStack (alignment: .top) {
                EventSummarySpendingCard(text: "Your total spending", amount: eventViewModel.userTotalSpending)
            }
        }
    }
}

#Preview {
    EventSummaryView()
        .environment(Routes())
        .environment(EventViewModel())
}
