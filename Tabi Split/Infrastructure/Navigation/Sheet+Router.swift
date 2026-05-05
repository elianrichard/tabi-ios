//
//  Sheet+Router.swift
//  Tabi Split
//
//  Created by Elian Richard on 26/04/26.
//

import SwiftUI

extension Router {
    func present(_ sheet: SheetRoute) {
        self.sheet = sheet
    }
    
    func dismissSheet() {
        sheet = nil
    }
    
    func isPresented(_ sheet: SheetRoute) -> Bool {
        self.sheet == sheet
    }
    
    func sheetBinding(for sheet: SheetRoute) -> Binding<Bool> {
        .init(
            get: { self.isPresented(sheet) },
            set: { isPresented in
                if !isPresented, self.sheet == sheet {
                    self.dismissSheet()
                }
            }
        )
    }
}
