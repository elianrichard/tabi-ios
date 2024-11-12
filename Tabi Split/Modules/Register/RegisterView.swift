//
//  LoginView.swift
//  Tabi
//
//  Created by ahmad naufal alfakhar on 03/10/24.
//

import SwiftUI

struct RegisterView: View {
    @Environment(Routes.self) private var routes
    @State private var registerViewModel = RegisterViewModel()
    
    var body: some View {
        Spacer()
        VStack (alignment: .leading, spacing: .spacingLarge) {
            Text("Ready to Take\nYour Bills?")
                .font(.tabiLargeTitle)
            
            VStack (spacing: .spacingMedium) {
                InputWithLabel(label: "Fullname",
                               placeholder: "Enter your full name",
                               text: $registerViewModel.name,
                               errorMessage: registerViewModel.nameError)
                InputWithLabel(label: "Phone Number",
                               placeholder: "Enter your phone number",
                               text: $registerViewModel.phoneNumber,
                               errorMessage: registerViewModel.phoneNumberError,
                               inputTypePicked: .phone)
                InputWithLabel(label: "Password",
                               placeholder: "Enter your password",
                               text: $registerViewModel.password,
                               errorMessage: registerViewModel.passwordError,
                               isSecure: true)
                InputWithLabel(label: "Confirm Password",
                               placeholder: "Re-enter your Password",
                               text: $registerViewModel.confirmPassword,
                               errorMessage: registerViewModel.confirmPasswordError,
                               isSecure: true)
            }
            VStack (spacing: .spacingTight) {
                VStack (spacing: .spacingMedium) {
                    CustomButton(text: registerViewModel.isLoading ? "Loading..." : "Sign Up",
                                 isEnabled: registerViewModel.isSignUpEnabled) {
                        Task {
                            await registerViewModel.register()
                            
                            if registerViewModel.isRegisterSuccess {
                                routes.navigate(to: .LoginView)
                            }
                        }
                    }
                    
                    DividerWithText(text: "Or")
                    
                    CustomButton(text: "Sign Up With Apple ID",icon: "apple.logo", customBackgroundColor: .black, customTextColor: .white) {
                        print("SignUp with Apple")
                    }
                }
                
                HStack (spacing: 3) {
                    Text("Already have an account?")
                        .font(.tabiBody)
                    Button {
                        routes.navigate(to: .LoginView)
                    } label: {
                        Text("Sign In")
                            .font(.custom(UIConfig.Font.Name.Bold, size: UIConfig.Font.Size.Body))
                            .foregroundStyle(.textBlue)
                    }
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .navigationBarBackButtonHidden(true)
        .padding()
    }
}

#Preview {
    RegisterView()
        .environment(Routes())
}
