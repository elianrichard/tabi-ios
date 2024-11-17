//
//  EventInviteViewModel.swift
//  Tabi
//
//  Created by Elian Richard on 08/10/24.
//

import Foundation
import Contacts

@Observable
final class EventInviteViewModel {
    var searchUserText: String = "" {
        didSet {
            if (self.searchUserText != "") {
                filteredContacts = self.allContacts.filter {
                    let searchedText = $0.name.lowercased()
                    return searchedText.contains(searchUserText.lowercased())
                }
            } else {
                filteredContacts = self.allContacts
            }
        }
    }
    var allContacts: [UserData] = [] {
        didSet {
            filteredContacts = self.allContacts
        }
    }
    var filteredContacts: [UserData] = []
    var selectedContacts: [UserData] = []
    var cnContacts: [CNContact] = []
    
    func fillUpContacts() {
        let CNStore = CNContactStore()
        
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized, .limited:
            do {
                let keys = [CNContactGivenNameKey as CNKeyDescriptor, CNContactFamilyNameKey as CNKeyDescriptor, CNContactPhoneNumbersKey as CNKeyDescriptor]
                let request = CNContactFetchRequest(keysToFetch: keys)
                try CNStore.enumerateContacts(with: request, usingBlock: { contact, _ in
                    cnContacts.append(contact)
                })
            } catch {
                print("Error on contact fetching \(error)")
            }
        case .notDetermined, .denied, .restricted:
            CNStore.requestAccess(for: .contacts) { granted, error in
                if (granted) {
                    print("contact granted")
                    self.fillUpContacts()
                } else if let error = error {
                    print("Error requesting contact acces: \(error)")
                }
            }
        default:
            do {
                let keys = [CNContactGivenNameKey as CNKeyDescriptor, CNContactFamilyNameKey as CNKeyDescriptor, CNContactPhoneNumbersKey as CNKeyDescriptor]
                let request = CNContactFetchRequest(keysToFetch: keys)
                try CNStore.enumerateContacts(with: request, usingBlock: { contact, _ in
                    cnContacts.append(contact)
                })
            } catch {
                print("Error on contact fetching \(error)")
            }
        }
    }
    
    @MainActor
    func fetchContacts() {
        for contact in cnContacts {
            for number in contact.phoneNumbers {
                SwiftDataService.shared.addContact(name: "\(contact.givenName) \(contact.familyName)", phone: number.value.stringValue.formattedAsPhoneNumber())
            }
        }
        if let users = SwiftDataService.shared.getAllUsers(excludeLoggedUser: true) {
            allContacts = users.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
        }
    }
}
