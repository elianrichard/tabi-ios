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

    // The scan action the user chose; deferred until the disclaimer is confirmed.
    private enum ScanAction { case library, camera }
    @State private var showDisclaimer: Bool = false
    @State private var pendingAction: ScanAction?
    @State private var openLibrary: Bool = false

    var body: some View {
        VStack(spacing: 0){
            SheetXButton(toggle: $isPresented)
            VStack(spacing: .spacingMedium){
                Text(!eventExpenseViewModel.isQuickScanned ? "Upload Image" : "Quick Scan with OCR")
                    .font(.tabiTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: .spacingTight){
                    Button {
                        requestScan(.library)
                    } label: {
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
                    // Programmatic picker so the disclaimer can gate it.
                    .photosPicker(isPresented: $openLibrary, selection: $receiptUploadViewModel.receiptImageFromGallery, matching: .images, photoLibrary: .shared())
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
                        requestScan(.camera)
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
        .sheet(isPresented: $showDisclaimer) {
            ReceiptScanDisclaimerSheet(isPresented: $showDisclaimer) {
                proceedWithPendingAction()
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
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

    /// Show the disclaimer first (unless the user opted out); otherwise proceed
    /// straight to the chosen picker.
    private func requestScan(_ action: ScanAction) {
        pendingAction = action
        if UserDefaultsService.shared.getReceiptScanDisclaimerDismissed() {
            proceedWithPendingAction()
        } else {
            showDisclaimer = true
        }
    }

    /// Opens the library or the camera scanner for the deferred action.
    private func proceedWithPendingAction() {
        switch pendingAction {
        case .library:
            openLibrary = true
        case .camera:
            receiptUploadViewModel.toggleScannerSheet = true
        case .none:
            break
        }
        pendingAction = nil
    }
}

#Preview {
    ReceiptUploadSheet(height: .constant(0), isPresented: .constant(true))
        .environment(Router())
        .environment(EventExpenseViewModel())
}
