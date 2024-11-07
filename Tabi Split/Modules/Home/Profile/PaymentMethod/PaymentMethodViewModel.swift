//
//  PaymentMethodViewModel.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 04/11/24.
//

import Foundation
import SwiftUI

@Observable
class PaymentMethodViewModel{
    var toggleDetailBankSheet: Bool = false
    var settingsDetent = PresentationDetent.large
    var contentHeight: CGFloat = 0
    var idToBeEdited: UUID?
}
