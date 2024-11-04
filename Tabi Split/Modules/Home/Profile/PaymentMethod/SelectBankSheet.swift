//
//  selectBankSheet.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 04/11/24.
//

import Foundation
import SwiftUI

struct SelectBankSheet: View {
    @Binding var viewModel: PaymentMethodViewModel
    
    var body: some View {
        VStack{
            SheetXButton(toggle: $viewModel.toggleSelectBank)
            VStack(alignment: .leading, spacing: 24){
                Text("Select Bank or e-Wallet")
                    .font(.tabiTitle)
                ScrollView{
                    VStack(alignment: .leading, spacing: .spacingTight){
                        Text("Popular")
                            .font(.tabiHeadline)
                        ForEach(TemplatePaymentMethod.allCases) { paymentMethod in
                            if paymentMethod.isPopular {
                                Divider()
                                HStack{
                                    Image(uiImage: paymentMethod.logoImage)
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
                                    Text(paymentMethod.name)
                                        .font(.tabiHeadline)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding([.bottom], .spacingMedium)
                    VStack(alignment: .leading, spacing: .spacingTight){
                        Text("All payment methods")
                        ForEach(TemplatePaymentMethod.allCases) { paymentMethod in
                            if !paymentMethod.isPopular {
                                Divider()
                                HStack{
                                    Image(uiImage: paymentMethod.logoImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 40, height: 40)
                                        .padding()
                                        .overlay {
                                            RoundedRectangle(cornerRadius: .radiusSmall)
                                                .fill(.clear)
                                                .stroke(.bgGreyOverlay, lineWidth: 0.5)
                                                .padding(0.5)
                                        }
                                    Text(paymentMethod.name)
                                        .font(.tabiHeadline)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .navigationBarBackButtonHidden(true)
        .padding()
        .padding([.top], 10)
    }
}

#Preview {
    SelectBankSheet(viewModel: .constant(PaymentMethodViewModel()))
}
