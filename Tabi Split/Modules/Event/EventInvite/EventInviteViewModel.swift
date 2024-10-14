//
//  EventInviteViewModel.swift
//  Tabi
//
//  Created by Elian Richard on 08/10/24.
//

import Foundation
import Contacts

@Observable
final class EventInviteViewModel: ObservableObject {
    var searchUserText: String = "" {
        didSet {
            if (self.searchUserText != "") {
                filteredContacts = self.allContacts.filter {
                    let searchedText = "\($0.givenName) \($0.familyName)".lowercased()
                    return searchedText.contains(searchUserText.lowercased())
                }
            } else {
                filteredContacts = self.allContacts
            }
        }
    }
    var allContacts: [CNContact] = [] {
        didSet {
            filteredContacts = self.allContacts
        }
    }
    var filteredContacts: [CNContact] = []
    var selectedContacts: [UserData] = []
    
    func fetchContacts () -> Void {
        let CNStore = CNContactStore()
        
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized, .limited:
            do {
                let keys = [CNContactGivenNameKey as CNKeyDescriptor, CNContactFamilyNameKey as CNKeyDescriptor, CNContactPhoneNumbersKey as CNKeyDescriptor]
                let request = CNContactFetchRequest(keysToFetch: keys)
                try CNStore.enumerateContacts(with: request, usingBlock: { contact, _ in
                    allContacts.append(contact)
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
                    self.fetchContacts()
                } else if let error = error {
                    print("Error requesting contact acces: \(error)")
                }
            }
        default:
            do {
                let keys = [CNContactGivenNameKey as CNKeyDescriptor, CNContactFamilyNameKey as CNKeyDescriptor, CNContactPhoneNumbersKey as CNKeyDescriptor]
                let request = CNContactFetchRequest(keysToFetch: keys)
                try CNStore.enumerateContacts(with: request, usingBlock: { contact, _ in
                    allContacts.append(contact)
                })
            } catch {
                print("Error on contact fetching \(error)")
            }
        }
    }
}
