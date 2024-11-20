//
//  SeeAllParticipantSheet.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 12/11/24.
//

import Foundation
import SwiftUI

struct SeeAllParticipantSheet: View {
    @Environment(EventViewModel.self) private var eventViewModel
    @Environment(ProfileViewModel.self) private var profileViewModel
    
    @Binding var isPresented: Bool
    @State var nameToBeSearched: String = ""
    var participantsList: [UserData] = []
    
    var body: some View {
        CustomSheet (xToggleBinding: $isPresented) {
            VStack(spacing: .spacingMedium) {
                Text("All Participants")
                    .font(.tabiTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                SearchInput(text: $nameToBeSearched, placeholder: "Search")
                ScrollView{
                    LazyVStack (spacing: .spacingTight){
                        Divided{
                            if nameToBeSearched.isEmpty || profileViewModel.user.name.lowercased().contains(nameToBeSearched.lowercased()) {
                                UserCard(user: profileViewModel.user, isShowYouText: true)
                            }
                            ForEach (
                                participantsList.filter {
                                    (nameToBeSearched.isEmpty || $0.name.lowercased().contains(nameToBeSearched.lowercased())) && !profileViewModel.isCurrentUser($0)
                                }.sorted(by: { $0.name < $1.name }) ) { user in
                                    UserCard(user: user)
                                }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    SeeAllParticipantSheet(isPresented: .constant(false ))
        .environment(EventViewModel())
}
