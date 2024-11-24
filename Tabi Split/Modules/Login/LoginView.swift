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
        ZStack {
            VStack {
                if SwiftDataService.shared.getCurrentUser() == nil {
                    Button {
                        if loginViewModel.guestLogin() {
                            profileViewModel.user = UserData(name: "Guest", phone: "Guest")
                            routes.navigate(to: .HomeView)
                        }
                    } label: {
                        Text("Enter as Guest")
                            .font(.tabiBody)
                            .foregroundStyle(.textGrey)
                            .opacity(focusedField != nil ? 0 : 1)
                            .padding(14)
                    }
                    .padding(-14)
                } else {
                    Icon(systemName: "arrow.left", size: 16) {
                        routes.navigateBack()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
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
                    CustomButton(text: loginViewModel.isLoading ? "Loading..." : "Sign In", animation: .default) {
                        Task {
//                            if await profileViewModel.logout(){
                                if await loginViewModel.login() {
                                    routes.navigate(to: .HomeView)
                                }
//                            }
                        }
                    }
                    //                TEMPORARILY DISABLED: LOGIN WITH APPLE ID
                    if (false) {
                        DividerWithText()
                        
                        CustomButton(text: "Sign In With Apple ID", icon: "apple.logo", customBackgroundColor: .black, customTextColor: .white) {
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
