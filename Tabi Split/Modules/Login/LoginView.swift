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
                            Task {
                                // Guest is now a server-backed account: create the
                                // session, then adopt the returned identity (real
                                // userId, kind == guest). Requires connectivity.
                                if let guestUser = await loginViewModel.guestLogin() {
                                    profileViewModel.user = guestUser
                                    sessionState.isAuthenticated = true
                                    router.popToRoot()
                                }
                            }
                        } label: {
                            Text(loginViewModel.isLoading ? "Loading..." : "Enter as Guest")
                                .font(.tabiBody)
                                .foregroundStyle(.textGrey)
                                .padding(14)
                        }
                        .padding(-14)
                        .disabled(loginViewModel.isLoading)
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

    /// Runs a provider sign-in, then the shared post-login flow. The guest→account
    /// merge happens server-side inside the sign-in request (the guest token is sent
    /// as merge_from_guest_token), so here we only clear stale local data owned by a
    /// *different* prior account, refresh from the server, and make Home the root.
    @MainActor
    private func handleSignIn(_ signIn: () async -> Bool) async {
        // Was this a guest upgrade? Captured before sign-in overwrites the stored
        // user; a guest merges its data, so its local rows must NOT be wiped.
        let wasGuest = UserDefaultsService.shared.getCurrentUser()?.kind == "guest"
        let prevEmail = UserDefaultsService.shared.getCurrentUser()?.userEmail

        let ok = await signIn()
        guard ok else { return }

        let incomingEmail = loginViewModel.lastSignedInEmail
        // A different real account previously owned this device: drop its local
        // cache so it isn't mixed with the incoming account. Guests are exempt —
        // their data was merged server-side and will rehydrate on refresh.
        if !wasGuest, let prevEmail, !prevEmail.isEmpty, prevEmail != incomingEmail {
            SwiftDataService.shared.deleteAllEvents()
            SwiftDataService.shared.deleteAllExpenses()
            SwiftDataService.shared.deleteAllUser()
            UserDefaultsService.shared.deleteCurrentUser()
        }

        sessionState.sessionExpiredBanner = false
        profileViewModel.refreshUserData()
        // Make Home the root: swap the stack root to HomeView and clear the path
        // so the auth screens are gone and Back cannot return. HomeView's refresh
        // pulls the (merged) events from the server.
        sessionState.isAuthenticated = true
        router.popToRoot()
    }
}

#Preview {
    LoginView()
        .environment(Router())
        .environment(ProfileViewModel())
}
