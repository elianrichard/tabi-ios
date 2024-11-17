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
        ScrollView (showsIndicators: false) {
            VStack (spacing: .spacingRegular) {
                if (!eventViewModel.isEventCompleted) {
                    DialogBox(icon: "exclamationmark.triangle.fill",
                              iconColor: .buttonBlue,
                              text: "You can only settle after you set the event to complete",
                              backgroundColor: .bgBlueElevated)
                }
                VStack {
                    if (eventViewModel.userBalance.status != .settled) {
                        if (eventViewModel.isEventCompleted) {
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
                            .clipShape(RoundedRectangle(cornerRadius: .radiusMedium))
                            .padding(.bottom, 6)
                            .background(eventViewModel.userBalance.status.summaryCardBgShadow)
                            .clipShape(RoundedRectangle(cornerRadius: .radiusLarge))
                        } else {
                            VStack (spacing: .spacingXSmall) {
                                Text(eventViewModel.userBalance.status.summaryCardText)
                                    .font(.tabiBody)
                                Text("Rp\((eventViewModel.userBalance.balance).formatPrice(isShowSign: false))")
                                    .font(.tabiTitle)
                            }
                            .foregroundStyle(eventViewModel.userBalance.status.summaryCardBgColor)
                            .frame(maxWidth: .infinity, minHeight: 80)
                            .background(.clear)
                            .overlay {
                                RoundedRectangle(cornerRadius: .radiusMedium)
                                    .strokeBorder(.uiGray, lineWidth: 2)
                            }
                        }
                    } else {
                        HStack {
                            VStack (spacing: .spacingSmall) {
                                Text(eventViewModel.userBalance.status.summaryCardText)
                                    .font(.tabiSubtitle)
                                if eventViewModel.isEventCompleted {
                                    Button {
                                        routes.navigate(to: .SettlementOptimizationView)
                                    } label: {
                                        Text("See Optimization Details")
                                            .foregroundStyle(.textBlue)
                                            .font(.tabiBody)
                                    }
                                }
                            }
                        }
                        .foregroundStyle(.textGrey)
                        .frame(maxWidth: .infinity, minHeight: 80)
                        .background(.clear)
                        .overlay {
                            RoundedRectangle(cornerRadius: .radiusMedium)
                                .strokeBorder(.uiGray, lineWidth: 2)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: .radiusMedium))
                    }
                }
                .onTapGesture {
                    if (eventViewModel.isEventCompleted) {
//                        TEMPORARILY DISABLED: SETTLEMENT
//                        routes.navigate(to: .EventSettlementView)
                        routes.navigate(to: .SettlementOptimizationView)
                    } else {
                        print("Cannot do this action yet")
                    }
                }
                
                VStack (spacing: 16) {
                    HStack {
                        Text("Your Balance History")
                            .font(.tabiHeadline)
                        Spacer()
                        Button {
                            routes.navigate(to: .EventSummaryDetailView)
                        } label: {
                            Text("See All")
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
}

#Preview {
    EventSummaryView()
        .environment(Routes())
        .environment(EventViewModel())
}
