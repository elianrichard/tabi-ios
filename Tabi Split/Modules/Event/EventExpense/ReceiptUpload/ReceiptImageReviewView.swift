//
//  ReceiptImageReviewView.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 13/11/24.
//

import Foundation
import SwiftUI

struct ReceiptImageReviewView: View {
    @Environment(EventExpenseViewModel.self) private var eventExpenseViewModel
    @Environment(Routes.self) private var routes
    @State var receiptSheetHeight: CGFloat = 0
    @State var toggleReceiptSheet: Bool = false
    @State var isUploaded: Bool = false
    
    var body: some View {
        VStack{
            TopNavigation(title: "Image Review")
            VStack{
                if let image = eventExpenseViewModel.uploadedReceiptImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: .radiusLarge))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            HStack{
                CustomButton(text: "Change Image", type: .secondary){
                    toggleReceiptSheet.toggle()
                }
                CustomButton(text: "Upload"){
                    if (eventExpenseViewModel.uploadedReceiptImage != nil) {
                        do {
                            try eventExpenseViewModel.performOCROnImage(eventExpenseViewModel.uploadedReceiptImage ?? UIImage())
                        } catch {
                            print(error)
                        }
                        
                        isUploaded.toggle()
                        routes.navigateBack()
                    }
                }
            }
        }
        .padding()
        .navigationBarBackButtonHidden()
        .onDisappear{
            if !isUploaded {
                eventExpenseViewModel.uploadedReceiptImage = nil
            }
        }
        .sheet(isPresented: $toggleReceiptSheet){
            ReceiptUploadSheet(height: $receiptSheetHeight, isPresented: $toggleReceiptSheet)
                .presentationDetents([.height(receiptSheetHeight)])
        }
    }
}

#Preview {
    ReceiptImageReviewView()
        .environment(EventExpenseViewModel())
        .environment(Routes())
}
