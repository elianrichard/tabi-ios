//
//  RegisterView.swift
//  Tabi
//
//  Created by ahmad naufal alfakhar on 03/10/24.
//

import SwiftUI

struct RegisterView: View {
    @Environment(Router.self) private var router
    @Environment(ProfileViewModel.self) private var profileViewModel: ProfileViewModel
    @State private var registerViewModel = RegisterViewModel()
    @State private var sessionState = SessionState.shared

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

                Text("Create your account with Apple or Google — no password needed.")
                    .font(.tabiBody)
                    .foregroundStyle(.textGrey)

                if let errorMessage = registerViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.tabiBody)
                        .foregroundStyle(.buttonRed)
                }

                VStack (spacing: .spacingTight) {
                    VStack (spacing: .spacingMedium) {
                        CustomButton(text: registerViewModel.isLoading ? "Loading..." : "Continue with Apple",
                                     icon: "apple.logo",
                                     customBackgroundColor: .black,
                                     customTextColor: .white) {
                            Task { await handleSignIn { await registerViewModel.signInWithApple() } }
                        }

                        CustomButton(text: registerViewModel.isLoading ? "Loading..." : "Continue with Google",
                                     type: .secondary) {
                            Task { await handleSignIn { await registerViewModel.signInWithGoogle() } }
                        }
                    }

                    HStack (spacing: .spacingXSmall) {
                        Text("Already have an account?")
                            .font(.tabiBody)
                        Button {
                            router.pop()
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
        }
    }

    /// Shared post-sign-in flow, mirroring LoginView: run any pending migration
    /// and make Home the root.
    @MainActor
    private func handleSignIn(_ signIn: () async -> Bool) async {
        let ok = await signIn()
        guard ok else { return }

        let incomingEmail = registerViewModel.lastSignedInEmail
        sessionState.sessionExpiredBanner = false
        profileViewModel.refreshUserData()
        let name = profileViewModel.user.name
        sessionState.migrationRunning = true
        let migrated = await MigrationCoordinator.shared.runIfNeeded(ownerEmail: incomingEmail, ownerName: name)
        sessionState.migrationRunning = false
        if !migrated {
            sessionState.lastMigrationError = MigrationCoordinator.shared.lastError?.localizedDescription
        }
        sessionState.isAuthenticated = true
        router.popToRoot()
    }
}

#Preview {
    RegisterView()
        .environment(Router())
        .environment(ProfileViewModel())
}
