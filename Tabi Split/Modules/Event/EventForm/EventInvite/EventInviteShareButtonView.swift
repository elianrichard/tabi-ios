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
    var action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
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
}

#Preview {
    EventInviteShareButtonView(text: "Invite QR Code", icon: .eyeIcon, action: {
        print("Hello")
    })
}
