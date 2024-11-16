//
//  InboxView.swift
//  Tabi Split
//
//  Created by Elian Richard on 07/11/24.
//

import SwiftUI

struct InboxView : View {
    @State private var inboxViewModel = InboxViewModel()
    
    var body: some View {
        VStack (spacing: 0) {
            TopNavigation(title: "Inbox")
                .padding(.horizontal)
            if (inboxViewModel.inboxList.count != 0) {
                ScrollView {
                    LazyVStack (spacing: .spacingTight) {
                        ForEach (inboxViewModel.inboxList) { inbox in
                            InboxCard(inboxItem: inbox)
                        }
                    }
                    .padding(.horizontal)
                }
            } else {
                VStack (spacing: .spacingLarge) {
                    Image(.inboxEmptyView)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .offset(x: 30)
                    VStack (spacing: .spacingMedium) {
                        Text("No Notification Yet")
                            .font(.tabiSubtitle)
                        Text("When you get notifications,\nthey'll show up here")
                            .font(.tabiHeadline)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            Spacer()
        }
        .ignoresSafeArea()
        .padding(.top)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    InboxView()
        .environment(Routes())
}
