//
//  SettlementCard.swift
//  Tabi Split
//
//  Created by Elian Richard on 16/10/24.
//

import SwiftUI


struct SettlementCard: View {
    @Environment(Routes.self) private var routes
    var name: String
    var amount: Float
    var type: SettlementCardTypeEnum
    @State var isNotified = true
    
    var body: some View {
        VStack (spacing: 16) {
            HStack {
                HStack {
                    Circle()
                        .fill(Color(UIColor(hex: "#D9D9D9")))
                        .frame(width: 40)
                    Text("\(name)")
                }
                Spacer()
                Text("Rp \(amount.formatPrice())")
            }
            Divider()
            VStack (spacing: 16) {
                HStack {
                    HStack {
                        Circle()
                            .fill(type.statusColor)
                            .frame(width: 10)
                        Text("\(type.statusText)")
                    }
                    Spacer()
                    if (type == .NeedPayment) {
                        Button {
                            routes.navigate(to: .SettlementPaymentMethodView)
                        } label: {
                            Text("Payment Method")
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
                        print("upload payment")
                    } label: {
                        HStack {
                            Image(systemName: "\(type.actionIcon)")
                            Text("\(type.actionText)")
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: .infinity))
                    }
                }
            }
            
        }
        .padding(16)
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .fill(.clear)
                .stroke(Color(UIColor(hex: "#E8E8E8")), lineWidth: 1)
        }
        .padding(1)
    }
}

#Preview {
    SettlementCard(name: "Elian", amount: 250_000, type: .NeedConfirmation)
        .environment(Routes())
}
