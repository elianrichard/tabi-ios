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
                    // Back only makes sense when this screen was pushed on top of a
                    // signed-in session (Profile → link a guest to an account). At
                    // the root — first launch, or after a session expiry swapped Home
                    // out — there is nothing to pop, so offer guest entry instead.
                    if canGoBack {
                        Icon(systemName: "arrow.left", size: 16) {
                            router.pop()
                        }
                    } else {
                        Button {
                            Task { await handleGuestEntry() }
                        } label: {
                            Text(loginViewModel.isLoading ? "Loading..." : "Enter as Guest")
                                .font(.tabiBody)
                                .foregroundStyle(.textGrey)
                                .padding(14)
                        }
                        .padding(-14)
                        .disabled(loginViewModel.isLoading)
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
                                     isEnabled: !loginViewModel.isLoading,
                                     icon: "apple.logo",
                                     customBackgroundColor: .black,
                                     customTextColor: .white) {
                            Task { await handleSignIn { await loginViewModel.signInWithApple() } }
                        }

                        CustomButton(text: loginViewModel.isLoading ? "Loading..." : "Continue with Google",
                                     type: .secondary,
                                     isEnabled: !loginViewModel.isLoading) {
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

    /// True when this screen sits on top of a signed-in session and can pop back
    /// to it. False at the root (nothing to pop) and when pushed from onboarding
    /// (no account yet), where guest entry is the right alternative.
    private var canGoBack: Bool {
        !router.path.isEmpty && SwiftDataService.shared.getCurrentUser() != nil
    }

    /// Runs a provider sign-in, then the shared post-login flow. The guest→account
    /// merge happens server-side inside the sign-in request (the guest token is sent
    /// as merge_from_guest_token), so a guest's local rows must survive the switch.
    @MainActor
    private func handleSignIn(_ signIn: () async -> Bool) async {
        // Captured before sign-in overwrites the stored user.
        let previous = UserDefaultsService.shared.getCurrentUser()
        let wasGuest = previous?.isGuest == true

        guard await signIn() else { return }
        finishLogin(previous: previous, mergedFromPrevious: wasGuest)
    }

    /// Guest is a server-backed account: create the session, then adopt the
    /// returned identity (real userId, kind == guest). Requires connectivity. A
    /// fresh guest is always a new identity — nothing is merged from whichever
    /// account owned this device before (e.g. one whose session expired).
    @MainActor
    private func handleGuestEntry() async {
        let previous = UserDefaultsService.shared.getCurrentUser()
        guard await loginViewModel.guestLogin() != nil else { return }
        finishLogin(previous: previous, mergedFromPrevious: false)
    }

    /// Shared post-login bookkeeping. The view model has already persisted the
    /// incoming user (UserDefaults + SwiftData). When a *different* account owned
    /// this device and nothing was merged server-side, its local cache is dropped
    /// so the two are never mixed — and the incoming user's row, which that wipe
    /// takes with it, is put back. Then Home becomes the root: the path is
    /// cleared so the auth screens are gone and Back cannot return, and Home's
    /// refresh pulls the (merged) events from the server.
    @MainActor
    private func finishLogin(previous: CurrentUserDefaults?, mergedFromPrevious: Bool) {
        if let previous, !mergedFromPrevious,
           let incoming = UserDefaultsService.shared.getCurrentUser(),
           !CurrentUserDefaults.isSameAccount(previous, incoming) {
            SwiftDataService.shared.deleteAllEvents()
            SwiftDataService.shared.deleteAllExpenses()
            SwiftDataService.shared.deleteAllUser()
            SwiftDataService.shared.saveCurrentUser(user: incoming)
        }

        sessionState.sessionExpiredBanner = false
        profileViewModel.refreshUserData()
        sessionState.isAuthenticated = true
        router.popToRoot()
    }
}

#Preview {
    LoginView()
        .environment(Router())
        .environment(ProfileViewModel())
}
