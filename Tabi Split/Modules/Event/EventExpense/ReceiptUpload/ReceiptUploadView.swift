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
//    @Environment(ReceiptUploadViewModel.self) private var receiptViewModel
    @State var viewModel = ReceiptUploadViewModel()
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
            PhotosPicker(selection: $viewModel.receiptImageFromGallery, matching: .images, photoLibrary: .shared()){
                VStack(spacing: 10){
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .foregroundColor(.gray)
                    Text("Upload an image")
                        .foregroundColor(.gray)
                }
                .opacity(viewModel.receiptImage != nil ? 0 : 1)
                .frame(height: 250)
                .frame(maxWidth: .infinity)
            }
            .onChange(of: viewModel.receiptImageFromGallery) {
                Task{
                    await viewModel.getImage()
                    viewModel.straightenDocument(in: viewModel.receiptImage!) { image in
                        viewModel.receiptImage = image
                    }
                }
            }
            .foregroundColor(.gray)
            .background{
                if viewModel.receiptImage != nil{
                    Image(uiImage: viewModel.receiptImage!)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }else{
                    Color(.midLightGray)
                }
            }
            .cornerRadius(20)
            
            DividerWithText()
                .padding()
            
            Button{
                viewModel.isShowingScanner.toggle()
            }label: {
                Text("Take Photo")
            }
            .padding([.leading, .trailing], 40)
            .padding([.top, .bottom], 10)
            .overlay(
                RoundedRectangle(cornerRadius: 100)
                    .stroke(Color(.buttonBlue), lineWidth: 1)
            )
            
            Spacer()
            
            BottomButton(text: "Upload", color: viewModel.receiptImage != nil ? Color(.buttonBlue) : Color(.midLightGray))
                .onTapGesture {
                    do {
                        try viewModel.performOCROnImage(viewModel.receiptImage ?? UIImage())
                    } catch {
                        print(error)
                    }
                }
                .disabled(viewModel.receiptImage == nil)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationBarBackButtonHidden(true)
        .padding()
        .sheet(isPresented: $viewModel.isShowingScanner) {
            DocumentScannerView { image in
                viewModel.receiptImage = image
            }
        }
    }
}

#Preview {
    ReceiptUploadView()
        .environment(Routes())
//        .environment(EventViewModel())
//        .environment(EventExpenseViewModel())
}
