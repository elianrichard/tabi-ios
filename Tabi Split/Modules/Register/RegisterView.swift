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
        VStack (alignment: .leading, spacing: UIConfig.Spacing.Large) {
            Text("Ready to Take\nYour Bills?")
                .font(.tabiLargeTitle)
            
            VStack (spacing: UIConfig.Spacing.Medium) {
                InputWithLabel(label: "Fullname",
                               placeholder: "Your name",
                               text: $registerViewModel.name,
                               errorMessage: registerViewModel.nameError)
                InputWithLabel(label: "Phone Number",
                               placeholder: "628123456789",
                               text: $registerViewModel.phoneNumber,
                               errorMessage: registerViewModel.phoneNumberError)
                InputWithLabel(label: "Password",
                               placeholder: "Password",
                               isSecure: true,
                               text: $registerViewModel.password,
                               errorMessage: registerViewModel.passwordError)
                InputWithLabel(label: "Confirm Password",
                               placeholder: "Confirm Password",
                               isSecure: true,
                               text: $registerViewModel.confirmPassword,
                               errorMessage: registerViewModel.confirmPasswordError)
            }
            VStack (spacing: UIConfig.Spacing.Tight) {
                VStack (spacing: UIConfig.Spacing.Medium) {
                    CustomButton(text: "Sign Up", isEnabled: registerViewModel.isSignUpEnabled) {
                        withAnimation (nil) {
                            registerViewModel.register()
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
