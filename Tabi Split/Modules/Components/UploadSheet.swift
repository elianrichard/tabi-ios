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
    var user: UserData
    var callback: (() -> Void)?
    
    var body: some View {
        VStack (spacing: 0) {
            SheetXButton(toggle: $isShowSheet)
            VStack (alignment: .leading, spacing: .spacingLarge) {
                Text("Upload Payment Receipt")
                    .font(.tabiTitle)
                VStack (alignment: .leading, spacing: .spacingTight) {
                    UserAvatar(userData: user, namePosition: .right)
                    VStack (spacing: .spacingMedium) {
                        PhotosPicker(selection:  $receiptImage, matching: .images, photoLibrary: .shared()) {
                            VStack {
                                Icon(systemName: "photo", color: .buttonBlue)
                                Text("Upload an image")
                                    .font(.tabiBody)
                                    .foregroundStyle(.buttonBlue)
                            }
                            .frame(maxWidth: .infinity, maxHeight: 230)
                            .background(.bgWhite)
                            .clipShape(RoundedRectangle(cornerRadius: .radiusLarge))
                        }
                        .onChange(of: receiptImage) {
                            if let callback = callback {
                                callback()
                            }
                            isShowSheet = false
                        }
                        DividerWithText(text: "Or")
                        CustomButton(text: "Take Photo", type: .secondary, icon: "camera.fill", vPadding: .spacingTight, hPadding: .spacingLarge) {
                            isShowSheet = false
                            isShowScanner = true
                        }
                    }
                }
            }
            Spacer()
        }
        .padding()
        .presentationDetents([.height(550)])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    UploadSheet(receiptImage: .constant(.none), isShowSheet: .constant(false), isShowScanner: .constant(false), user: UserData(name: "Elian", phone: "phone"))
}
