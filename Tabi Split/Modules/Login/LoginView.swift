//
//  LoginView.swift
//  Tabi
//
//  Created by ahmad naufal alfakhar on 03/10/24.
//

import SwiftUI

struct LoginView: View {
    @Environment(Routes.self) var routes
    @State private var loginViewModel = LoginViewModel()
    
    var body: some View {
        VStack (alignment: .leading, spacing: UIConfig.Spacing.Large) {
            Text("Hey There,\nYou're Back!")
                .font(.tabiLargeTitle)
                .multilineTextAlignment(.leading)
            
            VStack (alignment: .trailing, spacing: 8) {
                VStack(alignment: .leading, spacing: UIConfig.Spacing.Medium) {
                    InputWithLabel(label: "Phone Number",
                                   placeholder: "Your phone number",
                                   type: .numberPad, text: $loginViewModel.phoneNumber, errorMessage: loginViewModel.phoneNumberError)
                    InputWithLabel(label: "Password",
                                   placeholder: "Password",
                                   isSecure: true,
                                   text: $loginViewModel.password, errorMessage: loginViewModel.passwordError)
                }
                Button {
                    print("forgot password")
                } label: {
                    Text("Forgot Password?")
                        .font(.tabiBody)
                        .foregroundStyle(.textBlue)
                }
            }
            
            VStack (spacing: UIConfig.Spacing.Medium) {
                CustomButton(text: "Sign In") {
                    withAnimation (nil) {
                        loginViewModel.login()
                    }
                }
                
                DividerWithText()
                
                CustomButton(text: "Sign In With Apple ID",icon: "apple.logo", customBackgroundColor: .black, customTextColor: .white) {
                    print("Login with Apple")
                }
                
                HStack (spacing: 3) {
                    Text("Don't have an account?")
                        .font(.tabiBody)
                    Button {
                        routes.navigate(to: .RegisterView)
                    } label: {
                        Text("Sign Up")
                            .font(.custom(UIConfig.Font.Name.Bold, size: UIConfig.Font.Size.Body))
                            .foregroundStyle(.textBlue)
                    }
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    LoginView()
        .environment(Routes())
}
