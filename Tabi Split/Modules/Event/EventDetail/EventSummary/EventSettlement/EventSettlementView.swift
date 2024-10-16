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
            ZStack {
                Text(balance > 0 ? "You Should Receive" : "You Should Pay")
                    .font(.title2)
                HStack {
                    Button {
                        routes.navigateBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.black)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            ScrollView (showsIndicators: false) {
                VStack {
                    SettlementCard(name: "Elian", amount: 250_000, type: .NeedConfirmation)
                    SettlementCard(name: "Elian", amount: 250_000, type: .NeedPayment)
                    SettlementCard(name: "Elian", amount: 250_000, type: .WaitingConfirmation)
                    SettlementCard(name: "Elian", amount: 250_000, type: .WaitingPayment)
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
            .scrollBounceBehavior(.basedOnSize, axes: [.vertical])
            Button {
                print("optimization result")
            } label: {
                Text("See optimization details")
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
