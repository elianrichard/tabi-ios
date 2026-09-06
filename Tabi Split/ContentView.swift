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

        // Guests are now server-backed accounts with a real token, so they take the
        // same token + probeSession path as any signed-in user — no guest bypass.
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
        } catch {
            sessionState.isAuthenticated = false
            SessionState.shared.sessionExpiredBanner = true
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
        print("[Deeplink] received url=\(url.absoluteString)")
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            print("[Deeplink] Invalid URL")
            return
        }

        // Universal Link: https://tabisplit.my.id/join?token=<signed invite token>.
        if url.scheme == "https", components.host == ENV.DEEPLINK_HOST, components.path == "/join" {
            guard let token = components.queryItems?.first(where: { $0.name == "token" })?.value else {
                print("invite token not found")
                return
            }
            joinEventByToken(token)
            return
        }

        // Custom-scheme links (tabisplit://...). Web pages can trigger these to
        // launch the installed app directly from Safari, which a Universal Link
        // can't do from the page it's already showing.
        guard url.scheme == ENV.DEEPLINK_SCHEME else {
            return
        }
        switch components.host {
        // tabisplit://join?token=<signed invite token> — the "Open in Tabi"
        // button on the web /join page.
        case "join":
            guard let token = components.queryItems?.first(where: { $0.name == "token" })?.value else {
                print("invite token not found")
                return
            }
            joinEventByToken(token)
        // Legacy: tabisplit://join-event?event-id=<raw eventId> (QR codes, old links).
        case "join-event":
            guard let eventId = components.queryItems?.first(where: { $0.name == "event-id" })?.value else {
                print("eventId not found")
                return
            }
            joinEventByEventId(eventId)
        default:
            print("Unknown URL action!")
        }
    }

    private func joinEventByToken(_ token: String) {
        print("[Deeplink] joinEventByToken token=\(token)")
        Task {
            let eventId: String
            do {
                eventId = try await EventService.shared.joinEventByToken(token: token)
                print("[Deeplink] joinEventByToken success eventId=\(eventId)")
            } catch {
                // Swallow here: APIService.notifyError already surfaced the backend
                // message ("User already joined event" / "Invite link expired or
                // invalid") in the global error dialog for any non-401 error.
                print("[Deeplink] Join by token failed: \(error)")
                // No event to open — just land on Home.
                router.popToRoot()
                return
            }
            await openJoinedEvent(eventId: eventId)
        }
    }

    // After a successful join, pull the freshly-joined event into local storage
    // (same refresh Home does on appear) and navigate straight to its detail
    // view. Detail is pushed on top of the Home root, so Back returns to Home.
    @MainActor
    private func openJoinedEvent(eventId: String) async {
        print("[Deeplink] openJoinedEvent eventId=\(eventId)")
        profileViewModel.refreshUserData()
        _ = await HomeViewModel().refreshEventData(
            currentUser: profileViewModel.user,
            isShowLoading: Bindable(loadingViewModel).isLoading
        )

        router.popToRoot()
        let allEvents = SwiftDataService.shared.fetchAllEvents() ?? []
        print("[Deeplink] openJoinedEvent after refresh, \(allEvents.count) events locally, ids=\(allEvents.compactMap { $0.eventId })")
        if let event = allEvents.first(where: { $0.eventId == eventId }) {
            print("[Deeplink] openJoinedEvent found event, pushing detail")
            eventViewModel.selectedEvent = event
            router.push(.eventDetail)
        } else {
            print("[Deeplink] openJoinedEvent event NOT found locally after refresh — nothing to push")
        }
    }

    private func joinEventByEventId(_ eventId: String) {
        // Fast local-dedupe path: if the event is already joined, surface the same
        // dialog the backend would (409) rather than silently returning.
        if let events = SwiftDataService.shared.fetchAllEvents(),
           events.contains(where: { $0.eventId == eventId }) {
            ErrorDialogViewModel.shared.show("User already joined event")
            return
        }

        Task {
            do {
                try await EventService.shared.joinEvent(eventId: eventId)
            } catch {
                // notifyError already showed the dialog for non-401 errors.
                print("Join event failed: \(error)")
                router.popToRoot()
                return
            }
            await openJoinedEvent(eventId: eventId)
        }
    }
}

#Preview {
    ContentView()
}
