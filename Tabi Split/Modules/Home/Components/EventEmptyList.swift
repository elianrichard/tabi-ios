//
//  EventEmptyList.swift
//  Tabi Split
//
//  Created by Elian Richard on 28/10/24.
//

import SwiftUI

struct EventEmptyList: View {
    var body: some View {
        VStack (alignment: .center, spacing: 36) {
            Image(.homeEmptyView)
                .resizable()
                .scaledToFit()
                .frame(width: 200)
            Text("You don't have any\nevents yet...")
                .multilineTextAlignment(.center)
                .font(.tabiTitle2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
