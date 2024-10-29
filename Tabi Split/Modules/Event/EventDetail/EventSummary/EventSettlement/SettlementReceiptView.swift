//
//  SettlementReceiptView.swift
//  Tabi Split
//
//  Created by Elian Richard on 17/10/24.
//

import SwiftUI

struct SettlementReceiptView: View {
    @Environment(Routes.self) private var routes
    @State var lastScaleValue: CGFloat = 1.0
    @State private var scale: CGFloat = 1.0
    var body: some View {
        ZStack {
            ZoomableScrollView {
                Image(.samplePaymentReceipt)
                    .resizable()
                    .scaledToFit()
            }
            .ignoresSafeArea()
            VStack {
                ZStack {
                    Text("Payment Receipt")
                        .font(.title2)
                    HStack {
                        Button {
                            routes.navigateBack()
                        } label: {
                            Image(systemName: "chevron.left")
                                .foregroundStyle(.black)
                                .frame(width: 40, height: 40)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer()
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    SettlementReceiptView()
        .environment(Routes())
}
