//
//  EventNoParticipants.swift
//  Tabi Split
//
//  Created by Elian Richard on 28/10/24.
//

import SwiftUI

struct EventNoParticipants : View {
    @Environment(Routes.self) var routes
    @Environment(EventViewModel.self) var eventViewModel
    
    var body: some View {
        VStack (alignment: .center, spacing: 36) {
            Image(.eventOneParticipant)
                .resizable()
                .scaledToFit()
                .frame(width: 340, height: 250)
            Text("Zzz, you’re the only one here... ")
                .font(.tabiSubtitle)
            Button {
                eventViewModel.isDirectInvite = true
                routes.navigate(to: .EventInviteView)
            } label: {
                Text("+ Add Participants")
                    .font(.tabiHeadline)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
