//
//  EventSettlementView.swift
//  Tabi Split
//
//  Created by Elian Richard on 16/10/24.
//

import SwiftUI

struct EventSettlementView: View {
    @Environment(Routes.self) private var routes
    @Environment(EventViewModel.self) private var eventViewModel
    @Environment(EventSettlementViewModel.self) private var eventSettlementViewModel
    
    @State private var contentSize: CGSize = .zero
    @State private var isShowUploadSheet: Bool = false
    @State var receiptUploadViewModel = ReceiptUploadViewModel()
    
    var body: some View {
        VStack (spacing: 24) {
            TopNavigation(title: eventViewModel.userBalance.status == .credit ? "You Should Receive" : "You Should Pay")
            ScrollView (showsIndicators: false) {
                VStack (spacing: .spacingTight) {
                    ForEach(eventViewModel.userSettlementList) { data in
                        SettlementCard(data: data, isShowUploadSheet: $isShowUploadSheet)
                    }
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
            UploadSheet(receiptImage: $receiptUploadViewModel.receiptImageFromGallery, isShowSheet: $isShowUploadSheet, isShowScanner: $receiptUploadViewModel.isShowingScanner, user: eventSettlementViewModel.user) {
                Task {
                    if receiptUploadViewModel.receiptImageFromGallery != nil {
                        await receiptUploadViewModel.getImage()
                        eventSettlementViewModel.receiptImage = receiptUploadViewModel.receiptImage
                        routes.navigate(to: .SettlementUploadView)
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
        .environment(EventViewModel())
}
