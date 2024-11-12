//
//  PaymentMethodView.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 04/11/24.
//

import Foundation
import SwiftUI

struct PaymentMethodView: View {
    @Environment(Routes.self) var routes
    @Environment(ProfileViewModel.self) private var profileViewModel
    @State var viewModel = PaymentMethodViewModel()
    
    var body: some View {
        VStack{
            TopNavigation(title: "Payment Methods")
            VStack(alignment: .center, spacing: .spacingMedium){
                if profileViewModel.userPaymentMethods.isEmpty {
                    VStack(spacing: .spacingLarge){
                        Image("PaymentEmpty")
                        Text("Let your friends know your preferred method to pay.")
                            .multilineTextAlignment(.center)
                            .font(.tabiSubtitle)
                            .frame(width: 250)
                    }
                    CustomButton(text: "+ Add payment method", type: .tertiary) {
                        viewModel.toggleDetailBankSheet.toggle()
                    }
                }else{
                    if profileViewModel.userPaymentMethods.contains(where: { paymentMethod in paymentMethod.isFavorite}){
                        ScrollView(showsIndicators: false){
                            VStack(alignment: .leading, spacing: .spacingTight){
                                Text("Favorite")
                                    .font(.tabiHeadline)
                                Divided{
                                    ForEach(Array(profileViewModel.userPaymentMethods.enumerated()), id: \.offset) { index, paymentMethod in
                                        if paymentMethod.isFavorite{
                                            HStack{
                                                Image(uiImage: paymentMethod.bank.bankLogo)
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
                                                VStack(alignment: .leading, spacing: .spacingSmall){
                                                    Text(paymentMethod.name)
                                                        .font(.tabiHeadline)
                                                    VStack(alignment: .leading){
                                                        Text(paymentMethod.bank.bankName)
                                                        Text(paymentMethod.bankNumber)
                                                    }
                                                    .font(.tabiBody)
                                                    .foregroundColor(.textGrey)
                                                }
                                                Spacer()
                                                Icon(paymentMethod.isFavorite ? .favourited : .favourite, color: .textBlack, size: 20)
                                                    .onTapGesture {
                                                        profileViewModel.userPaymentMethods[index].isFavorite.toggle()
                                                    }
                                            }
                                            .onTapGesture {
                                                viewModel.idToBeEdited = paymentMethod.id
                                                viewModel.toggleDetailBankSheet.toggle()
                                            }
                                        }
                                    }
                                }
                                Text("Others")
                                    .font(.tabiHeadline)
                                Divided{
                                    ForEach(Array(profileViewModel.userPaymentMethods.enumerated()), id: \.offset) { index, paymentMethod in
                                        if !paymentMethod.isFavorite{
                                            HStack{
                                                Image(uiImage: paymentMethod.bank.bankLogo)
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
                                                VStack(alignment: .leading, spacing: .spacingSmall){
                                                    Text(paymentMethod.name)
                                                        .font(.tabiHeadline)
                                                    VStack(alignment: .leading){
                                                        Text(paymentMethod.bank.bankName)
                                                        Text(paymentMethod.bankNumber)
                                                    }
                                                    .font(.tabiBody)
                                                    .foregroundColor(.textGrey)
                                                }
                                                Spacer()
                                                Icon(paymentMethod.isFavorite ? .favourited : .favourite, color: .textBlack, size: 20)
                                                    .onTapGesture {
                                                        profileViewModel.userPaymentMethods[index].isFavorite.toggle()
                                                    }
                                            }
                                            .onTapGesture {
                                                viewModel.idToBeEdited = paymentMethod.id
                                                viewModel.toggleDetailBankSheet.toggle()
                                            }
                                        }
                                    }
                                }
                                CustomButton(text: "+ Add payment method", type: .tertiary) {
                                    viewModel.toggleDetailBankSheet.toggle()
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }else{
                        ScrollView(showsIndicators: false){
                            VStack(alignment: .leading, spacing: .spacingTight){
                                Text("All payment methods")
                                    .font(.tabiHeadline)
                                Divided{
                                    ForEach(Array(profileViewModel.userPaymentMethods.enumerated()), id: \.offset) { index, paymentMethod in
                                        HStack{
                                            Image(uiImage: paymentMethod.bank.bankLogo)
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
                                            VStack(alignment: .leading, spacing: .spacingSmall){
                                                Text(paymentMethod.name)
                                                    .font(.tabiHeadline)
                                                VStack(alignment: .leading){
                                                    Text(paymentMethod.bank.bankName)
                                                    Text(paymentMethod.bankNumber)
                                                }
                                                .font(.tabiBody)
                                                .foregroundColor(.textGrey)
                                            }
                                            Spacer()
                                            Icon(paymentMethod.isFavorite ? .favourited : .favourite, color: .textBlack, size: 20)
                                                .onTapGesture {
                                                    profileViewModel.userPaymentMethods[index].isFavorite.toggle()
                                                }
                                        }
                                        .onTapGesture {
                                            viewModel.idToBeEdited = paymentMethod.id
                                            viewModel.toggleDetailBankSheet.toggle()
                                        }
                                    }
                                }
                                CustomButton(text: "+ Add payment method", type: .tertiary) {
                                    viewModel.toggleDetailBankSheet.toggle()
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .sheet(isPresented: $viewModel.toggleDetailBankSheet){
            BankDetailFormSheet(viewModel: $viewModel, isEditing: viewModel.idToBeEdited != nil ? true : false)
        }
        .navigationBarBackButtonHidden(true)
        .padding(.spacingMedium)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview {
    PaymentMethodView()
        .environment(Routes())
        .environment(ProfileViewModel())
}
