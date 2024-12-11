//
//  LoadingViewModel.swift
//  Tabi Split
//
//  Created by Elian Richard on 11/12/24.
//

import SwiftUI

@Observable
final class LoadingViewModel {
    var isLoading: Bool = false
    
    func toggleIsLoading() {
        isLoading.toggle()
    }
}
