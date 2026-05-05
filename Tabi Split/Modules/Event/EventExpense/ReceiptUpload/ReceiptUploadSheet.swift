//
//  ReceiptUpload.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 15/10/24.
//

import Foundation
import SwiftUI
import PhotosUI

struct ReceiptUploadSheet: View {
    @State var receiptUploadViewModel = ReceiptUploadViewModel()
    @Environment(EventExpenseViewModel.self) private var eventExpenseViewModel
    @Environment(Router.self) private var router
    @Binding var height: CGFloat
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0){
            SheetXButton(toggle: $isPresented)
            VStack(spacing: .spacingMedium){
                Text(!eventExpenseViewModel.isQuickScanned ? "Upload Image" : "Quick Scan with OCR")
                    .font(.tabiTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: .spacingTight){
                    PhotosPicker(selection: $receiptUploadViewModel.receiptImageFromGallery, matching: .images, photoLibrary: .shared()){
                        VStack(spacing: .spacingTight){
                            Icon(systemName: "photo", color: .buttonBlue, size: 20)
                            Text("Open Library")
                                .font(.tabiHeadline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                    }
                    .accentColor(.buttonBlue)
                    .overlay {
                        RoundedRectangle(cornerRadius: .radiusLarge)
                            .fill(.clear)
                            .stroke(.buttonBlue, lineWidth: 1.5)
                    }
                    .onChange(of: receiptUploadViewModel.receiptImageFromGallery) {
                        receiptUploadViewModel.isLoading = true
                        Task{
                            if receiptUploadViewModel.receiptImageFromGallery != nil {
                                await receiptUploadViewModel.getImage()
                                receiptUploadViewModel.straightenDocument(in: receiptUploadViewModel.receiptImage ?? UIImage()) { image in
                                    receiptUploadViewModel.receiptImageProcessed = image
                                    receiptUploadViewModel.isLoading = false
                                }
                            }
                        }
                    }
                    Button{
                        receiptUploadViewModel.toggleScannerSheet.toggle()
                    }label:{
                        VStack(spacing: .spacingTight){
                            Icon(systemName: "camera.fill", color: .buttonBlue, size: 20)
                            Text("Take Photo")
                                .font(.tabiHeadline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                    }
                    .accentColor(.buttonBlue)
                    .overlay {
                        RoundedRectangle(cornerRadius: .radiusLarge)
                            .fill(.clear)
                            .stroke(.buttonBlue, lineWidth: 1.5)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .navigationBarBackButtonHidden(true)
        .padding()
        .padding([.top], 10)
        .fullScreenCover(isPresented: Bindable(receiptUploadViewModel).toggleScannerSheet) {
            CameraView(capturedImage: $receiptUploadViewModel.receiptImage, toggleClose: Bindable(receiptUploadViewModel).toggleScannerSheet)
                .onChange(of: receiptUploadViewModel.receiptImage) {
                    receiptUploadViewModel.straightenDocument(in: receiptUploadViewModel.receiptImage ?? UIImage()) { image in
                        receiptUploadViewModel.receiptImageProcessed = image
                        receiptUploadViewModel.isLoading = false
                    }
                }
                .background(.black)
                .background(ignoresSafeAreaEdges: .all)
        }
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        height = geometry.size.height
                    }
            }
        )
        .background(.bgWhite)
        .onChange(of: receiptUploadViewModel.receiptImageProcessed){
            eventExpenseViewModel.uploadedReceiptImage = receiptUploadViewModel.receiptImageProcessed ?? UIImage()
            isPresented.toggle()
        }
    }
}

#Preview {
    ReceiptUploadSheet(height: .constant(0), isPresented: .constant(true))
        .environment(Router())
        .environment(EventExpenseViewModel())
}
