//
//  selectBankSheet.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 04/11/24.
//

import Foundation
import SwiftUI

struct SelectBankSheet: View {
    @Environment(ProfileViewModel.self) private var profileViewModel
    @Binding var viewModel: PaymentMethodViewModel
    
    var body: some View {
        NavigationView {
            VStack{
                SheetXButton(toggle: $viewModel.toggleSelectBank)
                VStack(alignment: .leading, spacing: 24){
                    Text("Select Bank or e-Wallet")
                        .font(.tabiTitle)
                    ScrollView{
                        VStack(alignment: .leading, spacing: .spacingTight){
                            Text("Popular")
                                .font(.tabiHeadline)
                            Divided {
                                ForEach(BankEnum.allCases) { bank in
                                    if bank.isPopular {
                                        NavigationLink(destination: BankDetailFormSheet(viewModel: $viewModel, selectedBank: bank)){
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
                                        .contentShape(Rectangle())
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding([.bottom], .spacingMedium)
                        VStack(alignment: .leading, spacing: .spacingTight){
                            Text("All payment methods")
                                .font(.tabiHeadline)
                            Divided {
                                ForEach(BankEnum.allCases) { bank in
                                    if !bank.isPopular {
                                        NavigationLink(destination: BankDetailFormSheet(viewModel: $viewModel, selectedBank: bank)){
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
                                        .contentShape(Rectangle())
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding()
            .padding([.top], 10)
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    SelectBankSheet(viewModel: .constant(PaymentMethodViewModel()))
        .environment(ProfileViewModel())
}
