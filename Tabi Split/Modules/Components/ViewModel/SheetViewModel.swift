//
//  SheetViewModel.swift
//  Tabi Split
//
//  Created by Elian Richard on 19/11/24.
//

import SwiftUI

@Observable
final class SheetViewModel<T: Equatable> {
    var currentSheet: T? = nil
    var sheetHeight: CGFloat = 0
    
    func setSheet(_ sheet: T) {
        currentSheet = sheet
    }
    
    func clearSheet() {
        currentSheet = nil
    }
    
    func isPresented(_ sheet: T) -> Bool {
        return currentSheet == sheet
    }
    
    func getIsPresentedBinding(_ sheet: T) -> Binding<Bool> {
        return .init(get: { self.isPresented(sheet) },
                     set: { if !$0 { self.clearSheet() }}
        )
    }
}
