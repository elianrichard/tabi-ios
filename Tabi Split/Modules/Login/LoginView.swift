//
//  LoginView.swift
//  Tabi
//
//  Created by ahmad naufal alfakhar on 03/10/24.
//

import SwiftUI

struct LoginView: View {
    @Environment(Routes.self) var routes
    @Environment(ProfileViewModel.self) var profileViewModel: ProfileViewModel
    @State private var loginViewModel = LoginViewModel()
    
    @FocusState private var focusedField: FocusField?
    
    var body: some View {
        VStack (alignment: .leading, spacing: .spacingLarge) {
            Text("Hey There,\nYou're Back!")
                .font(.tabiLargeTitle)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            VStack (alignment: .trailing, spacing: 8) {
                VStack(alignment: .leading, spacing: .spacingMedium) {
                    InputWithLabel(label: "Phone Number",
                                   placeholder: "Enter your phone number",
                                   text: $loginViewModel.phoneNumber,
                                   errorMessage: loginViewModel.phoneNumberError,
                                   inputTypePicked: .phone,
                                   focusedField: $focusedField,
                                   focusCase: .field1)
                    InputWithLabel(label: "Password",
                                   placeholder: "Enter your password",
                                   text: $loginViewModel.password,
                                   errorMessage: loginViewModel.passwordError, isSecure: true,
                                   focusedField: $focusedField,
                                   focusCase: .field2)
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
                        if await loginViewModel.login() {
                            routes.navigate(to: .HomeView)
                        }
                    }
                }
                
                if (false) {
                    DividerWithText()
                    
                    CustomButton(text: "Sign In With Apple ID",icon: "apple.logo", customBackgroundColor: .black, customTextColor: .white) {
                        print("Login with Apple")
                    }
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
