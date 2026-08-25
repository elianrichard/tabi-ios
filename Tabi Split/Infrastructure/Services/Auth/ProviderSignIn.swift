//
//  ProviderSignIn.swift
//  Tabi Split
//
//  Native Google / Apple sign-in. Each method drives the platform SDK and
//  returns the provider id_token (plus name/email when available) which the
//  caller exchanges with the backend via AuthenticationService.
//

import AuthenticationServices
import UIKit
import GoogleSignIn

/// The verified credential obtained from a provider, ready to send to the backend.
struct ProviderCredential {
    let idToken: String
    let name: String?
    let email: String?
}

enum ProviderSignInError: LocalizedError {
    case noPresentingWindow
    case missingIDToken
    case cancelled
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .noPresentingWindow: return "Could not present the sign-in screen."
        case .missingIDToken: return "Sign-in did not return a valid token."
        case .cancelled: return "Sign-in was cancelled."
        case .failed(let message): return message
        }
    }
}

@MainActor
final class ProviderSignIn: NSObject {
    static let shared = ProviderSignIn()

    // Retained for the duration of an Apple sign-in so the delegate/continuation live.
    private var appleContinuation: CheckedContinuation<ProviderCredential, Error>?

    // MARK: - Google

    func signInWithGoogle() async throws -> ProviderCredential {
        guard let presenter = Self.topViewController() else {
            throw ProviderSignInError.noPresentingWindow
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
        guard let idToken = result.user.idToken?.tokenString else {
            throw ProviderSignInError.missingIDToken
        }
        return ProviderCredential(
            idToken: idToken,
            name: result.user.profile?.name,
            email: result.user.profile?.email
        )
    }

    // MARK: - Apple

    func signInWithApple() async throws -> ProviderCredential {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        return try await withCheckedThrowingContinuation { continuation in
            self.appleContinuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    // MARK: - Presentation

    static func topViewController(_ base: UIViewController? = nil) -> UIViewController? {
        let root = base ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController

        if let nav = root as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        if let tab = root as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(selected)
        }
        if let presented = root?.presentedViewController {
            return topViewController(presented)
        }
        return root
    }
}

extension ProviderSignIn: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        defer { appleContinuation = nil }
        guard
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = credential.identityToken,
            let idToken = String(data: tokenData, encoding: .utf8)
        else {
            appleContinuation?.resume(throwing: ProviderSignInError.missingIDToken)
            return
        }

        // Apple returns fullName/email only on the first authorization; the backend
        // treats the id_token's own email claim as authoritative when present.
        let name = credential.fullName.flatMap { formatted in
            PersonNameComponentsFormatter().string(from: formatted).trimmingCharacters(in: .whitespaces)
        }
        appleContinuation?.resume(returning: ProviderCredential(
            idToken: idToken,
            name: (name?.isEmpty == false) ? name : nil,
            email: credential.email
        ))
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithError error: Error) {
        defer { appleContinuation = nil }
        if let authError = error as? ASAuthorizationError, authError.code == .canceled {
            appleContinuation?.resume(throwing: ProviderSignInError.cancelled)
        } else {
            appleContinuation?.resume(throwing: ProviderSignInError.failed(error.localizedDescription))
        }
    }
}

extension ProviderSignIn: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
