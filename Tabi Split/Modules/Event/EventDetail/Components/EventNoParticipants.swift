//
//  EventNoParticipants.swift
//  Tabi Split
//
//  Created by Elian Richard on 28/10/24.
//

import SwiftUI

struct EventNoParticipants : View {
    var body: some View {
        VStack (alignment: .center, spacing: 36) {
            Image(.eventOneParticipant)
                .resizable()
                .scaledToFit()
                .frame(width: 240, height: 240)
            Text("You’re the only participant here")
                .font(.tabiSubtitle)
            Button {
                print("invite friend")
            } label: {
                Text("+ Invite your friends")
                    .font(.tabiHeadline)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
