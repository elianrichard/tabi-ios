//
//  EventFormView.swift
//  Tabi
//
//  Created by Elian Richard on 06/10/24.
//

import SwiftUI

struct EventFormView: View {
    @Environment(Routes.self) private var routes
    @Environment(EventViewModel.self) private var eventViewModel
    @Environment(EventInviteViewModel.self) private var eventInviteViewModel
    @Environment(ProfileViewModel.self) private var profileViewModel
    
    @State var isEdit: Bool = false
    @State var isShowEditIconSheet: Bool = false
    @State var toggleSeeAllParticipantsSheet: Bool = false

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
                                Text("Participants (" + String((eventViewModel.selectedEvent?.participants ?? []).count) + ")")
                                    .font(.tabiBody)
                                VStack (alignment: .leading, spacing: .spacingTight) {
                                    Button {
                                        routes.navigate(to: .EventInviteView)
                                    } label: {
                                        HStack(spacing: .spacingTight){
                                            ZStack {
                                                Icon(systemName: "plus", color: .buttonBlue, size: 20)
                                                    .frame(width: 40, height: 40)
                                                    .clipShape(Circle())
                                                    .overlay {
                                                        Circle()
                                                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 5]))
                                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                            .foregroundColor(.bgGreyOverlay)
                                                    }
                                            }
                                            Text("Add")
                                                .font(.tabiBody)
                                                .foregroundColor(.buttonBlue)
                                        }
                                        .frame(maxHeight: .infinity, alignment: .leading)
                                    }
                                    
                                    Divider()
                                        .background(.buttonGrey)
                                    
                                    ForEach (eventViewModel.selectedEvent?.participants.firstFourElements ?? []) { user in
                                        HStack{
                                            UserAvatar(userData: user)
                                            VStack(alignment: .leading){
                                                Text(user.name)
                                                    .font(.tabiHeadline)
                                                Text(user.phone)
                                                    .font(.tabiBody)
                                                    .foregroundColor(.textGrey)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        Divider()
                                            .background(.buttonGrey)
                                    }
                                    
                                    Button{
                                        toggleSeeAllParticipantsSheet.toggle()
                                    }label:{
                                        HStack{
                                            Text("See All")
                                                .font(.tabiBody)
                                                .foregroundColor(.buttonBlue)
                                            Spacer()
                                            Icon(systemName: "chevron.right", color: .buttonBlue, size: 18)
                                        }
                                        .frame(height: 40)
                                    }
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 12)
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
            
            CustomButton(text: isEdit ? "Save" : "Create",
                         isEnabled: eventViewModel.eventName != "") {
                eventViewModel.handleCreateEditEvent(selectedContacts: eventInviteViewModel.selectedContacts, currentUser: profileViewModel.user)
                routes.navigateBack()
            }
        }
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
            SeeAllParticipantSheet(isPresented: $toggleSeeAllParticipantsSheet)
                .presentationDetents([.large])
        }
        .onAppear {
            if let selectedEvent = eventViewModel.selectedEvent {
                isEdit = true
                eventInviteViewModel.selectedContacts = selectedEvent.participants
            }
        }
        .padding()
        .addBackgroundColor(.bgWhite) {
            focusedField = nil
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    EventFormView()
        .environment(EventViewModel())
        .environment(EventInviteViewModel())
        .environment(Routes())
        .environment(ProfileViewModel())
}
