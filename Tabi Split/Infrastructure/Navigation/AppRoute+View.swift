//
//  AppRoute+View.swift
//  Tabi Split
//
//  Created by OpenAI Codex on 26/04/26.
//

import SwiftUI

struct AppDestinationView: View {
    let route: AppRoute

    @ViewBuilder
    var body: some View {
        switch route {
        case .home:
            HomeView()
        case .inbox:
            InboxView()
        case .eventForm:
            EventFormView()
        case .eventDetail:
            EventDetailView()
        case .eventInvite:
            EventInviteView()
        case .swiftDataTesting:
            SwiftDataTestingView()
        case .login:
            LoginView()
        case .register:
            RegisterView()
        case .addExpense:
            AddExpenseView()
        case .expenseAddItems:
            ExpenseAddItemsView()
        case .expenseAssign:
            ExpenseAssignView()
        case .expenseResult:
            ExpenseResultView()
        case .eventSummaryDetail:
            EventSummaryDetailView()
        case .eventSettlement:
            EventSettlementView()
        case .settlementPaymentMethod:
            SettlementPaymentMethodView()
        case .settlementOptimization:
            SettlementOptimizationView()
        case .settlementReceipt:
            SettlementReceiptView()
        case .settlementConfirmation:
            SettlementConfirmationView()
        case .settlementUpload:
            SettlementUploadView()
        case .profile:
            ProfileView()
        case .editProfile:
            EditProfileView()
        case .paymentMethods:
            PaymentMethodView()
        case .receiptUploadReview:
            ReceiptImageReviewView()
        }
    }
}

extension View {
    func appNavigationDestinations() -> some View {
        navigationDestination(for: AppRoute.self) { route in
            AppDestinationView(route: route)
        }
    }
}
