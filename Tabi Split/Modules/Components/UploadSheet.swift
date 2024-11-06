//
//  UploadSheet.swift
//  Tabi Split
//
//  Created by Elian Richard on 06/11/24.
//

import SwiftUI
import PhotosUI

struct UploadSheet: View {
    @Binding var receiptImage: PhotosPickerItem?
    @Binding var isShowSheet: Bool
    @Binding var isShowScanner: Bool
    var callback: (() -> Void)?
    
    var body: some View {
        VStack {
            Text("Upload Payment")
                .font(.tabiTitle)
            HStack {
                CustomButton(text: "Camera") {
                    isShowSheet = false
                    isShowScanner = true
                }
                PhotosPicker(selection:  $receiptImage, matching: .images, photoLibrary: .shared()) {
                    CustomButton(text: "Library")
                }
                .onChange(of: receiptImage) {
                    if let callback = callback {
                        callback()
                    }
                    isShowSheet = false
                }
            }
        }
        .padding()
        .presentationDetents([.height(200)])
        .presentationDragIndicator(.visible)
    }
}
