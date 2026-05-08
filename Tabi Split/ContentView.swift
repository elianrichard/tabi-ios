//
//  ContentView.swift
//  Tabi
//
//  Created by Elian Richard on 19/09/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var routes = AppRouter()
    @State private var eventViewModel = EventViewModel()
    @State private var eventInviteViewModel = EventInviteViewModel()
    @State private var eventExpenseViewModel = EventExpenseViewModel()
    @State private var eventSettlementViewModel = EventSettlementViewModel()
    @State private var profileViewModel = ProfileViewModel()
    @State private var loadingViewModel = LoadingViewModel()
    
    @State private var isAuthenticated = false

    var body: some View {
        ZStack {
            NavigationStack (path: $routes.navPath) {
                ZStack {
                    if !UserDefaultsService.shared.getOnboardingStatus() {
                        OnboardingView()
                            .onAppear {
                                UserDefaultsService.shared.setOnboardingStatus(true)
                            }
                    } else if isAuthenticated {
                        HomeView()
                    } else {
                        LoginView()
                    }
                }
                .navigationDestination(for: AppRoute.self) { route in
                    AppRouteDestinationView(route: route)
                }
            }

            if (loadingViewModel.isLoading) {
                LoadingView()
            }

            SplashView()
                .ignoresSafeArea()
        }
        .ignoresSafeArea(.keyboard)
        .environment(routes)
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
        let isGuest = SwiftDataService.shared.getCurrentUser()?.phone == "Guest"

        if isGuest {
            isAuthenticated = true
            return
        }

        if !hasToken && !hasLocalUser {
            isAuthenticated = false
            return
        }

        if !hasToken && hasLocalUser {
            SessionState.shared.sessionExpiredBanner = true
            isAuthenticated = false
            return
        }

        do {
            let _ = try await ProfileService.shared.probeSession()
            isAuthenticated = true
            await runMigrationIfNeeded()
        } catch {
            isAuthenticated = false
            SessionState.shared.sessionExpiredBanner = true
        }
    }

    private func runMigrationIfNeeded() async {
        guard MigrationCoordinator.shared.hasUnsynced else { return }
        guard let cur = UserDefaultsService.shared.getCurrentUser(),
              !cur.userPhone.isEmpty,
              cur.userPhone != "Guest" else { return }
        SessionState.shared.migrationRunning = true
        let ok = await MigrationCoordinator.shared.runIfNeeded(ownerPhone: cur.userPhone, ownerName: cur.userName)
        SessionState.shared.migrationRunning = false
        if !ok {
            SessionState.shared.lastMigrationError = MigrationCoordinator.shared.lastError?.localizedDescription
        }
    }

    private func handleSessionExpired() {
        SessionState.shared.sessionExpiredBanner = true
        isAuthenticated = false
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
            routes.push(.home)
        }
    }
}

#Preview {
    ContentView()
}
