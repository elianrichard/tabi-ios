//
//  ContentView.swift
//  Tabi
//
//  Created by Elian Richard on 19/09/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var router = Router()
    @State private var eventViewModel = EventViewModel()
    @State private var eventInviteViewModel = EventInviteViewModel()
    @State private var eventExpenseViewModel = EventExpenseViewModel()
    @State private var eventSettlementViewModel = EventSettlementViewModel()
    @State private var profileViewModel = ProfileViewModel()
    @State private var loadingViewModel = LoadingViewModel()
    
    @State private var isAuthenticated = false
    
    var body: some View {
        ZStack {
            NavigationStack (path: $router.path) {
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
                .appNavigationDestinations()
            }
            
            if (loadingViewModel.isLoading) {
                LoadingView()
            }
            
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
            checkAuthentication()
        }
        .onOpenURL { incomingURL in
            handleIncomingURL(incomingURL)
        }
    }
    
    private func checkAuthentication() {
        let isAccessTokenAvailable: Bool
        do {
            let accessToken = try KeychainService.shared.getAccessToken()
            isAccessTokenAvailable = !accessToken.isEmpty
        } catch {
            isAccessTokenAvailable = false
        }
        isAuthenticated = (isAccessTokenAvailable || SwiftDataService.shared.getCurrentUser() != nil)
    }
    
    
    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "tabisplit" else {
            return
        }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return }
        guard let action = components.host, action == "join-event" else { return }
        guard let eventId = components.queryItems?.first(where: { $0.name == "event-id" })?.value else { return }
        if let events = SwiftDataService.shared.fetchAllEvents(), events.contains(where: { $0.eventId == eventId }) {
            return
        }

        Task {
            if !profileViewModel.isGuest {
                do {
                    try await EventService.shared.joinEvent(eventId: eventId)
                } catch { }
            }
            router.push(.home)
        }
    }
}

#Preview {
    ContentView()
}
