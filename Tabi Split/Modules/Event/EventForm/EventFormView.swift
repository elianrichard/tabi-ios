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
    
    @State var isEdit: Bool = false
    @State var isShowEditIconSheet: Bool = false
    
    var images: [ImageResource] = [.samplePersonProfile1, .samplePersonProfile2, .samplePersonProfile3]
    
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
                }
                
                ScrollView (showsIndicators: false) {
                    VStack (alignment: .leading, spacing: .spacingRegular) {
                        InputWithLabel(label: "Event Name", placeholder: "Event name", text: Bindable(eventViewModel).eventName)
                        if (isEdit) {
                            VStack (alignment: .leading, spacing: .spacingTight) {
                                Text("Participants")
                                    .font(.tabiBody)
                                HStack (alignment: .top, spacing: .spacingTight) {
                                    ScrollView (.horizontal, showsIndicators: false) {
                                        HStack (alignment: .top, spacing: 10) {
                                            ForEach ( eventViewModel.selectedEvent?.participants ?? []) { user in
                                                UserAvatar(userData: user, namePosition: .bottom)
                                            }
                                        }
                                    }
                                    
                                    Rectangle()
                                        .fill(.uiGray)
                                        .frame(maxWidth: 2, maxHeight: .infinity)
                                    
                                    Button {
                                        routes.navigate(to: .EventInviteView)
                                    } label: {
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
                                    }
                                    .frame(maxHeight: .infinity)
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
                eventViewModel.handleCreateEditEvent(selectedContacts: eventInviteViewModel.selectedContacts)
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
        .onAppear {
            if let selectedEvent = eventViewModel.selectedEvent {
                isEdit = true
                eventInviteViewModel.selectedContacts = selectedEvent.participants
            }
        }
        .padding()
        .addBackgroundColor(.bgWhite)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    EventFormView()
        .environment(EventViewModel())
        .environment(EventInviteViewModel())
        .environment(Routes())
}
