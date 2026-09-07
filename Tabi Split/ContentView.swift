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

    // A deeplink invite token that arrived before the session was ready (cold
    // launch via link, or mid-auth). Held here and processed once authenticated,
    // so the join isn't dropped by the auth/navigation race.
    @State private var pendingInviteToken: String?

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
        .onChange(of: sessionState.isAuthenticated) { _, _ in
            // Backup drain: process a queued invite token once the session is ready
            // (checkAuthentication also drains it directly).
            drainPendingInviteTokenIfNeeded()
        }
        .onOpenURL { incomingURL in
            // Custom-scheme links (tabisplit://…) and, on some launch paths,
            // Universal Links arrive here. Let GoogleSignIn claim its OAuth
            // callback URL first, then route the rest ourselves.
            if GIDSignIn.sharedInstance.handle(incomingURL) {
                return
            }
            handleIncomingURL(incomingURL)
        }
        // Universal Links (https://tabisplit.my.id/join?…) are delivered as a
        // browsing-web user activity, NOT always via onOpenURL — so handle that
        // path too, otherwise a QR/link that opens the app does nothing.
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
            if let url = activity.webpageURL {
                handleIncomingURL(url)
            }
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
            // Deterministically drain a queued deeplink token here, in case the
            // isAuthenticated onChange observer wasn't registered in time on a cold
            // launch (the QR/link that launched the app can arrive before body is
            // fully set up).
            drainPendingInviteTokenIfNeeded()
        } catch {
            sessionState.isAuthenticated = false
            SessionState.shared.sessionExpiredBanner = true
        }
    }

    private func drainPendingInviteTokenIfNeeded() {
        guard sessionState.isAuthenticated, let token = pendingInviteToken else { return }
        pendingInviteToken = nil
        joinEventByToken(token)
    }

    private func handleSessionExpired() {
        SessionState.shared.sessionExpiredBanner = true
        sessionState.isAuthenticated = false
        // Root swaps back to LoginView; clear any pushed screens so stale
        // authed views do not linger on top of the login root.
        router.popToRoot()
    }
    
    
    private func handleIncomingURL(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return
        }

        // Universal Link: https://tabisplit.my.id/join?token=<signed invite token>.
        if url.scheme == "https", components.host == ENV.DEEPLINK_HOST, components.path == "/join" {
            guard let token = components.queryItems?.first(where: { $0.name == "token" })?.value else {
                return
            }
            handleInviteToken(token)
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
                return
            }
            handleInviteToken(token)
        // Legacy: tabisplit://join-event?event-id=<raw eventId> (QR codes, old links).
        case "join-event":
            guard let eventId = components.queryItems?.first(where: { $0.name == "event-id" })?.value else {
                return
            }
            joinEventByEventId(eventId)
        default:
            break
        }
    }

    // Entry point for an invite token from a deeplink. If the session isn't ready
    // yet (cold launch via link, or auth still in flight), stash the token and let
    // the isAuthenticated onChange process it once ready — otherwise the join
    // races auth/navigation and intermittently does nothing.
    private func handleInviteToken(_ token: String) {
        guard sessionState.isAuthenticated else {
            pendingInviteToken = token
            return
        }
        joinEventByToken(token)
    }

    private func joinEventByToken(_ token: String) {
        Task {
            let eventId: String
            do {
                eventId = try await EventService.shared.joinEventByToken(token: token)
            } catch {
                // Swallow here: APIService.notifyError already surfaced the backend
                // message ("User already joined event" / "Invite link expired or
                // invalid") in the global error dialog for any non-401 error.
                print("Join by token failed: \(error)")
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
        profileViewModel.refreshUserData()
        _ = await HomeViewModel().refreshEventData(
            currentUser: profileViewModel.user,
            isShowLoading: Bindable(loadingViewModel).isLoading
        )

        router.popToRoot()
        if let event = SwiftDataService.shared.fetchAllEvents()?
            .first(where: { $0.eventId == eventId }) {
            eventViewModel.selectedEvent = event
            router.push(.eventDetail)
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
