//
//  SettlementCard.swift
//  Tabi Split
//
//  Created by Elian Richard on 16/10/24.
//

import SwiftUI

struct SettlementCard: View {
    @Environment(Routes.self) private var routes
    var user: UserData
    var amount: Float
    var type: SettlementCardTypeEnum
    
    @State var isNotified = true
    
    var body: some View {
        VStack (spacing: 16) {
            HStack {
                HStack (spacing: .spacingTight) {
                    UserAvatar(userData: user)
                    Text("\(user.name)")
                        .font(.tabiHeadline)
                }
                Spacer()
                Text("Rp\(amount.formatPrice())")
                    .font(.tabiHeadline)
            }
            Divider()
            VStack (spacing: 16) {
                HStack {
                    HStack {
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
                            isNotified.toggle()
                            print("turn on notification")
                        } label: {
                            Image(systemName: isNotified ? "bell.and.waves.left.and.right" :  "bell")
                                .foregroundStyle(isNotified ? .blue : .gray)
                        }
                    }
                }
                if (type == .NeedConfirmation || type == .NeedPayment) {
                    Button {
                        routes.navigate(to: .SettlementConfirmationView)
                    } label: {
                        HStack {
                            Image(systemName: "\(type.actionIcon)")
                            Text("\(type.actionText)")
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
        SettlementCard(user: UserData(name: "Elian", phone: "phone"), amount: 250_000, type: .NeedConfirmation)
        SettlementCard(user: UserData(name: "Elian", phone: "phone"), amount: 250_000, type: .NeedPayment)
        SettlementCard(user: UserData(name: "Elian", phone: "phone"), amount: 250_000, type: .WaitingConfirmation)
        SettlementCard(user: UserData(name: "Elian", phone: "phone"), amount: 250_000, type: .WaitingPayment)
    }
        .environment(Routes())
}
