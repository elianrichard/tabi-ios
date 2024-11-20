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
    var isLoadContactLoading: Bool {
        return allContacts.count == 0 ||
        CNContactStore.authorizationStatus(for: .contacts) == .denied ||
        CNContactStore.authorizationStatus(for: .contacts) == .restricted
    }
    
    var searchUserText: String = ""
    var searchFilteredContacts: [UserData] {
        if (searchUserText != "") {
            return allContacts.filter {
                let searchedText = $0.name.lowercased()
                return searchedText.contains(searchUserText.lowercased())
            }
        } else { return allContacts }
    }
    var searchFilteredSelectedContacts: [UserData] {
        return searchFilteredContacts.filter{ selectedContacts.contains($0) }
    }
    var searchFilteredUnselectedContacts: [UserData] {
        return searchFilteredContacts.filter{ !selectedContacts.contains($0) }
    }
    
    var allContacts: [UserData] = []
    var selectedContacts: [UserData] = []
    var unselectedContacts: [UserData] {
        return allContacts.filter { !selectedContacts.contains($0) }
    }
    
    var selectedContactsList: [UserData] {
        let contacts: [UserData]
        if searchUserText != "" { contacts = searchFilteredSelectedContacts }
        else { contacts = selectedContacts }
        return contacts.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
    }
    var unselectedContactsList: [UserData] {
        let contacts: [UserData]
        if searchUserText != "" { contacts = searchFilteredUnselectedContacts }
        else { contacts = unselectedContacts }
        return contacts.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
    }
    
    func toggleSelectContact (user: UserData) {
        if selectedContacts.contains(user) {
            selectedContacts.remove(user)
        } else {
            selectedContacts.append(user)
        }
    }
    
    func fillUpContacts(currentUser: UserData, registeredUsers: [UserData]) {
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
                    self.fillUpContacts(currentUser: currentUser, registeredUsers: registeredUsers)
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
        var allUsers: [UserData] = []
        
        for user in registeredUsers {
            if user.phone != "" {
                allUsers.append(user)                
            }
        }
        
        for user in selectedContacts {
            let phone = user.phone.formattedAsPhoneNumber()
            if !allUsers.contains(where: { $0.phone == phone }) {
                allUsers.append(user)
            }
        }
        
        for contact in cnContacts {
            for number in contact.phoneNumbers {
                let phone = number.value.stringValue.formattedAsPhoneNumber()
                if !allUsers.contains(where: { $0.phone == phone }){
                    allUsers.append(UserData(name: "\(contact.givenName) \(contact.familyName)", phone: number.value.stringValue.formattedAsPhoneNumber()))
                }
            }
        }
        
        allContacts = allUsers.filter{ $0.phone != currentUser.phone }
    }
}
