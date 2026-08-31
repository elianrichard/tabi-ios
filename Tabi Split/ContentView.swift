//
//  ContentView.swift
//  Tabi
//
//  Created by Elian Richard on 19/09/24.
//

import SwiftUI
import SwiftData
import GoogleSignIn

struct ContentView: View {
    @State private var router = Router()
    @State private var eventViewModel = EventViewModel()
    @State private var eventInviteViewModel = EventInviteViewModel()
    @State private var eventExpenseViewModel = EventExpenseViewModel()
    @State private var eventSettlementViewModel = EventSettlementViewModel()
    @State private var profileViewModel = ProfileViewModel()
    private var loadingViewModel = LoadingViewModel.shared
    @State private var sessionState = SessionState.shared

    var body: some View {
        ZStack {
            NavigationStack (path: $router.path) {
                ZStack {
                    if !UserDefaultsService.shared.getOnboardingStatus() {
                        OnboardingView()
                            .onAppear {
                                UserDefaultsService.shared.setOnboardingStatus(true)
                            }
                    } else if sessionState.isAuthenticated {
                        HomeView()
                    } else {
                        LoginView()
                    }
                }
                .appNavigationDestinations()
            }

            if (loadingViewModel.isLoading) {
                LoadingView()
            }

            ToastOverlay()

            ErrorDialogOverlay()

            SplashView()
                .ignoresSafeArea()
        }
        .ignoresSafeArea(.keyboard)
        .environment(router)
        .environment(eventViewModel)
        .environment(eventInviteViewModel)
        .environment(eventExpenseViewModel)
        .environment(eventSettlementViewModel)
        .environment(profileViewModel)
        .environment(loadingViewModel)
        .onAppear {
            Task { await checkAuthentication() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .sessionExpired)) { _ in
            handleSessionExpired()
        }
        .onOpenURL { incomingURL in
            print("App was opened via URL: \(incomingURL)")
            // Let GoogleSignIn claim its OAuth callback URL first; if it handles
            // it, skip the app's own deep-link routing.
            if GIDSignIn.sharedInstance.handle(incomingURL) {
                return
            }
            handleIncomingURL(incomingURL)
        }
    }

    private func checkAuthentication() async {
        let hasToken: Bool
        do {
            let accessToken = try KeychainService.shared.getAccessToken()
            hasToken = !accessToken.isEmpty
        } catch {
            hasToken = false
        }

        let hasLocalUser = SwiftDataService.shared.getCurrentUser() != nil
        let isGuest = SwiftDataService.shared.getCurrentUser()?.email == "Guest"

        if isGuest {
            sessionState.isAuthenticated = true
            return
        }

        if !hasToken && !hasLocalUser {
            sessionState.isAuthenticated = false
            return
        }

        if !hasToken && hasLocalUser {
            SessionState.shared.sessionExpiredBanner = true
            sessionState.isAuthenticated = false
            return
        }

        do {
            let _ = try await ProfileService.shared.probeSession()
            sessionState.isAuthenticated = true
            await runMigrationIfNeeded()
        } catch {
            sessionState.isAuthenticated = false
            SessionState.shared.sessionExpiredBanner = true
        }
    }

    private func runMigrationIfNeeded() async {
        guard MigrationCoordinator.shared.hasUnsynced else { return }
        guard let cur = UserDefaultsService.shared.getCurrentUser(),
              !cur.userEmail.isEmpty,
              cur.userEmail != "Guest" else { return }
        SessionState.shared.migrationRunning = true
        let ok = await MigrationCoordinator.shared.runIfNeeded(ownerEmail: cur.userEmail, ownerName: cur.userName)
        SessionState.shared.migrationRunning = false
        if !ok {
            SessionState.shared.lastMigrationError = MigrationCoordinator.shared.lastError?.localizedDescription
        }
    }

    private func handleSessionExpired() {
        SessionState.shared.sessionExpiredBanner = true
        sessionState.isAuthenticated = false
        // Root swaps back to LoginView; clear any pushed screens so stale
        // authed views do not linger on top of the login root.
        router.popToRoot()
    }
    
    
    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "tabisplit" else {
            return
        }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            print("Invalid URL")
            return
        }
        
        guard let action = components.host, action == "join-event" else {
            print("Unknown URL action!")
            return
        }
        
        guard let eventId = components.queryItems?.first(where: { $0.name == "event-id" })?.value else {
            print("eventId not found")
            return
        }
        
        if let events = SwiftDataService.shared.fetchAllEvents(), events.contains(where: { $0.eventId == eventId }) {
            print("Event already joined")
            return
        }
        
        Task {
            if !profileViewModel.isGuest {
                do {
                    try await EventService.shared.joinEvent(eventId: eventId)
                } catch {
                    print("Join event failed: \(error)")
                }
            }
            // Home is the stack root; clear the path to land there rather than
            // pushing a duplicate Home screen.
            router.popToRoot()
        }
    }
}

#Preview {
    ContentView()
}
