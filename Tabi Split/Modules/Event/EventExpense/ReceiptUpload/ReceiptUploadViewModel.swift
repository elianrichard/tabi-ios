//
//  ReceiptUploadViewModel.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 15/10/24.
//

import Foundation
import SwiftUI
import PhotosUI
import Vision

@Observable
final class ReceiptUploadViewModel{
    var isShowingScanner: Bool = false
    var receiptImage: UIImage?
    var receiptImageFromGallery: PhotosPickerItem?
    var items: [Item] = []
    var additionalCharges: [AdditionalCharge] = []
    var words: [VNRecognizedTextObservation] = []
    var totalPrice: Float = 0
    
    enum ocrError: Error {
        case imageError
        case textRecognizerError
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
            let correctedImage = self.performPerspectiveCorrection(rectangle: rectangle, image: cgImage)
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
    
    private func performPerspectiveCorrection(rectangle: VNRectangleObservation, image: CGImage) -> UIImage? {
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
    
    func normalizeString(_ input: String) -> String {
        // Lowercase the string
        let lowercasedString = input.lowercased()
        
        // Remove whitespaces, punctuation, and symbols
        let filteredString = lowercasedString.unicodeScalars.filter {
            CharacterSet.letters.contains($0) || CharacterSet.decimalDigits.contains($0)
        }
        
        // Convert the filtered result back to a String
        return String(String.UnicodeScalarView(filteredString))
    }
    
    func stringToFloat(_ input: String) -> Float {
        // Replace commas used for thousand separators with an empty string
        let cleanedString = input.replacingOccurrences(of: "[.,]", with: "", options: .regularExpression)
        
        // Convert the cleaned string to Float
        return Float(cleanedString) ?? 0
    }
    
    func performOCROnImage(_ image: UIImage) throws {
        var itemsAndPrice: [[String]] = []
        var totalFound: Bool = false
        var subTotalFound: Bool = false
        var taxKeywords: [String] = ["tax", "ppn", "pb10", "prest10", "pajak", "taxes", "pb1"]
        var serviceKeywords: [String] = ["service", "charge"]
        
        guard let cgImage = image.cgImage else {
            throw ocrError.imageError
        }
        
        let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                print("No recognized text.")
                return
            }
            
            for observation in observations {
                self.words.append(observation)
            }
        }
        
        request.recognitionLevel = .accurate // You can also use .fast for faster but less accurate recognition
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try requestHandler.perform([request])
        } catch {
            throw ocrError.textRecognizerError
        }
        
        for word in words {
            if let topCandidate = word.topCandidates(1).first {
                let recognizedText = topCandidate.string
                let pattern = "^((Rp|rp|RP|Rp | rp | Rp )?\\d{1,3})((,|.)\\d{3})*$"
                let regex = try? NSRegularExpression(pattern: pattern)
                let range = NSRange(location: 0, length: recognizedText.utf16.count)
                if regex?.firstMatch(in: recognizedText, options: [], range: range) != nil {
                    if word.boundingBox.minX > 0.6 {
                        for word2 in words {
                            if (((word2.boundingBox.midY) <= word.boundingBox.maxY) && ((word2.boundingBox.midY) >= (word.boundingBox.minY))){
                                let recognizedText2 = word2.topCandidates(1).first?.string
                                if recognizedText2 != recognizedText {
                                    itemsAndPrice.append([recognizedText2 ?? "", normalizeString(recognizedText2 ?? ""), recognizedText])
                                }
                            }
                        }
                    }
                }
            }
        }
        
        for item in itemsAndPrice {
            let isItTax = taxKeywords.contains { additionalChargeKeywords in
                item[1].contains(additionalChargeKeywords)
            }
            if isItTax {
                if !item[1].contains("dasar") {
                    additionalCharges.append(AdditionalCharge(additionalChargeType: .tax, amount: stringToFloat(item[2])))
                    itemsAndPrice.remove(item)
                    continue
                }
            }
            
            let isItService = serviceKeywords.contains { serviceKeywords in
                item[1].contains(serviceKeywords)
            }
            if isItService {
                additionalCharges.append(AdditionalCharge(additionalChargeType: .serviceCharge, amount: stringToFloat(item[2])))
                itemsAndPrice.remove(item)
                continue
            }
            
            if (item[1].contains("total") && item[1] != "subtotal"){
                totalFound.toggle()
                totalPrice = stringToFloat(item[2])
                itemsAndPrice.remove(item)
                break
            }
            
            if !subTotalFound{
                if (item[1].contains("subtotal")){
                    subTotalFound.toggle()
                    continue
                }
                items.append(Item(itemName: item[0], itemPrice: stringToFloat(item[2]), itemQuantity: 1))
                itemsAndPrice.remove(item)
            }
        }
    }
}
