//
//  AddExpenseViewModel.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 25/10/24.
//

import Foundation
import SwiftUI
import PhotosUI
import Vision

@Observable
class AddExpenseViewModel{
    var toggleSeeAll: Bool = false
    var settingsDetent = PresentationDetent.medium
    var toggleReceiptSheet: Bool = false
    var receiptSheetHeight: CGFloat = 0
    var toggleScannerSheet: Bool = false
    var receiptImage: UIImage?
    var receiptImageProcessed: UIImage?
    var receiptImageFromGallery: PhotosPickerItem?
    
    var eventExpenseViewModel: EventExpenseViewModel?
    var expenseNameError: String?
    var paidByError: String?
    var participantsError: String?
    var selectParticipantsError: String?
    var splitBillMethodError: String?
    var totalBillError: String?
    var isValid: Bool = true
    
    init(eventExpenseViewModel: EventExpenseViewModel?) {
        self.eventExpenseViewModel = eventExpenseViewModel
    }
    
    func validateInput() {
        isValid = true
        expenseNameError = nil
        paidByError = nil
        participantsError = nil
        selectParticipantsError = nil
        splitBillMethodError = nil
        
        if eventExpenseViewModel?.expenseName == "" {
            expenseNameError = "Please enter the expense name"
            isValid = false
        }
        
        if eventExpenseViewModel?.selectedCoverer == nil {
            paidByError = "Please select who paid for the bill"
            isValid = false
        }

        if eventExpenseViewModel?.selectedParticipants == [] {
            participantsError = "Please select the participants"
            isValid = false
        }
        
        if eventExpenseViewModel?.selectedMethod == nil {
            splitBillMethodError = "Please select the split bill method"
            isValid = false
        }
        
        if eventExpenseViewModel?.selectedMethod == .equally && (eventExpenseViewModel?.expenseTotalInput == 0 || eventExpenseViewModel?.expenseTotalInput == nil) {
            totalBillError = "Please enter the total bill amount"
            isValid = false
        }
    }
    
    func getImage() async{
        if let data = try? await receiptImageFromGallery?.loadTransferable(type: Data.self) {
            receiptImage = UIImage(data: data)
        }
    }
    
    func straightenDocument(in image: UIImage, completion: @escaping (UIImage?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        let request = VNDetectDocumentSegmentationRequest { request, error in
            if let error = error {
                print("Error detecting rectangles: \(error)")
                completion(nil)
                return
            }
            
            guard let results = request.results as? [VNRectangleObservation], let rectangle = results.first else {
                print("No rectangle found")
                completion(nil)
                return
            }
            
            // Perform perspective correction on the image
            var correctedImage = self.performPerspectiveCorrection(rectangle: rectangle, image: cgImage)
            correctedImage = correctedImage?.cgImage?.width ?? 0 > correctedImage?.cgImage?.height ?? 0 ? correctedImage?.rotate(radians: .pi/2) : correctedImage
            completion(correctedImage)
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                print("Failed to perform rectangle detection: \(error)")
                completion(nil)
            }
        }
    }
    
    func performPerspectiveCorrection(rectangle: VNRectangleObservation, image: CGImage) -> UIImage? {
        let ciImage = CIImage(cgImage: image)
        let size = CGSize(width: image.width, height: image.height)
        
        // Coordinates for the corners of the detected rectangle
        let topLeft = rectangle.topLeft.scaled(to: size)
        let topRight = rectangle.topRight.scaled(to: size)
        let bottomLeft = rectangle.bottomLeft.scaled(to: size)
        let bottomRight = rectangle.bottomRight.scaled(to: size)
        
        // Apply perspective correction
        let correctedImage = ciImage.applyingFilter("CIPerspectiveCorrection", parameters: [
            "inputTopLeft": CIVector(cgPoint: topLeft),
            "inputTopRight": CIVector(cgPoint: topRight),
            "inputBottomLeft": CIVector(cgPoint: bottomLeft),
            "inputBottomRight": CIVector(cgPoint: bottomRight)
        ])
        
        let context = CIContext()
        if let outputImage = context.createCGImage(correctedImage, from: correctedImage.extent) {
            return UIImage(cgImage: outputImage)
        }
        
        return nil
    }
}
