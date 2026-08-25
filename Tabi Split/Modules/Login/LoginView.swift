//
//  LoginView.swift
//  Tabi
//
//  Created by ahmad naufal alfakhar on 03/10/24.
//

import SwiftUI

struct LoginView: View {
    @Environment(Router.self) var router
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
                                profileViewModel.user = UserData(name: "Guest", email: "Guest")
                                sessionState.isAuthenticated = true
                                router.popToRoot()
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
                            router.pop()
                        }
                    }
                    Spacer()
                }
                
                Spacer(minLength: 20)
                
                VStack (alignment: .leading, spacing: .spacingLarge) {
                    Text("Hey There,\nWelcome to Tabi!")
                        .font(.tabiLargeTitle)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Sign in with your Apple or Google account to sync your events across devices.")
                        .font(.tabiBody)
                        .foregroundStyle(.textGrey)

                    if let errorMessage = loginViewModel.errorMessage {
                        Text(errorMessage)
                            .font(.tabiBody)
                            .foregroundStyle(.buttonRed)
                    }

                    VStack (spacing: .spacingMedium) {
                        CustomButton(text: loginViewModel.isLoading ? "Loading..." : "Continue with Apple",
                                     icon: "apple.logo",
                                     customBackgroundColor: .black,
                                     customTextColor: .white) {
                            Task { await handleSignIn { await loginViewModel.signInWithApple() } }
                        }

                        CustomButton(text: loginViewModel.isLoading ? "Loading..." : "Continue with Google",
                                     type: .secondary) {
                            Task { await handleSignIn { await loginViewModel.signInWithGoogle() } }
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

    /// Runs a provider sign-in, then the shared post-login flow: wipe local data
    /// if a different account previously owned this device, run the pending
    /// migration, and make Home the root.
    @MainActor
    private func handleSignIn(_ signIn: () async -> Bool) async {
        let ok = await signIn()
        guard ok else { return }

        let incomingEmail = loginViewModel.lastSignedInEmail
        let prev = UserDefaultsService.shared.getCurrentUser()
        if let prev, prev.userEmail != "Guest", prev.userEmail != incomingEmail {
            SwiftDataService.shared.deleteAllEvents()
            SwiftDataService.shared.deleteAllExpenses()
            SwiftDataService.shared.deleteAllUser()
            UserDefaultsService.shared.deleteCurrentUser()
        }

        sessionState.sessionExpiredBanner = false
        profileViewModel.refreshUserData()
        let name = profileViewModel.user.name
        sessionState.migrationRunning = true
        let migrated = await MigrationCoordinator.shared.runIfNeeded(ownerEmail: incomingEmail, ownerName: name)
        sessionState.migrationRunning = false
        if !migrated {
            sessionState.lastMigrationError = MigrationCoordinator.shared.lastError?.localizedDescription
        }
        // Make Home the root: swap the stack root to HomeView and clear the path
        // so the auth screens are gone and Back cannot return.
        sessionState.isAuthenticated = true
        router.popToRoot()
    }
}

#Preview {
    LoginView()
        .environment(Router())
        .environment(ProfileViewModel())
}
