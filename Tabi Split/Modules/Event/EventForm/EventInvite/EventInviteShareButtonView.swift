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
            Icon(icon)
            Text(text)
                .font(.tabiBody)
        }
            .padding(.horizontal, .spacingTight)
            .padding(.vertical, .spacingRegular)
            .foregroundColor(.textBlack)
            .font(.subheadline)
            .frame(maxWidth: .infinity)
            .background(.buttonBlueSelected)
            .clipShape(RoundedRectangle(cornerRadius: .radiusMedium))
    }
}

#Preview {
    EventInviteShareButtonView(text: "Invite QR Code", icon: .checkIcon, action: {
        print("Hello")
    })
}


