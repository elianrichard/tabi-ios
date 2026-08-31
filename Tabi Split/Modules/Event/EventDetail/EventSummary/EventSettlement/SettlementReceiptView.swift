//
//  SettlementReceiptView.swift
//  Tabi Split
//
//  Created by Elian Richard on 17/10/24.
//

import SwiftUI

struct SettlementReceiptView: View {
    @Environment(Router.self) private var router
    @Environment(EventSettlementViewModel.self) private var eventSettlementViewModel
    
    @State var lastScaleValue: CGFloat = 1.0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            if let image = eventSettlementViewModel.receiptImage {
                ZoomableScrollView {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                }
                .ignoresSafeArea()
            }
            VStack {
                TopNavigation(title: "Payment Receipt")
                Spacer()
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    SettlementReceiptView()
        .environment(Router())
        .environment(EventSettlementViewModel())
}
