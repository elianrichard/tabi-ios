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

enum SheetRoute: Hashable {}

@Observable final class Router {
    var path: [AppRoute] = []
    var sheet: SheetRoute?

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else {
            return
        }
        path.removeLast()
    }

    func popToRoot() {
        path.removeAll()
    }
}
