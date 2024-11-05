//
//  BankDetailFormSheet.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 04/11/24.
//

import Foundation
import SwiftUI

struct BankDetailFormSheet: View {
    @Environment(ProfileViewModel.self) private var profileViewModel
    @Binding var viewModel: PaymentMethodViewModel
    @State var selectedBank: TemplatePaymentMethod
    @State var accountNumber: String = ""
    @State var accountName: String = ""
    
    var body: some View {
        VStack{
            SheetXButton(toggle: $viewModel.toggleSelectBank)
            VStack(alignment: .leading, spacing: .spacingMedium){
                Text("Add Payment Method")
                    .font(.tabiTitle)
                HStack{
                    Image(uiImage: selectedBank.logoImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 45, height: 45)
                        .padding()
                        .overlay {
                            RoundedRectangle(cornerRadius: .radiusSmall)
                                .fill(.clear)
                                .stroke(.bgGreyOverlay, lineWidth: 0.5)
                                .padding(0.5)
                        }
                    Text(selectedBank.name)
                        .font(.tabiHeadline)
                }
                VStack{
                    InputWithLabel(label: "Account number", placeholder: "Your account number", text: $accountNumber)
                    InputWithLabel(label: "Account owner's name", placeholder: "Your account name", text: $accountName)
                }
                Spacer()
                CustomButton(text: "Save", isEnabled: accountNumber != "" && accountName != "") {
                    profileViewModel.userPaymentMethods.append(PaymentMethod(name: accountName, bankName: selectedBank.name, bankNumber: accountNumber, logoImage: selectedBank.logoImage))
                    viewModel.toggleSelectBank.toggle()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding()
        .padding([.top], 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationBarBackButtonHidden(true)
    }
}


#Preview {
    BankDetailFormSheet(viewModel: .constant(PaymentMethodViewModel()), selectedBank: .bca)
        .environment(ProfileViewModel())
}
