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
                VStack(spacing: .spacingLarge){
                    Image("PaymentEmpty")
                    Text("Let your friends know your preferred method to pay.")
                        .multilineTextAlignment(.center)
                        .font(.tabiSubtitle)
                        .frame(width: 250)
                }
                CustomButton(text: "+ Add payment method", type: .tertiary) {
                    viewModel.toggleSelectBank.toggle()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .sheet(isPresented: $viewModel.toggleSelectBank){
            SelectBankSheet(viewModel: $viewModel)
                .presentationDetents([.medium, .large], selection: $viewModel.settingsDetent)
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
