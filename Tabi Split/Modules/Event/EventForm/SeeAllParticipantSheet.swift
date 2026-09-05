//
//  SeeAllParticipantSheet.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 12/11/24.
//

import Foundation
import SwiftUI

struct SeeAllParticipantSheet: View {
    @Environment(Router.self) private var router
    @Environment(EventViewModel.self) private var eventViewModel
    @Environment(EventInviteViewModel.self) private var eventInviteViewModel
    @Environment(ProfileViewModel.self) private var profileViewModel

    @Binding var isPresented: Bool
    @State var nameToBeSearched: String = ""
    var participantsList: [UserData] = []
    // Controls whether the pinned "Add / Edit Participant" button is shown.
    // Off by default so callers that only display the list (e.g. EventFormView)
    // are unaffected; EventDetailView opts in.
    var showAddParticipantButton: Bool = false

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
                                    UserCard(user: user,
                                             isShowOwnerText: user.userId == eventViewModel.selectedEvent?.creatorId,
                                             onEdit: (eventViewModel.isUserCreator && !profileViewModel.isCurrentUser(user)) ? {
                                                 eventInviteViewModel.editingParticipant = user
                                                 isPresented = false
                                                 router.push(.editParticipant)
                                             } : nil)
                                }
                        }
                    }
                }
                // Pinned outside the ScrollView so it stays at the bottom of the sheet.
                // Only the event creator can add/edit participants.
                if showAddParticipantButton && eventViewModel.isUserCreator {
                    CustomButton(text: "Add / Edit Participant") {
                        isPresented = false
                        // Direct invite so EventInviteView persists changes on Save,
                        // and its back button returns to the presenting EventDetailView.
                        eventViewModel.isDirectInvite = true
                        router.push(.eventInvite)
                    }
                }
            }
        }
    }
}

#Preview {
    SeeAllParticipantSheet(isPresented: .constant(false ))
        .environment(Router())
        .environment(EventViewModel())
        .environment(EventInviteViewModel())
        .environment(ProfileViewModel())
}
