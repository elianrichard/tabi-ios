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
        VStack (spacing: 0) {
            TopNavigation(title: "\(settlementPaymentMethodViewModel.user.name)'s Payment Methods")
                .padding([.top, .horizontal])
            ScrollView {
                VStack (spacing: .spacingMedium) {
                    if settlementPaymentMethodViewModel.isHasFavorite {
                        VStack (alignment: .leading, spacing: 0) {
                            Text("Favorite")
                                .font(.tabiHeadline)
                            VStack (spacing: 0) {
                                ForEach(Array(settlementPaymentMethodViewModel.favoritePaymentMethods.enumerated()), id: \.offset) { index, payment in
                                    PaymentMethodCard(payment: payment, isLast: index == settlementPaymentMethodViewModel.favoritePaymentMethods.count - 1)
                                }
                            }
                        }
                    }
                    
                    VStack (alignment: .leading, spacing: 0) {
                        if settlementPaymentMethodViewModel.isHasFavorite {
                            Text("Others")
                                .font(.tabiHeadline)
                        }
                        VStack (spacing: 0) {
                            ForEach(Array(settlementPaymentMethodViewModel.otherPaymentMethods.enumerated()), id: \.offset) { index, payment in
                                PaymentMethodCard(payment: payment, isLast: index == settlementPaymentMethodViewModel.otherPaymentMethods.count - 1)
                            }
                        }
                    }
                }
                .padding([.bottom, .horizontal])
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    SettlementPaymentMethodView()
        .environment(Routes())
}
