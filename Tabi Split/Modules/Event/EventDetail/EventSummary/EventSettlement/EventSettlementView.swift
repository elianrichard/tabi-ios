//
//  EventSettlementView.swift
//  Tabi Split
//
//  Created by Elian Richard on 16/10/24.
//

import SwiftUI

struct EventSettlementView: View {
    @Environment(Routes.self) private var routes
    var balance: Float = 200_000
    @State private var contentSize: CGSize = .zero

    
    var body: some View {
        VStack (spacing: 24) {
            TopNavigation(title: balance > 0 ? "You Should Receive" : "You Should Pay")
            ScrollView (showsIndicators: false) {
                VStack {
                    SettlementCard(user: UserData(name: "Elian", phone: "phone"), amount: 250_000, type: .NeedConfirmation)
                    SettlementCard(user: UserData(name: "Elian", phone: "phone"), amount: 250_000, type: .NeedPayment)
                    SettlementCard(user: UserData(name: "Elian", phone: "phone"), amount: 250_000, type: .WaitingConfirmation)
                    SettlementCard(user: UserData(name: "Elian", phone: "phone"), amount: 250_000, type: .WaitingPayment)
                }
                .overlay(
                    GeometryReader { geo in
                        Color.clear.onAppear {
                            contentSize = geo.size
                        }
                    }
                )
            }
            .frame(maxWidth: .infinity, maxHeight: contentSize.height)
            
            Button {
                routes.navigate(to: .SettlementOptimizationView)
            } label: {
                Text("See optimization details")
                    .font(.tabiHeadline)
                    .foregroundStyle(.textBlue)
            }
            Spacer()
            
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}


#Preview {
    EventSettlementView()
        .environment(Routes())
}
