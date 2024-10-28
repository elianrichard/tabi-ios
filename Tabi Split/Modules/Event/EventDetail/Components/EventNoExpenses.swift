//
//  EventNoExpenses.swift
//  Tabi Split
//
//  Created by Elian Richard on 28/10/24.
//

import SwiftUI

struct EventNoExpenses: View {
    var body: some View {
        VStack (alignment: .center, spacing: 36) {
            Image(.eventEmptyExpense)
                .resizable()
                .scaledToFit()
                .frame(width: 200)
            Text("We don't have any\nexpenses yet...")
                .multilineTextAlignment(.center)
                .font(.tabiSubtitle)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
