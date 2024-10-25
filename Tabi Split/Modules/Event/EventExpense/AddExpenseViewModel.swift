//
//  AddExpenseViewModel.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 25/10/24.
//

import Foundation
import SwiftUI

@Observable
class AddExpenseViewModel{
    var toggleSeeAll: Bool = false
    var settingsDetent = PresentationDetent.medium
    var placeholderPrice: String = ""
    var isParticipantsError: Bool = false
}
