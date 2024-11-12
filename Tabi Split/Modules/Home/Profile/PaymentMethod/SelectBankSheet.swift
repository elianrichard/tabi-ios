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
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Binding var viewModel: PaymentMethodViewModel
    @Binding var selectedBank: BankEnum?
    
    var body: some View {
        VStack{
            SheetXButton(toggle: $viewModel.toggleDetailBankSheet)
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
                                    Button{
                                        selectedBank = bank
                                        presentationMode.wrappedValue.dismiss()
                                    } label: {
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
                                    Button{
                                        selectedBank = bank
                                        presentationMode.wrappedValue.dismiss()
                                    } label: {
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
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationBarBackButtonHidden(true)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding()
        .padding([.top], 10)
    }
}

#Preview {
    SelectBankSheet(viewModel: .constant(PaymentMethodViewModel()), selectedBank: .constant(.bca))
        .environment(ProfileViewModel())
}
