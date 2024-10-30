//
//  EventFormView.swift
//  Tabi
//
//  Created by Elian Richard on 06/10/24.
//

import SwiftUI

struct EventFormView: View {
    @State var isEdit: Bool = false
    @Environment(Routes.self) private var routes
    @Environment(EventViewModel.self) private var eventViewModel
    @Environment(EventInviteViewModel.self) private var eventInviteViewModel

    var body : some View {
        VStack (spacing: 40) {
            TopNavigation(title: isEdit ? "Edit Event" : "Create Event")
            ZStack {
                Circle()
                    .fill(Color(UIColor(hex: "#D9D9D9")))
                    .frame(width: 80)
                Circle()
                    .fill(Color(UIColor(hex: "#8E8E8E")))
                    .frame(width: 24)
                    .frame(width: 80, height: 80, alignment: .bottomTrailing)
            }
            
            ScrollView (showsIndicators: false) {
                VStack (alignment: .leading, spacing: 16) {
                    InputWithLabel(label: "Event Name", placeholder: "Event name", text: Bindable(eventViewModel).eventName)
                    VStack (alignment: .leading, spacing: 12) {
                        Text("Participants")
                            .font(.title3)
                        HStack (alignment: .top, spacing: 10) {
                            ScrollView (showsIndicators: false) {
                                HStack (alignment: .top, spacing: 10) {
                                    if !isEdit {
                                        VStack {
                                            Circle()
                                                .fill(Color(UIColor(hex: "#D9D9D9")))
                                                .frame(width: 40)
                                            Text("You")
                                                .font(.caption)
                                        }
                                    }
                                    ForEach ( isEdit ? (eventViewModel.selectedEvent?.participants ?? []) : eventInviteViewModel.selectedContacts) { user in
                                        VStack {
                                            Circle()
                                                .fill(Color(UIColor(hex: "#D9D9D9")))
                                                .frame(width: 40)
                                            Text("\(user.name.split(separator: " ").first ?? "error")")
                                                .font(.caption)
                                        }
                                    }
                                }
                            }
                            Button {
                                routes.navigate(to: .EventInviteView)
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(UIColor(hex: "#D9D9D9")))
                                        .frame(width: 40)
                                    Image(systemName: "plus")
                                        .foregroundStyle(.black)
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .background(Color(UIColor(hex: "#F7F7F7")))
                    }
                }
            }
            
//            Spacer()
            
            Button {
                eventViewModel.handleCreateEditEvent(selectedContacts: eventInviteViewModel.selectedContacts)
                routes.navigateBack()
            } label: {
                Text(eventViewModel.selectedEvent != nil ? "Edit" : "Create")
                    .frame(maxWidth: .infinity)
                    .font(.callout)
                    .foregroundStyle(.black)
                    .padding(.vertical, 16)
                    .background(Color(UIColor(hex: "#D9D9D9")))
                    .clipShape(RoundedRectangle(cornerRadius: 32))
            }
        }
        .onAppear {
            if let selectedEvent = eventViewModel.selectedEvent {
                isEdit = true
                eventInviteViewModel.selectedContacts = selectedEvent.participants
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    EventFormView()
        .environment(EventViewModel())
        .environment(EventInviteViewModel())
        .environment(Routes())
}
