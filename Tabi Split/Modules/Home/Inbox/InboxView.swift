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
            ScrollView {
                VStack (spacing: .spacingTight) {
                    ForEach (inboxViewModel.inboxList) { inbox in
                        InboxCard(inboxItem: inbox)
                    }
                }
                .padding(.horizontal)
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
