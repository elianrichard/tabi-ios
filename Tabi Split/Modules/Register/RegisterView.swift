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
    @FocusState private var focusedField: FocusField?
    
    var body: some View {
        ZStack {
            VStack {
                Image(.bigOctopus)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                    .rotationEffect(Angle(degrees: 225))
                    .offset(x: 65, y: -110)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            
            VStack (alignment: .leading, spacing: .spacingLarge) {
                Text("Start Your\nJourney!")
                    .font(.tabiLargeTitle)
                
                VStack (spacing: .spacingMedium) {
                    InputWithLabel(label: "Fullname",
                                   placeholder: "Enter your full name",
                                   text: $registerViewModel.name,
                                   errorMessage: registerViewModel.nameError,
                                   focusedField: $focusedField, focusCase: .field1
                    )
                    InputWithLabel(label: "Phone Number",
                                   placeholder: "Enter your phone number",
                                   text: $registerViewModel.phoneNumber,
                                   errorMessage: registerViewModel.phoneNumberError,
                                   inputTypePicked: .phone,
                                   focusedField: $focusedField, focusCase: .field2
                    )
                    InputWithLabel(label: "Password",
                                   placeholder: "Enter your password",
                                   text: $registerViewModel.password,
                                   errorMessage: registerViewModel.passwordError,
                                   isSecure: true,
                                   focusedField: $focusedField, focusCase: .field3
                    )
                    InputWithLabel(label: "Confirm Password",
                                   placeholder: "Re-enter your Password",
                                   text: $registerViewModel.confirmPassword,
                                   errorMessage: registerViewModel.confirmPasswordError,
                                   isSecure: true,
                                   focusedField: $focusedField, focusCase: .field4
                    )
                }
                VStack (spacing: .spacingTight) {
                    VStack (spacing: .spacingMedium) {
                        CustomButton(text: registerViewModel.isLoading ? "Loading..." : "Sign Up",
                                     isEnabled: registerViewModel.isSignUpEnabled,
                                     animation: .default) {
                            Task {
                                if await registerViewModel.register() {
                                    routes.navigate(to: .HomeView)
                                }
                            }
                        }
                        
//                TEMPORARILY DISABLED: REGISTER WITH APPLE ID
                        if (false) {
                            DividerWithText(text: "Or")
                            
                            CustomButton(text: "Sign Up With Apple ID",icon: "apple.logo", customBackgroundColor: .black, customTextColor: .white) {
                                print("SignUp with Apple")
                            }
                        }
                    }
                    
                    HStack (spacing: .spacingXSmall) {
                        Text("Already have an account?")
                            .font(.tabiBody)
                        Button {
                            routes.navigateBack()
                        } label: {
                            Text("Sign In")
                                .font(.custom(UIConfig.Font.Name.Bold, size: UIConfig.Font.Size.Body))
                                .foregroundStyle(.textBlue)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
        .addBackgroundColor(.bgWhite) {
            focusedField = nil
        }
    }
}

#Preview {
    RegisterView()
        .environment(Routes())
}
