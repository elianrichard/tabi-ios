//
//  ReceiptUpload.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 15/10/24.
//

import Foundation
import SwiftUI
import PhotosUI

struct ReceiptUploadView: View {
    @State var receiptUploadViewModel = ReceiptUploadViewModel()
    @Environment(EventExpenseViewModel.self) private var eventExpenseViewModel
    @Environment(Routes.self) private var routes
    
    var body: some View {
        VStack{
            ZStack {
                Text("Upload Payment")
                    .font(.title2)
                HStack {
                    Button {
                        routes.navigateBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.black)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            PhotosPicker(selection: $receiptUploadViewModel.receiptImageFromGallery, matching: .images, photoLibrary: .shared()){
                VStack(spacing: 10){
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .foregroundColor(.gray)
                    Text("Upload an image")
                        .foregroundColor(.gray)
                }
                .opacity(receiptUploadViewModel.receiptImage != nil ? 0 : 1)
                .frame(height: 250)
                .frame(maxWidth: .infinity)
            }
            .onChange(of: receiptUploadViewModel.receiptImageFromGallery) {
                Task{
                    if receiptUploadViewModel.receiptImageFromGallery != nil {
                        await receiptUploadViewModel.getImage()
                        receiptUploadViewModel.straightenDocument(in: receiptUploadViewModel.receiptImage ?? UIImage()) { image in
                            receiptUploadViewModel.receiptImage = image
                        }
                    }
                }
            }
            .foregroundColor(.gray)
            .background{
                if receiptUploadViewModel.receiptImage != nil{
                    Image(uiImage: receiptUploadViewModel.receiptImage ?? UIImage())
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color(.uiGray)
                }
            }
            .cornerRadius(20)
            
            DividerWithText()
                .padding()
            
            CustomButton (text: "Take Photo", type: .secondary, hPadding: 40) {
                receiptUploadViewModel.isShowingScanner.toggle()
            }
            
            Spacer()

            CustomButton(text: "Upload", isEnabled: receiptUploadViewModel.receiptImage != nil) {
                do {
                    try eventExpenseViewModel.performOCROnImage(receiptUploadViewModel.receiptImage ?? UIImage())
                } catch {
                    print(error)
                }

                eventExpenseViewModel.uploadedReceiptImage = receiptUploadViewModel.receiptImage

                routes.navigateBack()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationBarBackButtonHidden(true)
        .padding()
        .sheet(isPresented: Bindable(receiptUploadViewModel).isShowingScanner) {
            DocumentScannerView { image in
                receiptUploadViewModel.receiptImageFromGallery = nil
                receiptUploadViewModel.receiptImage = image
            }
        }
    }
}

#Preview {
    ReceiptUploadView()
        .environment(Routes())
        .environment(EventExpenseViewModel())
}
