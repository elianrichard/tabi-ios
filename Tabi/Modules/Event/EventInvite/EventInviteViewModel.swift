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
    var searchUserText: String {
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
    var allContacts: [CNContact] {
        didSet {
            filteredContacts = self.allContacts
        }
    }
    var filteredContacts: [CNContact] = []
    var selectedContacts: [UserData] = []
    
    init() {
        self.searchUserText = ""
        self.allContacts = []
        self.filteredContacts = []
    }
}
