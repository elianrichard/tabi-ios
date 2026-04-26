//
//  EventFormView.swift
//  Tabi
//
//  Created by Elian Richard on 06/10/24.
//

import SwiftUI

struct EventFormView: View {
    @Environment(Router.self) private var router
    @Environment(EventViewModel.self) private var eventViewModel
    @Environment(EventInviteViewModel.self) private var eventInviteViewModel
    @Environment(ProfileViewModel.self) private var profileViewModel
    
    @State var isEdit: Bool = false
    @State var isShowEditIconSheet: Bool = false
    @State var toggleSeeAllParticipantsSheet: Bool = false
    @State var participantsList: [UserData] = []
    
    @FocusState private var focusedField: FocusField?
    
    var body : some View {
        VStack {
            TopNavigation(title: isEdit ? "Edit Event" : "Create Event")
            VStack (spacing: .spacingMedium) {
                ZStack {
                    Button {
                        isShowEditIconSheet = true
                    } label: {
                        Image(eventViewModel.eventIcon.resource)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 88, height: 88)
                            .clipShape(Circle())
                            .overlay {
                                VStack {
                                    Circle()
                                        .fill(.buttonBlue)
                                        .strokeBorder(.bgWhite, lineWidth: 1)
                                        .frame(width: 28, height: 28)
                                        .overlay {
                                            Icon(systemName: "pencil", color: .textWhite, size: 12)
                                        }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                            }
                    }
                    .frame(maxWidth: .infinity)
                }
                
                ScrollView (showsIndicators: false) {
                    VStack (alignment: .leading, spacing: .spacingRegular) {
                        InputWithLabel(label: "Event Name", placeholder: "Event name", text: Bindable(eventViewModel).eventName, focusedField: $focusedField, focusCase: .field1)
                        if (isEdit) {
                            VStack (alignment: .leading, spacing: .spacingTight) {
                                Text("Participants (\((eventInviteViewModel.selectedContacts).count))")
                                    .font(.tabiBody)
                                VStack (alignment: .leading, spacing: .spacingTight) {
                                    Divided {
                                        Button {
                                            router.push(.eventInvite)
                                        } label: {
                                            HStack(spacing: .spacingTight) {
                                                Icon(systemName: "plus", color: .buttonBlue, size: 20)
                                                    .frame(width: 40, height: 40)
                                                    .addDashedCircleBorder()
                                                Text("Add")
                                                    .font(.tabiBody)
                                                    .foregroundColor(.buttonBlue)
                                                Spacer()
                                            }
                                            .contentShape(Rectangle())
                                        }
                                        
                                        ForEach (participantsList.prefix(4)) { user in
                                            UserCard(user: user, isShowYouText: true)
                                        }
                                        
                                        if participantsList.count > 4 {
                                            Button{
                                                toggleSeeAllParticipantsSheet.toggle()
                                            } label: {
                                                HStack{
                                                    Text("See All")
                                                        .font(.tabiBody)
                                                        .foregroundColor(.buttonBlue)
                                                    Spacer()
                                                    Icon(systemName: "chevron.right", color: .buttonBlue, size: 16)
                                                }
                                                .padding(.vertical, .spacingSmall)
                                                .contentShape(Rectangle())
                                            }
                                        }
                                    }
                                }
                                .padding(.spacingTight)
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                                .background(.bgWhite)
                                .clipShape(RoundedRectangle(cornerRadius: .radiusMedium))
                                .overlay {
                                    RoundedRectangle(cornerRadius: .radiusMedium)
                                        .stroke(.bgGreyOverlay, lineWidth: 0.5)
                                        .padding(0.5)
                                }
                            }
                        }
                    }
                }
            }
            
            CustomButton(text: eventViewModel.isApiCallLoading ? "Loading..." : (isEdit ? "Save" : "Create"),
                         isEnabled: !eventViewModel.isApiCallLoading && eventViewModel.eventName != "") {
                Task {
                    if isEdit {
                        if await eventViewModel.handleEditEvent(selectedContacts: eventInviteViewModel.selectedContacts, currentUser: profileViewModel.user, isGuest: profileViewModel.isGuest) {
                            router.pop()
                        }
                    } else {
                        if await eventViewModel.handleCreateEvent(currentUser: profileViewModel.user, isGuest: profileViewModel.isGuest) {
                            router.pop()
                        }
                    }
                }
            }
        }
        .onAppear {
            if eventViewModel.selectedEvent != nil {
                isEdit = true
                var participants = eventInviteViewModel.selectedContacts.filter{ !profileViewModel.isCurrentUser($0) }
                participants.sort { $0.name.lowercased() < $1.name.lowercased() }
                participants.insert(profileViewModel.user, at: 0)
                participantsList = participants
            } else {
                isEdit = false
                eventInviteViewModel.searchUserText = ""
                eventInviteViewModel.selectedContacts = []
            }
        }
        .padding()
        .addBackgroundColor(.bgWhite) {
            focusedField = nil
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $isShowEditIconSheet) {
            VStack (spacing: 0) {
                SheetXButton(toggle: $isShowEditIconSheet)
                VStack (alignment: .center, spacing: .spacingSmall) {
                    VStack {
                        Text("Select Image")
                            .font(.tabiTitle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 4), spacing: .spacingRegular) {
                            ForEach(EventIconEnum.allCases) { icon in
                                Button {
                                    withAnimation (nil) {
                                        eventViewModel.eventIcon = icon
                                    }
                                } label: {
                                    Circle()
                                        .fill(icon == eventViewModel.eventIcon ? .buttonGreen : .clear)
                                        .frame(width: 78, height: 78)
                                        .overlay {
                                            Image(icon.resource)
                                                .resizable()
                                                .scaledToFill()
                                                .clipShape(Circle())
                                                .padding(6)
                                        }
                                }
                            }
                        }
                    }
                    Spacer()
                    CustomButton(text: "Save") {
                        isShowEditIconSheet = false
                    }
                }
            }
            .padding()
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $toggleSeeAllParticipantsSheet){
            SeeAllParticipantSheet(isPresented: $toggleSeeAllParticipantsSheet, participantsList: participantsList)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    EventFormView()
        .environment(EventViewModel())
        .environment(EventInviteViewModel())
        .environment(Router())
        .environment(ProfileViewModel())
}
