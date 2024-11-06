//
//  EventSettlementView.swift
//  Tabi Split
//
//  Created by Elian Richard on 16/10/24.
//

import SwiftUI

struct EventSettlementView: View {
    @Environment(Routes.self) private var routes
    @Environment(EventSettlementViewModel.self) private var eventSettlementViewModel
    
    var balance: Float = 200_000
    
    @State private var contentSize: CGSize = .zero
    @State private var isShowUploadSheet: Bool = false
    @State var receiptUploadViewModel = ReceiptUploadViewModel()
    
    var body: some View {
        VStack (spacing: 24) {
            TopNavigation(title: balance > 0 ? "You Should Receive" : "You Should Pay")
            ScrollView (showsIndicators: false) {
                VStack (spacing: .spacingTight) {
                    SettlementCard(user: UserData(name: "Elian", phone: "phone"), amount: 250_000, type: .NeedConfirmation, isShowUploadSheet: $isShowUploadSheet)
                    SettlementCard(user: UserData(name: "Elian", phone: "phone"), amount: 250_000, type: .NeedPayment, isShowUploadSheet: $isShowUploadSheet)
                    SettlementCard(user: UserData(name: "Elian", phone: "phone"), amount: 250_000, type: .WaitingConfirmation, isShowUploadSheet: $isShowUploadSheet)
                    SettlementCard(user: UserData(name: "Elian", phone: "phone"), amount: 250_000, type: .WaitingPayment, isShowUploadSheet: $isShowUploadSheet)
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
        .sheet(isPresented: $isShowUploadSheet) {
            UploadSheet(receiptImage: $receiptUploadViewModel.receiptImageFromGallery, isShowSheet: $isShowUploadSheet, isShowScanner: $receiptUploadViewModel.isShowingScanner) {
                Task {
                    if receiptUploadViewModel.receiptImageFromGallery != nil {
                        await receiptUploadViewModel.getImage()
                        eventSettlementViewModel.receiptImage = receiptUploadViewModel.receiptImage
                        routes.navigate(to: .SettlementConfirmationView)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}


#Preview {
    EventSettlementView()
        .environment(Routes())
        .environment(EventSettlementViewModel())
}
