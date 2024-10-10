//
//  ContentView.swift
//  Tabi
//
//  Created by Elian Richard on 19/09/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject var routes = Routes()
    @State private var isShowSplash = true
    @State var eventName: String = "Japan Trip"
    
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
                case .EventInviteView:
                    EventInviteView()
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
        .environmentObject(routes)
    }
}

#Preview {
    ContentView()
        .environmentObject(EventViewModel())
        .environmentObject(EventInviteViewModel())
}
