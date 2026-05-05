//
//  EventNoParticipants.swift
//  Tabi Split
//
//  Created by Elian Richard on 28/10/24.
//

import SwiftUI
import Lottie

struct EventNoParticipants : View {
    @Environment(Router.self) var router
    @Environment(EventViewModel.self) var eventViewModel
    
    var body: some View {
        VStack (alignment: .center, spacing: 36) {
            LottieView(animation: .named("EventAlone"))
                .looping()
                .resizable()
                .frame(width: 340, height: 250)
                .scaledToFit()
            Text("Zzz, you’re the only one here... ")
                .font(.tabiSubtitle)
            Button {
                eventViewModel.isDirectInvite = true
                router.push(.eventInvite)
            } label: {
                Text("+ Add Participants")
                    .font(.tabiHeadline)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
