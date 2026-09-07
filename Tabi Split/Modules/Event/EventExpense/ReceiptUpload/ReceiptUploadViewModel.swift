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

    func getImage() async{
        if let data = try? await receiptImageFromGallery?.loadTransferable(type: Data.self) {
            receiptImage = UIImage(data: data)
        }
    }
}
