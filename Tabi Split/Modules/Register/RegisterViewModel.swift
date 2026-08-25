//
//  RegisterViewModel.swift
//  Tabi
//
//  Created by ahmad naufal alfakhar on 09/10/24.
//
//  With passwordless Google/Apple sign-in, "register" and "login" are the same
//  find-or-create flow. This view model delegates to LoginViewModel so the two
//  screens share one implementation.
//

import Foundation

@Observable
class RegisterViewModel {
    private let loginViewModel = LoginViewModel()

    var isLoading: Bool { loginViewModel.isLoading }
    var errorMessage: String? { loginViewModel.errorMessage }
    var lastSignedInEmail: String { loginViewModel.lastSignedInEmail }

    @MainActor
    func signInWithGoogle() async -> Bool { await loginViewModel.signInWithGoogle() }

    @MainActor
    func signInWithApple() async -> Bool { await loginViewModel.signInWithApple() }
}
