//
//  LoadingViewModel.swift
//  Tabi Split
//
//  Created by Elian Richard on 11/12/24.
//

import SwiftUI

@Observable
@MainActor
final class LoadingViewModel {
    static let shared = LoadingViewModel()

    var isLoading: Bool = false
    private var activeCount: Int = 0

    func toggleIsLoading() {
        isLoading.toggle()
    }

    func beginRequest() {
        activeCount += 1
        isLoading = activeCount > 0
    }

    func endRequest() {
        activeCount = max(0, activeCount - 1)
        isLoading = activeCount > 0
    }
}
