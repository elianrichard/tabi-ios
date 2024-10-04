//
//  EventCardView.swift
//  Tabi
//
//  Created by Elian Richard on 04/10/24.
//

import SwiftUI

struct EventCardView : View {
    var body : some View {
        VStack (alignment: .leading, spacing: 10) {
            HStack (spacing: 12) {
                Circle()
                    .fill(Color(UIColor(hex: "#D9D9D9")))
                    .frame(width: 40)
                VStack (alignment: .leading, spacing: 8) {
                    Text("Text")
                        .font(.body)
                    HStack (spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 10)
                        Text("Ongoing Event")
                            .font(.caption)
                    }
                }
            }
            Rectangle()
                .fill(Color(UIColor(hex: "#D9D9D9")))
                .frame(height: 1)
            HStack (spacing: 32) {
                HStack (spacing: -20) {
                    Circle()
                        .fill(Color(UIColor(hex: "#C2C2C2")))
                        .frame(width: 40)
                    Circle()
                        .fill(Color(UIColor(hex: "#D3D3D3")))
                        .frame(width: 40)
                    Circle()
                        .fill(Color(UIColor(hex: "#D9D9D9")))
                        .frame(width: 40)
                    
                }
                Text("New Event")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor(hex: "#EBEBEB")))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    EventCardView()
}
