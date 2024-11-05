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
    var toggleSelectBank: Bool = false
    var settingsDetent = PresentationDetent.large
    var contentHeight: CGFloat = 0
}
