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
    var isLoadContactLoading: Bool = true

    // The participant currently being edited on the EditParticipant screen. Set
    // when the user taps a card's edit button, then read by EditParticipantView.
    var editingParticipant: UserData?


    var searchUserText: String = ""
    var searchFilteredContacts: [UserData] {
        if (searchUserText != "") {
            let query = searchUserText.lowercased()
            return allContacts.filter {
                $0.name.lowercased().contains(query) || $0.email.lowercased().contains(query)
            }
        } else { return allContacts }
    }
    var searchFilteredSelectedContacts: [UserData] {
        return searchFilteredContacts.filter{ isSelected($0) }
    }
    var searchFilteredUnselectedContacts: [UserData] {
        return searchFilteredContacts.filter{ !isSelected($0) }
    }

    var allContacts: [UserData] = []
    var selectedContacts: [UserData] = []
    var unselectedContacts: [UserData] {
        return allContacts.filter { !isSelected($0) }
    }

    /// Whether two contacts are the same person. Matches on userId first
    /// (authoritative), then email, then instance — so a selected event
    /// participant and its `allContacts` entry (different SwiftData instances,
    /// same identity) are recognized as one. Empty userId/email never match, so
    /// name-only dummy rows fall back to instance equality.
    func isSameContact(_ a: UserData, _ b: UserData) -> Bool {
        if !a.userId.isEmpty && !b.userId.isEmpty {
            return a.userId == b.userId
        }
        if !a.email.isEmpty && !b.email.isEmpty {
            return a.email.lowercased() == b.email.lowercased()
        }
        return a == b
    }

    /// Whether this contact is in the selected list, matched by identity.
    func isSelected(_ user: UserData) -> Bool {
        return selectedContacts.contains(where: { isSameContact($0, user) })
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
    
    /// The already-selected participant matching this email, if any. Used to warn
    /// when an invited email is already in the list rather than adding a duplicate.
    ///
    /// Resolves the contact from `allContacts` first (that entry carries the email
    /// even when the selected participant instance only has a userId), then checks
    /// selection by identity — so a selected contact whose participant row lacks a
    /// matching email string is still recognized as already added.
    func selectedUser(withEmail email: String) -> UserData? {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !email.isEmpty else { return nil }
        return selectedContacts.first(where: { selected in
            // Direct match on the selected participant's own email.
            if selected.email.lowercased() == email { return true }
            // Otherwise resolve via any allContacts entry with this email that is
            // the same person (covers participants stored with a userId but an
            // empty/absent email).
            if let contact = allContacts.first(where: { $0.email.lowercased() == email }) {
                return isSameContact(selected, contact)
            }
            return false
        })
    }

    /// Adds a participant invited by email. If a contact with the same email is
    /// already known, it is selected instead of appending a duplicate — mirroring
    /// the email-based dedup used when building `allContacts`.
    func addInvitedUser(name: String, email: String) {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existing = allContacts.first(where: { $0.email.lowercased() == email }) {
            // Dedup by identity, not instance: the selected list may hold the
            // equivalent participant object rather than this `allContacts` entry.
            if !isSelected(existing) {
                selectedContacts.append(existing)
            }
            return
        }

        let newUser = UserData(name: name, email: email)
        allContacts.append(newUser)
        selectedContacts.append(newUser)
    }

    func toggleSelectContact (user: UserData) {
        // Match by identity, not instance: the tapped card may be an `allContacts`
        // entry while the selected list holds the equivalent event-participant
        // instance (same person, different SwiftData object).
        if let existing = selectedContacts.first(where: { isSameContact($0, user) }) {
            selectedContacts.remove(existing)
        } else {
            selectedContacts.append(user)
        }
    }
    
    func fillUpContacts(currentUser: UserData, registeredUsers: [UserData]) {
        let CNStore = CNContactStore()
        var cnContacts: [CNContact] = []
        
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized, .limited:
            isLoadContactLoading = true
            do {
                let keys = [CNContactGivenNameKey as CNKeyDescriptor, CNContactFamilyNameKey as CNKeyDescriptor, CNContactEmailAddressesKey as CNKeyDescriptor]
                let request = CNContactFetchRequest(keysToFetch: keys)
                try CNStore.enumerateContacts(with: request, usingBlock: { contact, _ in
                    cnContacts.append(contact)
                })
            } catch {
                print("Error on contact fetching \(error)")
            }
            isLoadContactLoading = false
        case .notDetermined, .denied, .restricted:
            CNStore.requestAccess(for: .contacts) { granted, error in
                if (granted) {
                    print("contact granted")
                    self.isLoadContactLoading = true
                    self.fillUpContacts(currentUser: currentUser, registeredUsers: registeredUsers)
                } else if let error = error {
                    print("Error requesting contact acces: \(error)")
                    self.isLoadContactLoading = false
                }
            }
        default:
            do {
                let keys = [CNContactGivenNameKey as CNKeyDescriptor, CNContactFamilyNameKey as CNKeyDescriptor, CNContactEmailAddressesKey as CNKeyDescriptor]
                let request = CNContactFetchRequest(keysToFetch: keys)
                try CNStore.enumerateContacts(with: request, usingBlock: { contact, _ in
                    cnContacts.append(contact)
                })
            } catch {
                print("Error on contact fetching \(error)")
            }
            isLoadContactLoading = false
        }
        var allUsers: [UserData] = []

        for user in registeredUsers {
            if user.email != "" {
                allUsers.append(user)
            }
        }

        for user in selectedContacts {
            let email = user.email.lowercased()
            if !allUsers.contains(where: { $0.email == email }) {
                allUsers.append(user)
            }
        }

        for contact in cnContacts {
            for emailValue in contact.emailAddresses {
                let email = (emailValue.value as String).lowercased()
                if !allUsers.contains(where: { $0.email == email }){
                    allUsers.append(UserData(name: "\(contact.givenName) \(contact.familyName)", email: email))
                }
            }
        }

        allContacts = allUsers.filter{ $0.email != currentUser.email }
    }
}
