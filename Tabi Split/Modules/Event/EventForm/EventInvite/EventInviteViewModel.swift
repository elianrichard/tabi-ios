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
    
    func fillUpContacts() {
        let CNStore = CNContactStore()
        var cnContacts: [CNContact] = []
        
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
//        TO DO: Fix Warning SwiftData.ModelContext: Unbinding from the main queue.
        Task {
            await SwiftDataService.shared.addContacts(contacts: cnContacts)
            if let users = await SwiftDataService.shared.getAllUsers(excludeLoggedUser: true) {
                self.allContacts = users.sorted(by: { $0.name < $1.name })
            }
        }
    }
}
