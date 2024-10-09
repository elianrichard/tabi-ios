//
//  Routes.swift
//  Tabi
//
//  Created by Elian Richard on 03/10/24.
//

import SwiftUI

@Observable final class Routes: ObservableObject {
    var navPath = NavigationPath()
    
    public enum Destination {
        case HomeView, SwiftDataTestingView, LoginView, RegisterView
    }
    
    func navigate(to destination: Destination) {
        navPath.append(destination)
    }
    
    func navigateBack() {
        navPath.removeLast()
    }
    
    func navigateToRoot() {
        navPath.removeLast(navPath.count)
    }
}
