//
//  Routes.swift
//  Tabi
//
//  Created by Elian Richard on 03/10/24.
//

import SwiftUI

@Observable class Routes {
    var navPath = NavigationPath()
    
    public enum Destination {
        case HomeView,
             InboxView,
             SwiftDataTestingView,
             AddExpenseView,
             ExpenseAddItemsView,
             ExpenseAssignView,
             ExpenseResultView,
             EventFormView,
             LoginView,
             RegisterView,
             EventDetailView,
             EventInviteView, 
             EventSummaryDetailView, 
             EventSettlementView, 
             SettlementPaymentMethodView, 
             SettlementOptimizationView, 
             SettlementConfirmationView, 
             SettlementReceiptView,
             SettlementUploadView,
             Profile,
             EditProfile,
             PaymentMethods,
             ReceiptUploadReview
    }
    
    func navigate(to destination: Destination) {
        navPath.append(destination)
    }
    
    func mutlipleNavigate(to destinations: [Destination]) {
        for destination in destinations {
            navPath.append(destination)
        }
    }
    
    func navigateBack() {
        navPath.removeLast()
    }
    
    func navigateToRoot() {
        navPath.removeLast(navPath.count)
    }
}
