//
//  EventInviteView.swift
//  Tabi
//
//  Created by Elian Richard on 08/10/24.
//

import SwiftUI
import Contacts


struct EventInviteView: View {
    @EnvironmentObject var routes: Routes
    @EnvironmentObject var eventViewModel: EventViewModel
    @StateObject var eventInviteViewModel = EventInviteViewModel()
    
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
                    TextField("Search", text: $eventInviteViewModel.searchUserText)
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
                eventViewModel.selectedContacts = eventInviteViewModel.selectedContacts
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
            fetchContacts()
            eventInviteViewModel.selectedContacts = eventViewModel.selectedContacts
        }
        .navigationBarBackButtonHidden(true)
        .environmentObject(eventInviteViewModel)
    }
    
    private func fetchContacts () -> Void {
        let CNStore = CNContactStore()
        
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized, .limited:
            do {
                let keys = [CNContactGivenNameKey as CNKeyDescriptor, CNContactFamilyNameKey as CNKeyDescriptor, CNContactPhoneNumbersKey as CNKeyDescriptor]
                let request = CNContactFetchRequest(keysToFetch: keys)
                try CNStore.enumerateContacts(with: request, usingBlock: { contact, _ in
                    eventInviteViewModel.allContacts.append(contact)
                })
            } catch {
                print("Error on contact fetching \(error)")
            }
//        case .restricted:
//            print("restricted")
//        case .denied:
//            print("denied")
        case .notDetermined, .denied, .restricted:
            CNStore.requestAccess(for: .contacts) { granted, error in
                if (granted) {
                    print("contact granted")
                    fetchContacts()
                } else if let error = error {
                    print("Error requesting contact acces: \(error)")
                }
            }
        default:
            do {
                let keys = [CNContactGivenNameKey as CNKeyDescriptor, CNContactFamilyNameKey as CNKeyDescriptor, CNContactPhoneNumbersKey as CNKeyDescriptor]
                let request = CNContactFetchRequest(keysToFetch: keys)
                try CNStore.enumerateContacts(with: request, usingBlock: { contact, _ in
                    eventInviteViewModel.allContacts.append(contact)
                })
            } catch {
                print("Error on contact fetching \(error)")
            }
        }
    }
}

#Preview {
    EventInviteView()
        .environmentObject(EventViewModel())
}
