//
//  EventFormView.swift
//  Tabi
//
//  Created by Elian Richard on 06/10/24.
//

import SwiftUI

struct EventFormView: View {
    @EnvironmentObject var routes: Routes
    @EnvironmentObject var eventViewModel: EventViewModel
    @EnvironmentObject var eventInviteViewModel: EventInviteViewModel
    
    @State var name: String = ""
    @State var isEdit: Bool = false
    
    var body : some View {
        VStack (spacing: 40) {
            ZStack {
                Text(isEdit ? "Edit Event" : "Create Event")
                    .font(.title2)
                HStack {
                    Button {
                        routes.navigateBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.black)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            ZStack {
                Circle()
                    .fill(Color(UIColor(hex: "#D9D9D9")))
                    .frame(width: 80)
                Circle()
                    .fill(Color(UIColor(hex: "#8E8E8E")))
                    .frame(width: 24)
                    .frame(width: 80, height: 80, alignment: .bottomTrailing)
            }
            VStack (alignment: .leading, spacing: 16) {
                VStack (alignment: .leading, spacing: 12) {
                    Text("Event name")
                        .font(.title3)
                    TextField("Event name", text: $name)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .font(.body)
                        .background(Color(UIColor(hex: "#F7F7F7")))
                        .foregroundStyle(.black)
                }
                VStack (alignment: .leading, spacing: 12) {
                    Text("Participants")
                        .font(.title3)
                    HStack (alignment: .top, spacing: 10) {
                        ScrollView (showsIndicators: false) {
                            HStack (alignment: .top, spacing: 10) {
                                VStack {
                                    Circle()
                                        .fill(Color(UIColor(hex: "#D9D9D9")))
                                        .frame(width: 40)
                                    Text("You")
                                        .font(.caption)
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
            Spacer()
            Button {
                eventViewModel.handleCreateEditEvent(name: name, selectedContacts: [])
//                eventViewModel.handleCreateEditEvent(name: name, selectedContacts: eventInviteViewModel.selectedContacts)
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
            if let event = eventViewModel.selectedEvent {
                isEdit = true
                name = event.eventName
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    EventFormView()
        .environmentObject(EventViewModel())
        .environmentObject(EventInviteViewModel())
}
