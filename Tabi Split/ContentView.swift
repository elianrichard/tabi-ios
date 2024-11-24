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
//                    EmptyView()
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
}

#Preview {
    ContentView()
}
