//
//  EventBanner.swift
//  Tabi Split
//
//  Created by Elian Richard on 28/10/24.
//

import SwiftUI

struct EventBanner: View {
    var resource: ImageResource
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.black.opacity(0.5))
                .overlay{
                    ZStack {
                        Image(resource)
                            .resizable()
                            .scaledToFill()
                        Color(.black)
                            .opacity(0.35)
                        VStack {
                            Spacer()
                            LinearGradient(colors: [.black, .black.opacity(0)], startPoint: .bottom, endPoint: .top)
                                .frame(maxHeight: 50)
                        }
                    }
                }
                .clipped()
            VStack {
                Spacer()
                Image(.eventBannerCircle)
                    .resizable()
                    .frame(maxWidth: .infinity, maxHeight: 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 180)
    }
}
