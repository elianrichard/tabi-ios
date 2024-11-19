//
//  GuestLoginView.swift
//  Tabi Split
//
//  Created by Elian Richard on 18/11/24.
//

import SwiftUI

struct GuestLoginView: View {
    @Environment(Routes.self) var routes
    @Environment(ProfileViewModel.self) var profileViewModel: ProfileViewModel
    @State private var guestLoginViewModel = GuestLoginViewModel()
    
    @FocusState private var focusedField: FocusField?
    
    var body: some View {
            VStack (alignment: .leading, spacing: .spacingLarge) {
                Text("Hi there, nice to\nmeet you!")
                    .font(.tabiLargeTitle)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                    VStack(alignment: .leading, spacing: .spacingMedium) {
                        InputWithLabel(label: "Full name",
                                       placeholder: "Enter your name",
                                       text: $guestLoginViewModel.name,
                                       errorMessage: guestLoginViewModel.nameError,
                                       focusedField: $focusedField,
                                       focusCase: .field1)
                    }
                
                    CustomButton(text: "Enter") {
                        if guestLoginViewModel.login() {
                            routes.navigate(to: .HomeView)
                        }
                    }
            }
        .padding()
        .navigationBarBackButtonHidden(true)
        .addBackgroundColor(.bgWhite) {
            focusedField = nil
        }
    }
}

#Preview {
    LoginView()
        .environment(Routes())
}
