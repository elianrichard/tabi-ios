//
//  EventInviteShareButtonView.swift
//  Tabi
//
//  Created by Elian Richard on 08/10/24.
//

import SwiftUI

struct EventInviteShareButtonView: View {
    var text: String
    
    var body: some View {
        Button {
            print(text)
        } label: {
            Text(text)
                .padding(.horizontal)
                .foregroundColor(.black)
                .font(.subheadline)
                .frame(maxWidth: .infinity, maxHeight: 50)
                .background(Color(UIColor(hex: "#D9D9D9")))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    EventInviteShareButtonView(text: "Invite QR Code")
}
