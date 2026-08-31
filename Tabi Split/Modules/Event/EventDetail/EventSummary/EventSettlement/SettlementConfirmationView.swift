//
//  SettlementConfirmationView.swift
//  Tabi Split
//
//  Created by Elian Richard on 17/10/24.
//

import SwiftUI
import PhotosUI

struct SettlementConfirmationView: View {
    @Environment(Router.self) private var router
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
                    router.push(.settlementReceipt)
                }
                Spacer()
                CustomButton(text: "Confirm") {
                    router.pop()
                }
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    SettlementConfirmationView()
        .environment(Router())
        .environment(EventSettlementViewModel())
}
