//
//  EventNoParticipants.swift
//  Tabi Split
//
//  Created by Elian Richard on 28/10/24.
//

import SwiftUI

struct EventNoParticipants : View {
    @Environment(Routes.self) var routes
    
    var body: some View {
        VStack (alignment: .center, spacing: 36) {
            Image(.eventOneParticipant)
                .resizable()
                .scaledToFit()
                .frame(width: 340, height: 250)
            Text("You’re the only participant here")
                .font(.tabiSubtitle)
            Button {
                routes.navigate(to: .EventInviteView)
            } label: {
                Text("+ Invite your friends")
                    .font(.tabiHeadline)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
