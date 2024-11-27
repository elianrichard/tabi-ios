//
//  ContentView.swift
//  Tabi
//
//  Created by Elian Richard on 19/09/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var routes = Routes()
    @State private var eventViewModel = EventViewModel()
    @State private var eventInviteViewModel = EventInviteViewModel()
    @State private var eventExpenseViewModel = EventExpenseViewModel()
    @State private var eventSettlementViewModel = EventSettlementViewModel()
    @State private var profileViewModel = ProfileViewModel()
    
    @State private var isAuthenticated = false
    
    var body: some View {
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
                
                SplashView()
                    .ignoresSafeArea()
            }
            .navigationDestination(for: Routes.Destination.self) { destination in
                switch destination {
                case .HomeView:
                    HomeView()
                    
                case .InboxView:
                    InboxView()
                    
                case .EventFormView:
                    EventFormView()
                    
                case .EventDetailView:
                    EventDetailView()
                    
                case .EventInviteView:
                    EventInviteView()
                    
                case .SwiftDataTestingView:
                    SwiftDataTestingView()
                    
                case .LoginView:
                    LoginView()
                    
                case .RegisterView:
                    RegisterView()
                    
                case .AddExpenseView:
                    AddExpenseView()
                    
                case .ExpenseAddItemsView:
                    ExpenseAddItemsView()
                    
                case .ExpenseAssignView:
                    ExpenseAssignView()
                    
                case .ExpenseResultView:
                    ExpenseResultView()
                    
                case .EventSummaryDetailView:
                    EventSummaryDetailView()
                    
                case .EventSettlementView:
                    EventSettlementView()
                    
                case .SettlementPaymentMethodView:
                    SettlementPaymentMethodView()
                    
                case .SettlementOptimizationView:
                    SettlementOptimizationView()
                    
                case .SettlementReceiptView:
                    SettlementReceiptView()
                    
                case .SettlementConfirmationView:
                    SettlementConfirmationView()
                    
                case .SettlementUploadView:
                    SettlementUploadView()
                    
                case .Profile:
                    ProfileView()
                    
                case .EditProfile:
                    EditProfileView()
                    
                case .PaymentMethods:
                    PaymentMethodView()
                    
                case .ReceiptUploadReview:
                    ReceiptImageReviewView()
                }
                
            }
        }
        .ignoresSafeArea(.keyboard)
        .environment(routes)
        .environment(eventViewModel)
        .environment(eventInviteViewModel)
        .environment(eventExpenseViewModel)
        .environment(eventSettlementViewModel)
        .environment(profileViewModel)
        .onAppear {
            checkAuthentication()
        }
        .onOpenURL { incomingURL in
            print("App was opened via URL: \(incomingURL)")
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
            routes.navigate(to: .HomeView)
        }
    }
}

#Preview {
    ContentView()
}
