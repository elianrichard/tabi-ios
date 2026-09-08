//
//  ReceiptUploadViewModel.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 15/10/24.
//

import Foundation
import SwiftUI
import PhotosUI

@Observable
final class ReceiptUploadViewModel{
    var toggleScannerSheet: Bool = false
    var receiptImage: UIImage?
    var receiptImageFromGallery: PhotosPickerItem?
    var receiptImageProcessed: UIImage?
    var isLoading: Bool = false

    /// Loads the picked gallery image and RETURNS it. It intentionally does not
    /// write `receiptImage` — that property is watched by the camera-scanner
    /// observer, and writing it from the gallery path would fire that observer too,
    /// setting `receiptImageProcessed` twice and re-presenting the sheet.
    func getImage() async -> UIImage? {
        if let data = try? await receiptImageFromGallery?.loadTransferable(type: Data.self) {
            return UIImage(data: data)
        }
        return nil
    }
}
