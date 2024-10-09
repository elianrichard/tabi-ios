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
//                if isShowSplash {
//                    SplashView()
//                        .onAppear {
//                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
//                                withAnimation {
//                                    isShowSplash = false
//                                }
//                            }
//                        }
//                } else {
                HomeView()
//                }
            }
            .navigationDestination(for: Routes.Destination.self) { destination in
                switch destination {
                case .HomeView:
                    HomeView()
                case .EventFormView:
                    EventFormView()
                        .navigationBarBackButtonHidden(true)
                case .SwiftDataTestingView:
                    SwiftDataTestingView()
//                        .navigationBarBackButtonHidden(true)
//                        .toolbar(.hidden)
                case .LoginView:
                    LoginView()
                case .RegisterView:
                    RegisterView()
                case .ExpensesView:
                    ExpenseView()
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
}
