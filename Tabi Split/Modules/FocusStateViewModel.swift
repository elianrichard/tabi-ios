//
//  FocusStateViewModel.swift
//  Tabi Split
//
//  Created by Elian Richard on 15/11/24.
//

import SwiftUI

enum InputFields {
    case field1, field2, field3
}

@Observable
final class FocusStateViewModel {
    var focusedState: InputFields?

    func focusField(_ field: InputFields) {
        focusedState = field
    }
    
    func clearFocus() {
        focusedState = nil
    }
}
