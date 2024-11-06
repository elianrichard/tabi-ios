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
    
    var user: UserData
    var amount: Float
    var type: SettlementCardTypeEnum
    
    @State var isNotified = false
    @Binding var isShowUploadSheet: Bool
    
    var body: some View {
        VStack (spacing: 16) {
            HStack {
                UserAvatar(userData: user, namePosition: .right)
                Spacer()
                Text("Rp\(amount.formatPrice())")
                    .font(.tabiHeadline)
            }
            Divider()
            VStack (spacing: 16) {
                HStack {
                    HStack (spacing: .spacingSmall) {
                        Circle()
                            .fill(type.statusColor)
                            .frame(width: 10)
                        Text("\(type.statusText)")
                            .font(.tabiBody)
                    }
                    Spacer()
                    if (type == .NeedPayment) {
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
                    } else if (type == .WaitingPayment) {
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
                if (type == .NeedConfirmation || type == .NeedPayment) {
                    Button {
                        eventSettlementViewModel.selectedSettlementType = type
                        eventSettlementViewModel.user = user
                        if (type == .NeedConfirmation) {
                            eventSettlementViewModel.receiptImage = .samplePaymentReceipt
                            routes.navigate(to: .SettlementConfirmationView)
                        } else {
                            isShowUploadSheet = true
                        }
                    } label: {
                        HStack (spacing: .spacingTight) {
                            Icon(type.actionIcon, color: .textWhite, size: 20)
                            Text("\(type.actionText)")
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

#Preview {
    VStack {
        SettlementCard(user: UserData(name: "Elian", phone: "phone"), amount: 250_000, type: .NeedConfirmation, isShowUploadSheet: .constant(false))
        SettlementCard(user: UserData(name: "Elian", phone: "phone"), amount: 250_000, type: .NeedPayment, isShowUploadSheet: .constant(false))
        SettlementCard(user: UserData(name: "Elian", phone: "phone"), amount: 250_000, type: .WaitingConfirmation, isShowUploadSheet: .constant(false))
        SettlementCard(user: UserData(name: "Elian", phone: "phone"), amount: 250_000, type: .WaitingPayment, isShowUploadSheet: .constant(false))
    }
    .environment(Routes())
    .environment(EventSettlementViewModel())
}
