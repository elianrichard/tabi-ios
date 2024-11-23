//
//  SettlementUploadView.swift
//  Tabi Split
//
//  Created by Elian Richard on 06/11/24.
//

import SwiftUI
import PhotosUI

struct SettlementUploadView: View {
    @Environment(Routes.self) private var routes
    @Environment(EventSettlementViewModel.self) private var eventSettlementViewModel
    
    @State var receiptUploadViewModel = ReceiptUploadViewModel()
    @State var isShowUploadSheet = false
    
    var body: some View {
        VStack (spacing: 0) {
            TopNavigation(title: "Review Payment Receipt")
            VStack (alignment: .leading, spacing: .spacingTight) {
                VStack (alignment: .center, spacing: .spacingLarge) {
                    HStack (spacing: .spacingTight) {
                        Icon(systemName: "exclamationmark.triangle.fill", color: .buttonBlue, size: 20)
                        Text("Make sure the nominal and destination of your transfer to \(eventSettlementViewModel.user.name)")
                            .font(.tabiBody)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, .spacingTight)
                    .padding(.horizontal, .spacingSmall)
                    .background(.bgWhite)
                    .clipShape(RoundedRectangle(cornerRadius: .radiusMedium))
                    
                    if let image = eventSettlementViewModel.receiptImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: 300, maxHeight: 380, alignment: .center)
                            .background(.uiWhite)
                            .clipShape(RoundedRectangle(cornerRadius: .radiusLarge))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .onTapGesture {
                    routes.navigate(to: .SettlementReceiptView)
                }
                Spacer()
                HStack {
                    CustomButton(text: "Change Image", type: .secondary) {
                        isShowUploadSheet = true
                    }
                    CustomButton(text: "Upload",
                                 isEnabled: eventSettlementViewModel.receiptImage != nil) {
                        routes.navigateBack()
                    }
                }
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $receiptUploadViewModel.toggleScannerSheet) {
            CameraView(capturedImage: $receiptUploadViewModel.receiptImage, toggleClose: Bindable(receiptUploadViewModel).toggleScannerSheet)
        }
        .sheet(isPresented: $isShowUploadSheet) {
            UploadSheet(receiptImage: $receiptUploadViewModel.receiptImageFromGallery, isShowSheet: $isShowUploadSheet, isShowScanner: $receiptUploadViewModel.toggleScannerSheet, user: eventSettlementViewModel.user) {
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
    SettlementUploadView()
        .environment(Routes())
        .environment(EventSettlementViewModel())
}
