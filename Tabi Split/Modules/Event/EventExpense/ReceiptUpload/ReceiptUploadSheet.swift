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
                        guard receiptUploadViewModel.receiptImageFromGallery != nil else { return }
                        receiptUploadViewModel.isLoading = true
                        Task{
                            // Load the picked image and set the PROCESSED image
                            // directly. Do not touch `receiptImage` (camera-only) —
                            // that would double-fire and re-present the sheet.
                            // Orientation baked to .up so it doesn't upload rotated.
                            let image = await receiptUploadViewModel.getImage()
                            receiptUploadViewModel.receiptImageProcessed = image?.normalizedUp()
                            receiptUploadViewModel.isLoading = false
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
            // VisionKit scanner: live edge detection + draggable corner dots +
            // perspective crop. Its output is already cropped/straightened.
            DocumentScannerView(
                scannedImage: $receiptUploadViewModel.receiptImage,
                isPresented: Bindable(receiptUploadViewModel).toggleScannerSheet
            )
            .ignoresSafeArea()
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
        // Observe the scanned image on the PARENT (not inside the cover) so it fires
        // after the scanner dismisses. The gallery path already sets
        // receiptImageProcessed directly; the camera path lands here.
        .onChange(of: receiptUploadViewModel.receiptImage) {
            guard let image = receiptUploadViewModel.receiptImage else { return }
            print("[ReceiptUpload] scanner returned image \(Int(image.size.width))x\(Int(image.size.height))")
            receiptUploadViewModel.receiptImageProcessed = image
        }
        .onChange(of: receiptUploadViewModel.receiptImageProcessed){
            print("[ReceiptUpload] processed image set — attaching + dismissing sheet")
            eventExpenseViewModel.attachReceiptImage(receiptUploadViewModel.receiptImageProcessed)
            isPresented.toggle()
        }
    }
}

#Preview {
    ReceiptUploadSheet(height: .constant(0), isPresented: .constant(true))
        .environment(Router())
        .environment(EventExpenseViewModel())
}
