//
//  SettlementPaymentMethodView.swift
//  Tabi Split
//
//  Created by Elian Richard on 16/10/24.
//

import SwiftUI

struct SettlementPaymentMethodView: View {
    @Environment(Routes.self) private var routes
    @State var settlementPaymentMethodViewModel = SettlementPaymentMethodViewModel()
    
    var body: some View {
        VStack (spacing: 24) {
            ZStack {
                Text("\(settlementPaymentMethodViewModel.personName)'s Payment Methods")
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
            ScrollView {
                VStack (spacing: 24) {
                    if settlementPaymentMethodViewModel.isHasFavorite {
                        VStack (alignment: .leading, spacing: 0) {
                            Text("Favourite")
                                .font(.title2)
                                .fontWeight(.medium)
                            VStack {
                                ForEach(Array(settlementPaymentMethodViewModel.favoritePaymentMethods.enumerated()), id: \.offset) { index, payment in
                                    PaymentMethodCard(payment: payment, isLast: index == settlementPaymentMethodViewModel.favoritePaymentMethods.count - 1)
                                }
                            }
                        }
                    }
                    
                    VStack (alignment: .leading, spacing: 0) {
                        if settlementPaymentMethodViewModel.isHasFavorite {
                            Text("Other")
                                .font(.title2)
                                .fontWeight(.medium)
                        }
                        VStack {
                            ForEach(Array(settlementPaymentMethodViewModel.otherPaymentMethods.enumerated()), id: \.offset) { index, payment in
                                PaymentMethodCard(payment: payment, isLast: index == settlementPaymentMethodViewModel.otherPaymentMethods.count - 1)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    SettlementPaymentMethodView()
        .environment(Routes())
}
