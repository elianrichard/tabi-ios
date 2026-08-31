//
//  EventSettlementView.swift
//  Tabi Split
//
//  Created by Elian Richard on 16/10/24.
//

import SwiftUI

struct EventSettlementView: View {
    @Environment(Router.self) private var router
    @Environment(EventViewModel.self) private var eventViewModel
    @Environment(EventSettlementViewModel.self) private var eventSettlementViewModel
    
    @State private var contentSize: CGSize = .zero
    @State private var isShowUploadSheet: Bool = false
    @State var receiptUploadViewModel = ReceiptUploadViewModel()
    
    var body: some View {
        VStack (spacing: 0) {
            TopNavigation(title: eventViewModel.userBalance.status == .credit ? "You Should Receive" : "You Should Pay")
            VStack (spacing: .spacingMedium) {
                ScrollView (showsIndicators: false) {
                    LazyVStack (spacing: .spacingTight) {
                        ForEach(eventViewModel.userSettlementList) { data in
                            SettlementCard(data: data, isShowUploadSheet: $isShowUploadSheet)
                        }
                    }
                    .background(
                        GeometryReader { geo in
                            Color.clear.onAppear {
                                contentSize = geo.size
                            }
                        }
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: contentSize.height)
                
                Button {
                    router.push(.settlementOptimization)
                } label: {
                    Text("See optimization details")
                        .font(.tabiHeadline)
                        .foregroundStyle(.textBlue)
                }
            }
            Spacer()
        }
        .padding()
        .sheet(isPresented: $isShowUploadSheet) {
            UploadSheet(receiptImage: $receiptUploadViewModel.receiptImageFromGallery, isShowSheet: $isShowUploadSheet, isShowScanner: $receiptUploadViewModel.toggleScannerSheet, user: eventSettlementViewModel.user) {
                Task {
                    if receiptUploadViewModel.receiptImageFromGallery != nil {
                        await receiptUploadViewModel.getImage()
                        eventSettlementViewModel.receiptImage = receiptUploadViewModel.receiptImage
                        router.push(.settlementUpload)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}


#Preview {
    EventSettlementView()
        .environment(Router())
        .environment(EventSettlementViewModel())
        .environment(EventViewModel())
}
