//
//  SettlementConfirmationView.swift
//  Tabi Split
//
//  Created by Elian Richard on 17/10/24.
//

import SwiftUI
import PhotosUI

struct SettlementConfirmationView: View {
    @Environment(Routes.self) private var routes
    @Environment(EventSettlementViewModel.self) private var eventSettlementViewModel
    
    @State var receiptUploadViewModel = ReceiptUploadViewModel()
    
    var body: some View {
        VStack (spacing: 0) {
            TopNavigation(title: "Confirm Payment")
            VStack (alignment: .leading, spacing: .spacingTight) {
                UserAvatar(userData: eventSettlementViewModel.user, namePosition: .right)
                VStack (alignment: .center, spacing: .spacingLarge) {
                    if let image = eventSettlementViewModel.receiptImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: 300, maxHeight: 380, alignment: .center)
                            .background(.uiWhite)
                            .clipShape(RoundedRectangle(cornerRadius: .radiusLarge))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .onTapGesture {
                    routes.navigate(to: .SettlementReceiptView)
                }
                Spacer()
                CustomButton(text: "Confirm") {
                    routes.navigateBack()
                }
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    SettlementConfirmationView()
        .environment(Routes())
        .environment(EventSettlementViewModel())
}
