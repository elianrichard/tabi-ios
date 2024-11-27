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
            LottieView(animation: .named("NoExpenses"))
                .looping()
                .frame(width: 300, height: 300)
            Text("We don't have any\nexpenses yet...")
                .multilineTextAlignment(.center)
                .font(.tabiSubtitle)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
