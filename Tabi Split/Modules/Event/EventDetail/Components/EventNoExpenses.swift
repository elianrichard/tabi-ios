//
//  EventNoExpenses.swift
//  Tabi Split
//
//  Created by Elian Richard on 28/10/24.
//

import SwiftUI
import Lottie

struct EventNoExpenses: View {
    var body: some View {
        VStack (alignment: .center, spacing: 36) {
            LottieView(animation: .named("NoExpense"))
                .looping()
                .resizable()
                .frame(width: 200, height: 200)
                .scaledToFit()
            Text("We don't have any\nexpenses yet...")
                .multilineTextAlignment(.center)
                .font(.tabiSubtitle)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
