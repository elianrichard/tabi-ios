//
//  EventInviteShareButtonView.swift
//  Tabi
//
//  Created by Elian Richard on 08/10/24.
//

import SwiftUI

struct EventInviteShareButtonView: View {
    var text: String
    var icon: ImageResource
    var action: (() -> Void)?
    
    var body: some View {
        if let action = action {
            Button {
                action()
            } label: {
                EventInviteShareButtonViewComponent(text: text, icon: icon)
            }
        } else {
            EventInviteShareButtonViewComponent(text: text, icon: icon)
        }
    }
}

struct EventInviteShareButtonViewComponent : View {
    var text: String
    var icon: ImageResource
    var body: some View {
        VStack (spacing: .spacingSmall) {
            Icon(icon, color: .buttonBlue)
            Text(text)
                .font(.tabiBody)
        }
            .padding(.horizontal, .spacingTight)
            .padding(.vertical, .spacingRegular)
            .foregroundColor(.buttonBlue)
            .font(.subheadline)
            .frame(maxWidth: .infinity)
            .background(.bgWhite)
            .clipShape(RoundedRectangle(cornerRadius: .radiusMedium))
            .overlay {
                RoundedRectangle(cornerRadius: .radiusMedium)
                    .fill(.clear)
                    .stroke(.buttonBlue, lineWidth: 0.5)
                    .padding(0.5)
            }
    }
}

#Preview {
    EventInviteShareButtonView(text: "Invite QR Code", icon: .checkIcon, action: {
        print("Hello")
    })
}


