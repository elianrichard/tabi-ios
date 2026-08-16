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
    @State private var sessionState = SessionState.shared

    @FocusState private var focusedField: FocusField?

    var body: some View {
        ZStack {
            VStack {
                Image(.bigWallet)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                    .rotationEffect(Angle(degrees: 225))
                    .offset(x: 75, y: -120)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

            VStack (spacing: 0) {
                if sessionState.sessionExpiredBanner {
                    Text("Your session expired. Sign in to sync your local data.")
                        .font(.tabiBody)
                        .foregroundStyle(.textGrey)
                        .multilineTextAlignment(.center)
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(Color.yellow.opacity(0.25))
                        .cornerRadius(8)
                        .padding(.bottom, 8)
                }
                HStack {
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
                                .padding(14)
                        }
                        .padding(-14)
                    } else {
                        Icon(systemName: "arrow.left", size: 16) {
                            routes.navigateBack()
                        }
                    }
                    Spacer()
                }
                
                Spacer(minLength: 20)
                
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
                                let incomingPhone = loginViewModel.phoneNumber.formattedAsPhoneNumber()
                                // Wipe local data if a different user previously owned this device.
                                let prev = UserDefaultsService.shared.getCurrentUser()
                                if let prev, prev.userPhone != "Guest", prev.userPhone != incomingPhone {
                                    SwiftDataService.shared.deleteAllEvents()
                                    SwiftDataService.shared.deleteAllExpenses()
                                    SwiftDataService.shared.deleteAllUser()
                                    UserDefaultsService.shared.deleteCurrentUser()
                                }
                                if await loginViewModel.login() {
                                    sessionState.sessionExpiredBanner = false
                                    profileViewModel.refreshUserData()
                                    let name = profileViewModel.user.name
                                    sessionState.migrationRunning = true
                                    let ok = await MigrationCoordinator.shared.runIfNeeded(ownerPhone: incomingPhone, ownerName: name)
                                    sessionState.migrationRunning = false
                                    if !ok {
                                        sessionState.lastMigrationError = MigrationCoordinator.shared.lastError?.localizedDescription
                                    }
                                    routes.navigate(to: .HomeView)
                                }
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
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
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
