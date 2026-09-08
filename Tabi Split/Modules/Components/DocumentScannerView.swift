//
//  DocumentScannerView.swift
//  Tabi Split
//
//  Wraps VisionKit's VNDocumentCameraViewController — Apple's built-in document
//  scanner. Provides live edge detection, draggable corner dots to adjust the
//  crop (CamScanner-style), and automatic perspective correction. The image it
//  returns is already cropped/straightened, so no manual straightening is needed.
//

import SwiftUI
import VisionKit

struct DocumentScannerView: UIViewControllerRepresentable {
    /// Receives the first scanned, cropped page. Nil is never written here.
    @Binding var scannedImage: UIImage?
    /// Toggled to false to dismiss the scanner (on finish or cancel).
    @Binding var isPresented: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerView

        init(parent: DocumentScannerView) {
            self.parent = parent
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            // Single-receipt flow: VisionKit allows multiple pages, but we only ever
            // use the FIRST — a receipt is one image. Extra pages are ignored.
            print("[DocumentScanner] didFinish — \(scan.pageCount) page(s); using page 0")
            if scan.pageCount > 0 {
                let image = scan.imageOfPage(at: 0)
                print("[DocumentScanner] page 0 = \(Int(image.size.width))x\(Int(image.size.height))")
                parent.scannedImage = image
            } else {
                print("[DocumentScanner] no pages in scan")
            }
            parent.isPresented = false
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            print("[DocumentScanner] cancelled")
            parent.isPresented = false
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("[DocumentScanner] failed: \(error)")
            parent.isPresented = false
        }
    }
}
