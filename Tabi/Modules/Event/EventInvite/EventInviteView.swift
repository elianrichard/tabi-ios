//
//  EventInviteView.swift
//  Tabi
//
//  Created by Elian Richard on 08/10/24.
//

import SwiftUI
import Contacts


struct EventInviteView: View {
    @Environment(Routes.self) private var routes
    @Environment(EventViewModel.self) private var eventViewModel
    @Environment(EventInviteViewModel.self) private var eventInviteViewModel
    
    var body: some View {
        VStack (spacing: 40) {
            ZStack {
                Text("Invite Participants")
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
            HStack (spacing: 10) {
                EventInviteShareButtonView(text: "Share Link Invitation")
                EventInviteShareButtonView(text: "Copy Link")
                EventInviteShareButtonView(text: "Show QR Code")
            }
            VStack (spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search", text: Bindable(eventInviteViewModel).searchUserText)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color(UIColor(hex: "#D9D9D9")))
                .clipShape(RoundedRectangle(cornerRadius: 40))
                
                ScrollView (showsIndicators: false) {
                    
                    VStack {
                        ForEach(eventInviteViewModel.filteredContacts) { contact in
                            ForEach(contact.phoneNumbers, id: \.identifier) { number in
                                EventInviteCardView(name: "\(contact.givenName) \(contact.familyName)", number: number.value.stringValue, label: CNLabeledValue<CNPhoneNumber>.localizedString(forLabel: number.label!).capitalized)
                            }
                        }
                    }
                }
            }
            
            Button {
                eventViewModel.selectedEvent?.participants = eventInviteViewModel.selectedContacts
                routes.navigateBack()
            } label: {
                Text("Done")
                    .frame(maxWidth: .infinity)
                    .font(.callout)
                    .foregroundStyle(.black)
                    .padding(.vertical, 16)
                    .background(Color(UIColor(hex: "#D9D9D9")))
                    .clipShape(RoundedRectangle(cornerRadius: 32))
            }
        }
        .padding()
        .onAppear {
            if (eventInviteViewModel.allContacts.count == 0) {
                DispatchQueue.global(qos: .background).async {
                    eventInviteViewModel.fetchContacts()
                }
            }
            if let selectedEvent = eventViewModel.selectedEvent {
                eventInviteViewModel.selectedContacts = selectedEvent.participants
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
}

#Preview {
    EventInviteView()
        .environment(Routes())
        .environment(EventViewModel())
        .environment(EventInviteViewModel())
}
