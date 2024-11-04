//
//  EventDetailSummaryView.swift
//  Tabi
//
//  Created by Elian Richard on 07/10/24.
//

import SwiftUI

struct EventSummaryView: View {
    @Environment(Routes.self) private var routes
    
    var balance: Float
    @State var status: EventCardStatusEnum
    
    init(balance: Float = 250_000) {
        self.balance = balance
        if (balance > 0) {
            self.status = .credit
        } else if (balance < 0) {
            self.status = .debt
        } else {
            self.status = .settled
        }
    }
    
    var body: some View {
        VStack (spacing: .spacingRegular) {
            VStack {
                if (status != .settled) {
                    HStack (spacing: 20) {
                        Spacer()
                            .frame(width: 30)
                        VStack (spacing: .spacingXSmall) {
                            Text(status.summaryCardText)
                                .font(.tabiBody)
                            Text("Rp\(abs(balance).formatPrice())")
                                .font(.tabiTitle)
                        }
                        Icon(systemName: "chevron.right", color: .textWhite, size: 12)
                            .offset(x: 1)
                            .frame(width: 30, height: 30, alignment: .center)
                            .background(status.summaryCardBgShadow.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: 80)
                    .background(status.summaryCardBgColor)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding(.bottom, 6)
                    .background(status.summaryCardBgShadow)
                } else {
                    HStack {
                        Text(status.summaryCardText)
                            .font(.tabiSubtitle)
                    }
                    .foregroundStyle(.textGrey)
                    .frame(maxWidth: .infinity, maxHeight: 80)
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
                    EventSummaryHistoryCard(itemName: "KFC", amount: 500000, date: Date(), isLast: true)
                    EventSummaryHistoryCard(itemName: "McDonald", amount: -500000, date: Date().yesterday(), isLast: true)
                    EventSummaryHistoryCard(itemName: "Marugame Udon", amount: 500000, date: Date(dateString: "2024-10-11"), isLast: true)
                }
            }
            .padding(.spacingRegular)
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
