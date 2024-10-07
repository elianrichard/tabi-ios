//
//  HomeView.swift
//  Tabi
//
//  Created by Elian Richard on 03/10/24.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var routes: Routes
    @StateObject var homeViewModel = HomeViewModel()
    
    var body: some View {
        VStack (spacing: 20) {
            Text("HomeView")
            Text("\(homeViewModel.text)")
            Button {
                routes.navigate(to: .SwiftDataTestingView)
            } label: {
                Text("Go To SwiftDataTestView")
            }
            Button {
                routes.navigate(to: .ExpensesView)
            } label: {
                Text("Edit view model text")
            }
        }
    }
}

#Preview {
    HomeView()
}
