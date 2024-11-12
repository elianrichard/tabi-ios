//
//  SettlementCard.swift
//  Tabi Split
//
//  Created by Elian Richard on 16/10/24.
//

import SwiftUI

struct SettlementCard: View {
    @Environment(Routes.self) private var routes
    @Environment(EventSettlementViewModel.self) private var eventSettlementViewModel
    
    var data: SummarySettlementData
    @Binding var isShowUploadSheet: Bool
    
    @State var isNotified = false
    
    var body: some View {
        VStack (spacing: 16) {
            HStack {
                UserAvatar(userData: data.targetUser, namePosition: .right)
                Spacer()
                Text("Rp\(data.amount.formatPrice())")
                    .font(.tabiHeadline)
            }
            Divider()
            VStack (spacing: 16) {
                HStack {
                    HStack (spacing: .spacingSmall) {
                        Circle()
                            .fill(data.status.statusColor)
                            .frame(width: 10)
                        Text("\(data.status.statusText)")
                            .font(.tabiBody)
                    }
                    Spacer()
                    if (data.status == .NeedPayment) {
                        Button {
                            routes.navigate(to: .SettlementPaymentMethodView)
                        } label: {
                            HStack (spacing: .spacingXSmall) {
                                Text("Payment Methods")
                                    .font(.tabiBody)
                                    .foregroundStyle(.textBlue)
                                Icon(systemName: "chevron.right", color: .textBlue, size: 12)
                            }
                        }
                    } else if (data.status == .WaitingPayment) {
                        Button {
                            withAnimation (nil) {
                                isNotified.toggle()
                            }
                            print("turn on notification")
                        } label: {
                            HStack (spacing: .spacingXSmall){
                                Icon(systemName: !isNotified ? "bell" : "bell.and.waves.left.and.right", color: !isNotified ? .textBlue : .textGrey, size: !isNotified ? 16 : 24)
                                if !isNotified {
                                    Text("Remind")
                                        .font(.tabiBody)
                                        .foregroundStyle(.textBlue)
                                }
                            }
                            .frame(height: 20)
                        }
                    }
                }
                if (data.status == .NeedConfirmation || data.status == .NeedPayment) {
                    Button {
                        eventSettlementViewModel.selectedSettlementType = data.status
                        eventSettlementViewModel.user = data.targetUser
                        if (data.status == .NeedConfirmation) {
                            eventSettlementViewModel.receiptImage = .samplePaymentReceipt
                            routes.navigate(to: .SettlementConfirmationView)
                        } else {
                            isShowUploadSheet = true
                        }
                    } label: {
                        HStack (spacing: .spacingTight) {
                            Icon(data.status.actionIcon, color: .textWhite, size: 20)
                            Text("\(data.status.actionText)")
                                .font(.tabiBody)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.buttonBlue)
                        .clipShape(RoundedRectangle(cornerRadius: .infinity))
                    }
                }
            }
        }
        .padding(.vertical, .spacingTight)
        .padding(.horizontal, .spacingMedium)
        .overlay {
            RoundedRectangle(cornerRadius: .radiusMedium)
                .fill(.clear)
                .stroke(.uiGray, lineWidth: 1)
                .padding(1)
        }
    }
}
