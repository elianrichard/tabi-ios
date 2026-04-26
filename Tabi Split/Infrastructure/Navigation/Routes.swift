//
//  Routes.swift
//  Tabi
//
//  Created by Elian Richard on 03/10/24.
//

import SwiftUI

enum AppRoute: Hashable {
    case home
    case inbox
    case swiftDataTesting
    case addExpense
    case expenseAddItems
    case expenseAssign
    case expenseResult
    case eventForm
    case login
    case register
    case eventDetail
    case eventInvite
    case eventSummaryDetail
    case eventSettlement
    case settlementPaymentMethod
    case settlementOptimization
    case settlementConfirmation
    case settlementReceipt
    case settlementUpload
    case profile
    case editProfile
    case paymentMethods
    case receiptUploadReview
}

extension AppRoute {
    static var HomeView: AppRoute { .home }
    static var InboxView: AppRoute { .inbox }
    static var SwiftDataTestingView: AppRoute { .swiftDataTesting }
    static var AddExpenseView: AppRoute { .addExpense }
    static var ExpenseAddItemsView: AppRoute { .expenseAddItems }
    static var ExpenseAssignView: AppRoute { .expenseAssign }
    static var ExpenseResultView: AppRoute { .expenseResult }
    static var EventFormView: AppRoute { .eventForm }
    static var LoginView: AppRoute { .login }
    static var RegisterView: AppRoute { .register }
    static var EventDetailView: AppRoute { .eventDetail }
    static var EventInviteView: AppRoute { .eventInvite }
    static var EventSummaryDetailView: AppRoute { .eventSummaryDetail }
    static var EventSettlementView: AppRoute { .eventSettlement }
    static var SettlementPaymentMethodView: AppRoute { .settlementPaymentMethod }
    static var SettlementOptimizationView: AppRoute { .settlementOptimization }
    static var SettlementConfirmationView: AppRoute { .settlementConfirmation }
    static var SettlementReceiptView: AppRoute { .settlementReceipt }
    static var SettlementUploadView: AppRoute { .settlementUpload }
    static var Profile: AppRoute { .profile }
    static var EditProfile: AppRoute { .editProfile }
    static var PaymentMethods: AppRoute { .paymentMethods }
    static var ReceiptUploadReview: AppRoute { .receiptUploadReview }
}

struct AppRouteDestinationView: View {
    let route: AppRoute
    
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

@Observable final class AppRouter {
    typealias Destination = AppRoute
    
    var navPath = NavigationPath()
    
    func push(_ route: AppRoute) {
        navPath.append(route)
    }
    
    func pushMany(_ routes: [AppRoute]) {
        routes.forEach { navPath.append($0) }
    }
    
    func pop() {
        guard !navPath.isEmpty else {
            return
        }
        navPath.removeLast()
    }
    
    func popToRoot() {
        guard !navPath.isEmpty else {
            return
        }
        navPath.removeLast(navPath.count)
    }
    
    func replaceStack(with routes: [AppRoute]) {
        navPath = NavigationPath()
        pushMany(routes)
    }
    
    func navigate(to destination: Destination) {
        push(destination)
    }
    
    func navigateBack() {
        pop()
    }
    
    func navigateToRoot() {
        popToRoot()
    }
}

typealias Routes = AppRouter
