//
//  EventDetailSummaryView.swift
//  Tabi
//
//  Created by Elian Richard on 07/10/24.
//

import SwiftUI

struct EventSummaryView: View {
    @Environment(Router.self) private var router
    @Environment(EventViewModel.self) private var eventViewModel
    /// Pull-to-refresh handler; the parent decides what "refresh" means.
    var onRefresh: () async -> Void = {}

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: .spacingRegular) {
                VStack {
                    if eventViewModel.userBalance.status != .settled {
                        //                        if (eventViewModel.isEventCompleted) {
                        HStack(spacing: 20) {
                            Spacer()
                                .frame(width: 30)
                            VStack(spacing: .spacingXSmall) {
                                Text(
                                    eventViewModel.userBalance.status
                                        .summaryCardText
                                )
                                .font(.tabiBody)
                                Text(
                                    "Rp\((eventViewModel.userBalance.balance).formatPrice(isShowSign: false))"
                                )
                                .font(.tabiTitle)
                            }
                            Icon(
                                systemName: "chevron.right",
                                color: .textWhite,
                                size: 12
                            )
                            .offset(x: 1)
                            .frame(width: 30, height: 30, alignment: .center)
                            .background(
                                eventViewModel.userBalance.status
                                    .summaryCardBgShadow.opacity(0.5)
                            )
                            .clipShape(Circle())
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 80)
                        .background(
                            eventViewModel.userBalance.status.summaryCardBgColor
                        )
                        .clipShape(
                            RoundedRectangle(cornerRadius: .radiusMedium)
                        )
                        .padding(.bottom, 6)
                        .background(
                            eventViewModel.userBalance.status
                                .summaryCardBgShadow
                        )
                        .clipShape(RoundedRectangle(cornerRadius: .radiusLarge))
                        //                        } else {
                        //                        VStack(spacing: .spacingXSmall) {
                        //                            Text(
                        //                                eventViewModel.userBalance.status
                        //                                    .summaryCardText
                        //                            )
                        //                            .font(.tabiBody)
                        //                            Text(
                        //                                "Rp\((eventViewModel.userBalance.balance).formatPrice(isShowSign: false))"
                        //                            )
                        //                            .font(.tabiTitle)
                        //                        }
                        //                        .foregroundStyle(
                        //                            eventViewModel.userBalance.status.summaryCardBgColor
                        //                        )
                        //                        .frame(maxWidth: .infinity, minHeight: 80)
                        //                        .background(.clear)
                        //                        .overlay {
                        //                            RoundedRectangle(cornerRadius: .radiusMedium)
                        //                                .strokeBorder(.uiGray, lineWidth: 2)
                        //                        }
                        //                        }
                    } else {
                        HStack {
                            VStack(spacing: .spacingSmall) {
                                Text(
                                    eventViewModel.userBalance.status
                                        .summaryCardText
                                )
                                .font(.tabiSubtitle)
                                if eventViewModel.isEventCompleted {
                                    Button {
                                        router.push(.settlementOptimization)
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
                        .clipShape(
                            RoundedRectangle(cornerRadius: .radiusMedium)
                        )
                    }
                }
                .onTapGesture {
                    //                    TEMPORARILY DISABLED: SETTLEMENT
                    //                    router.push(.eventSettlement)
                    router.push(.settlementOptimization)
                }

                if !eventViewModel.userTransactionHistory.isEmpty {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Your Transaction History")
                                .font(.tabiHeadline)
                            Spacer()
                            Button {
                                router.push(.eventSummaryDetail)
                            } label: {
                                Text("See All")
                                    .font(.tabiBody)
                                    .foregroundStyle(.textBlue)
                            }
                        }
                        LazyVStack {
                            ForEach(
                                Array(
                                    eventViewModel.userTransactionHistory
                                        .prefix(3)
                                )
                            ) { data in
                                EventSummaryHistoryCard(data: data)
                            }
                        }
                    }
                }

                HStack(alignment: .top) {
                    EventSummarySpendingCard(
                        text: "Your total spending",
                        amount: eventViewModel.userTotalSpending
                    )
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
    EventSummaryView()
        .environment(Router())
        .environment(EventViewModel())
}
