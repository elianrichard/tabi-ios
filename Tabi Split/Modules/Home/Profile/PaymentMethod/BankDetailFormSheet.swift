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
    @State var selectedBank: BankEnum?
    @State var accountNumber: String = ""
    @State var accountName: String = ""
    @State var isEditing: Bool = false
    
    var body: some View {
        NavigationView{
            VStack{
                SheetXButton(toggle: $viewModel.toggleDetailBankSheet)
                VStack(alignment: .leading, spacing: .spacingMedium){
                    if viewModel.idToBeEdited != nil {
                        Text("Edit Payment Method")
                            .font(.tabiTitle)
                    }else{
                        Text("Add Payment Method")
                            .font(.tabiTitle)
                    }
                    if let bank = selectedBank {
                        NavigationLink(destination: SelectBankSheet(viewModel: $viewModel, selectedBank: $selectedBank)){
                            HStack{
                                Image(uiImage: bank.bankLogo)
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
                                Text(bank.bankName)
                                    .font(.tabiHeadline)
                            }
                        }
                        .accentColor(.textBlack)
                    }else{
                        NavigationLink(destination: SelectBankSheet(viewModel: $viewModel, selectedBank: $selectedBank)){
                            HStack{
                                Icon(systemName: "wallet.bifold.fill", color: .buttonBlue, size: 35)
                                    .frame(width: 45, height: 45)
                                    .padding()
                                    .overlay {
                                        RoundedRectangle(cornerRadius: .radiusSmall)
                                            .fill(.clear)
                                            .stroke(.bgGreyOverlay, lineWidth: 0.5)
                                            .padding(0.5)
                                    }
                                Text("Select Bank or e-Wallet")
                                    .font(.tabiHeadline)
                                    .foregroundColor(.buttonBlue)
                            }
                        }
                    }
                    VStack{
                        InputWithLabel(label: "Account number", placeholder: "Your account number", text: $accountNumber)
                        InputWithLabel(label: "Account owner's name", placeholder: "Your account name", text: $accountName)
                    }
                    .onAppear{
                        if isEditing {
                            accountName = profileViewModel.userPaymentMethods.first(where: { $0.id == viewModel.idToBeEdited })?.name ?? ""
                            accountNumber = profileViewModel.userPaymentMethods.first(where: { $0.id == viewModel.idToBeEdited })?.bankNumber ?? ""
                        }
                    }
                    Spacer()
                    if isEditing {
                        CustomButton(text: "Delete Payment Method"){
                            profileViewModel.userPaymentMethods.removeAll(where: { $0.id == viewModel.idToBeEdited })
                            viewModel.idToBeEdited = nil
                            viewModel.toggleDetailBankSheet.toggle()
                        }
                    }
                    CustomButton(text: "Save", isEnabled: accountNumber != "" && accountName != "" && selectedBank != nil) {
                        if isEditing {
                            if let index = profileViewModel.userPaymentMethods.firstIndex(where: {$0.id == viewModel.idToBeEdited}) {
                                profileViewModel.userPaymentMethods[index].name = accountName
                                profileViewModel.userPaymentMethods[index].bankNumber = accountNumber
                                if let bank = selectedBank{
                                    profileViewModel.userPaymentMethods[index].bank = bank
                                }
                            }
                            viewModel.idToBeEdited = nil
                            viewModel.toggleDetailBankSheet.toggle()
                        }else{
                            if let bank = selectedBank{
                                profileViewModel.userPaymentMethods.append(PaymentMethod(name: accountName, bank: bank, bankNumber: accountNumber))
                                viewModel.toggleDetailBankSheet.toggle()
                            }
                        }
                    }
                }
                .onAppear{
                    if let index = profileViewModel.userPaymentMethods.firstIndex(where: {$0.id == viewModel.idToBeEdited}) {
                        selectedBank = profileViewModel.userPaymentMethods[index].bank
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
}


#Preview {
    BankDetailFormSheet(viewModel: .constant(PaymentMethodViewModel()), selectedBank: .bca)
        .environment(ProfileViewModel())
}
