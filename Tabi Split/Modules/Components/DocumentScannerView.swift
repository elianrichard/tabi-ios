//
//  DocumentScannerView.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 15/10/24.
//

import SwiftUI
import WeScan

struct DocumentScannerView: UIViewControllerRepresentable {
    
    class Coordinator: NSObject, ImageScannerControllerDelegate {
        var parent: DocumentScannerView
        
        init(parent: DocumentScannerView) {
            self.parent = parent
        }
        
        func imageScannerController(_ scanner: ImageScannerController, didFinishScanningWithResults results: ImageScannerResults) {
            // Handle the results (scanned document)
            parent.onScanComplete(results.croppedScan.image)
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imageScannerControllerDidCancel(_ scanner: ImageScannerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imageScannerController(_ scanner: ImageScannerController, didFailWithError error: Error) {
            print("Scanning failed: \(error)")
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
    
    @Environment(\.presentationMode) var presentationMode
    var onScanComplete: (UIImage) -> Void
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> ImageScannerController {
        let scannerController = ImageScannerController()
        scannerController.imageScannerDelegate = context.coordinator
        return scannerController
    }
    
    func updateUIViewController(_ uiViewController: ImageScannerController, context: Context) {
        // Nothing to update here
    }
}
