//
//  ContentView.swift
//  Tabi
//
//  Created by Elian Richard on 19/09/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var routes = Routes()
    @State private var eventViewModel = EventViewModel()
    
    var body: some View {
        NavigationStack (path: $routes.navPath) {
            VStack {
                HomeView()
            }
            .navigationDestination(for: Routes.Destination.self) { destination in
                switch destination {
                case .HomeView:
                    HomeView()
                case .EventFormView:
                    EventFormView()
                case .EventDetailView:
                    EventDetailView()
                case .SwiftDataTestingView:
                    SwiftDataTestingView()
                case .LoginView:
                    LoginView()
                case .RegisterView:
                    RegisterView()
                case .AddExpenseView:
                    AddExpenseView()
                case .ExpenseSplitView:
                    ExpenseSplitView()
                }
            }
        }
        .ignoresSafeArea(.keyboard)
        .environment(routes)
        .environment(eventViewModel)
    }
}

#Preview {
    ContentView()
}
