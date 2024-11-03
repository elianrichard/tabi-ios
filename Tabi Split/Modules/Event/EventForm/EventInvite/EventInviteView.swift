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
        VStack (spacing: .spacingLarge) {
            TopNavigation(title: "Add Participants")
            HStack (spacing: .spacingMedium) {
                EventInviteShareButtonView(text: "Copy Link",
                                           icon: .linkIcon,
                                           action: {
                    print("Copy Link")
                })
                EventInviteShareButtonView(text: "Share Link",
                                           icon: .shareIcon,
                                           action: {
                    print("Share Link")
                })
                EventInviteShareButtonView(text: "QR Code",
                                           icon: .qrIcon,
                                           action: {
                    print("QR Code")
                })
            }
            HStack (spacing: .spacingSmall) {
                Image(systemName: "magnifyingglass")
                TextField("Search", text: Bindable(eventInviteViewModel).searchUserText)
                    .font(.tabiBody)
            }
            .padding(.spacingTight)
            .background(.uiWhite)
            .clipShape(RoundedRectangle(cornerRadius: .infinity))
            .overlay {
                RoundedRectangle(cornerRadius: .infinity)
                    .fill(.clear)
                    .strokeBorder(.uiGray, lineWidth: 1)
            }
            
            ScrollView (showsIndicators: false) {
                VStack {
                    ForEach(eventInviteViewModel.filteredContacts) { contact in
                        ForEach(contact.phoneNumbers, id: \.identifier) { number in
                            EventInviteCardView(name: "\(contact.givenName) \(contact.familyName)", number: number.value.stringValue, label: CNLabeledValue<CNPhoneNumber>.localizedString(forLabel: number.label ?? "").capitalized)
                        }
                    }
                }
            }
            
            CustomButton(text: "Add", isEnabled: eventInviteViewModel.selectedContacts.count > 0) {
                eventViewModel.selectedEvent?.participants = eventInviteViewModel.selectedContacts
                routes.navigateBack()
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
