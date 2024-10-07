//
//  EventExpenseView.swift
//  Tabi
//
//  Created by Elian Richard on 07/10/24.
//

import SwiftUI

struct EventExpenseView: View {
    var body: some View {
        ScrollView (showsIndicators: false) {
            VStack {
                EventDetailCardView()
                EventDetailCardView()
                EventDetailCardView()
                EventDetailCardView()
                EventDetailCardView()
            }
        }
    }
}

#Preview {
    EventExpenseView()
}
