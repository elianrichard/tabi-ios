//
//  EventParticipants.swift
//  Tabi Split
//
//  Created by Elian Richard on 28/10/24.
//

import SwiftUI

struct EventParticipantsList: View {
    @Environment(EventViewModel.self) private var eventViewModel
    @Environment(Routes.self) private var routes
    
    var images: [ImageResource] = [.samplePersonProfile1, .samplePersonProfile2, .samplePersonProfile3]
    
    var body: some View {
        HStack (spacing: 4) {
            if let selectedEvent = eventViewModel.selectedEvent {
                ForEach (Array(selectedEvent.participants.enumerated()), id: \.offset) { index, person in
                    if index < 4 {
                        Circle()
                            .fill(.bgWhite)
                            .overlay {
                                Image(images.randomElement() ?? images[0])
                                    .resizable()
                                    .scaledToFill()
                                    .clipShape(Circle())
                                    .padding(2)
                            }
                            .frame(width: 40, height: 40)
                    }
                }
                if selectedEvent.participants.count > 4 {
                    Button {
                        routes.navigate(to: .EventInviteView)
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color(UIColor(hex: "#D9D9D9")))
                                .frame(width: 40)
                            Text("+\(selectedEvent.participants.count - 4)")
                                .foregroundStyle(.textBlack)
                        }
                    }
                }
            }
        }
        .padding(.top, -40)
    }
}
