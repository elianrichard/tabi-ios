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
        VStack (alignment: .leading, spacing: .spacingLarge) {
            Text("Hey There,\nYou're Back!")
                .font(.tabiLargeTitle)
                .multilineTextAlignment(.leading)
            
            VStack (alignment: .trailing, spacing: 8) {
                VStack(alignment: .leading, spacing: .spacingMedium) {
                    InputWithLabel(label: "Phone Number",
                                   placeholder: "Enter your phone number",
                                   text: $loginViewModel.phoneNumber,
                                   errorMessage: loginViewModel.phoneNumberError,
                                   inputTypePicked: .phone)
                    InputWithLabel(label: "Password",
                                   placeholder: "Enter your password",
                                   text: $loginViewModel.password,
                                   errorMessage: loginViewModel.passwordError, isSecure: true)
                }
                Button {
                    print("forgot password")
                } label: {
                    Text("Forget Password?")
                        .font(.tabiBody)
                        .foregroundStyle(.textBlue)
                }
            }
            
            VStack (spacing: .spacingMedium) {
                CustomButton(text: loginViewModel.isLoading ? "Loading..." : "Sign In") {
                    Task {
                        let isSuccess = await loginViewModel.login()
                        
                        if isSuccess {
                            routes.navigate(to: .HomeView)
                        }
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
