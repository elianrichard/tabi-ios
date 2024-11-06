//
//  SettlementConfirmationView.swift
//  Tabi Split
//
//  Created by Elian Richard on 17/10/24.
//

import SwiftUI
import PhotosUI

struct SettlementConfirmationView: View {
    @Environment(Routes.self) private var routes
    @Environment(EventSettlementViewModel.self) private var eventSettlementViewModel
    
    @State var receiptUploadViewModel = ReceiptUploadViewModel()
    @State var isShowUploadSheet = false
    
    var body: some View {
        VStack (spacing: .spacingMedium) {
            TopNavigation(title: eventSettlementViewModel.selectedSettlementType == .NeedPayment ? "Upload Payment" : "Confirm Payment")
            VStack (alignment: .leading, spacing: .spacingTight) {
                UserAvatar(userData: eventSettlementViewModel.user, namePosition: .right)
                VStack (alignment: .center, spacing: .spacingLarge) {
                    if let image = eventSettlementViewModel.receiptImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: 300, maxHeight: 380, alignment: .center)
                            .background(.uiWhite)
                            .clipShape(RoundedRectangle(cornerRadius: .radiusLarge))
                    }
                    
                    if eventSettlementViewModel.selectedSettlementType == .NeedPayment {
                        CustomButton(text: "Change Image", type: .secondary, vPadding: .spacingTight, hPadding: .spacingLarge) {
                            isShowUploadSheet = true
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .onTapGesture {
                    routes.navigate(to: .SettlementReceiptView)
                }
                Spacer()
                CustomButton(text: eventSettlementViewModel.selectedSettlementType == .NeedPayment ? "Upload" : "Confirm",
                             isEnabled: (eventSettlementViewModel.selectedSettlementType == .NeedPayment && eventSettlementViewModel.receiptImage != nil) || eventSettlementViewModel.selectedSettlementType == .NeedConfirmation) {
                    routes.navigateBack()
                }
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: Bindable(receiptUploadViewModel).isShowingScanner) {
            DocumentScannerView { image in
                receiptUploadViewModel.receiptImageFromGallery = nil
                receiptUploadViewModel.receiptImage = image
            }
        }
        .sheet(isPresented: $isShowUploadSheet) {
            UploadSheet(receiptImage: $receiptUploadViewModel.receiptImageFromGallery, isShowSheet: $isShowUploadSheet, isShowScanner: $receiptUploadViewModel.isShowingScanner) {
                Task {
                    if receiptUploadViewModel.receiptImageFromGallery != nil {
                        await receiptUploadViewModel.getImage()
                        eventSettlementViewModel.receiptImage = receiptUploadViewModel.receiptImage
                    }
                }
            }
        }
    }
}

#Preview {
    SettlementConfirmationView()
        .environment(Routes())
        .environment(EventSettlementViewModel())
}
