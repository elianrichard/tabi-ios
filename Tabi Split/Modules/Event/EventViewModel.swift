//
//  EventFormViewModel.swift
//  Tabi
//
//  Created by Elian Richard on 06/10/24.
//

import SwiftUI

@Observable
final class EventViewModel {
    var selectedSection: EventSection = .expenses
    
    var selectedEvent: EventData? {
        didSet {
            if let event = selectedEvent {
                eventName = event.eventName
                eventIcon = EventIconEnum(rawValue: event.eventIcon) ?? .icon1
                selectedSection = .expenses
            } else {
                eventName = ""
                eventIcon = .icon1
            }
        }
    }
    //    eventName and eventIcon need to be Bindable var, so user can change dynamically
    var eventName: String = ""
    var eventIcon: EventIconEnum = .icon1
    
    var isEventCompleted: Bool {
        if let event = selectedEvent {
            return event.completionDate != nil
        } else { return false }
    }
    var isNoParticipants: Bool {
        if let event = selectedEvent {
            return event.participants.count <= 1
        } else { return true }
    }
    var isUserCreator: Bool {
        if let user = UserDefaultsService.shared.getCurrentUser(), let selectedEvent {
            return user.userId == selectedEvent.creatorId
        } else { return false }
    }
    var isDirectInvite: Bool = false
    
    var participantsBalance: [PersonBalanceData] = []
    var userTransactionHistory: [SummaryHistoryData] = []
    var userBalance: PersonBalanceData {
        if let currentUser = UserDefaultsService.shared.getCurrentUser(),
           let personBalance = participantsBalance.first(where: { $0.user.phone == currentUser.userPhone }) {
            return personBalance
        } else { return PersonBalanceData(user: UserData(name: "Unkown", phone: "Phone")) }
    }
    var userTotalSpending: Float = 0
    var userSettlementList: [SummarySettlementData] = []
    
    var isApiCallLoading = false
    var error: AppError?
    
    @MainActor
    func handleEditEvent (selectedContacts: [UserData], currentUser: UserData, isGuest: Bool) async -> Bool {
        guard let selectedEvent else { return false }
        isApiCallLoading = true
        defer { isApiCallLoading = false }
        
        do {
            var participants: [UserData] = selectedContacts
            if !isGuest {
                let checkUsersResponse = try await ProfileService.shared.checkUsers(phoneNumbers: selectedContacts.map{ $0.phone })
                let registeredUsers : [UserData] = checkUsersResponse.users.map{ user in
                    if let image = ProfileImageEnum(rawValue: user.avatar_url) {
                        UserData(userId: user.user_id, name: user.name, phone: user.phone ?? "", image: image, imageUrl: "" )
                    } else {
                        UserData(userId: user.user_id, name: user.name, phone: user.phone ?? "", image: .owl, imageUrl: user.avatar_url )
                    }
                }
                
                var unregisteredUsers: [UserData] = selectedContacts.filter { contact in
                    return !registeredUsers.contains(where: { user in user.phone == contact.phone })
                }
                
                let response = try await EventService.shared.updateEvent(event: EventData(eventId: selectedEvent.eventId, eventName: eventName, eventIcon: eventIcon, participants: registeredUsers, creatorId: selectedEvent.creatorId), dummyNames: unregisteredUsers.map { $0.name })
                var registeredDummyUsers: [UserData] = []
                for dummyInfo in response.dummy_user_info {
                    if let user = unregisteredUsers.first(where: { $0.name == dummyInfo.dummy_name }) {
                        user.userId = dummyInfo.dummy_user_id
                        registeredDummyUsers.append(user)
                        unregisteredUsers.remove(user)
                    }
                }
                participants = registeredUsers + registeredDummyUsers
            }
            selectedEvent.eventName = eventName
            selectedEvent.eventIcon = eventIcon.id
            selectedEvent.participants = participants
            SwiftDataService.shared.saveModelContext()
        } catch {
            self.error = .from(error)
            return false
        }
        return true
        
    }
    
    @MainActor
    func handleCreateEvent (currentUser: UserData, isGuest: Bool) async -> Bool {
        isApiCallLoading = true
        defer { isApiCallLoading = false }
        
        do {
            var eventId: String?
            if !isGuest {
                let response = try await EventService.shared.createEvent(name: eventName, image: eventIcon.id)
                eventId = response.event_id
            }
            let newEvent = EventData(eventId: eventId, eventName: eventName, eventIcon: eventIcon, participants: [currentUser], creatorId: currentUser.userId)
            SwiftDataService.shared.addEvent(newEvent)
        } catch {
            self.error = .from(error)
            return false
        }
        return true
    }
    
    @MainActor
    func handleDeleteEvent (isGuest: Bool) async -> Bool {
        guard let selectedEvent else { return false }
        isApiCallLoading = true
        defer { isApiCallLoading = false }
        
        do {
            if !isGuest {
                try await EventService.shared.deleteEvent(event: selectedEvent)
            }
            SwiftDataService.shared.deleteEvent(selectedEvent)
        } catch {
            self.error = .from(error)
            return false
        }
        return true
    }
    
    @MainActor
    func completeEvent(isGuest: Bool) async -> Bool {
        guard let selectedEvent else { return false }
        isApiCallLoading = true
        defer { isApiCallLoading = false }
        
        do {
            if !isGuest {
                try await EventService.shared.completeEvent(event: selectedEvent)
            }
            SwiftDataService.shared.completeEvent(selectedEvent)
        } catch {
            self.error = .from(error)
            return false
        }
        return true
    }
    
    @MainActor
    func incompleteEvent(isGuest: Bool) async -> Bool {
        guard let selectedEvent else { return false }
        isApiCallLoading = true
        defer { isApiCallLoading = false }
        
        do {
            if !isGuest {
                try await EventService.shared.incompleteEvent(event: selectedEvent)
            }
            SwiftDataService.shared.incompleteEvent(selectedEvent)
        } catch {
            self.error = .from(error)
            return false
        }
        return true
    }
    
    func calculateOptimization(currentUser: UserData) {
        guard let event = selectedEvent else { return }

        participantsBalance = event.participants
            .map { PersonBalanceData(user: $0) }
            .sorted { $0.user.name.lowercased() < $1.user.name.lowercased() }

        let result = BalanceCalculator.optimize(
            participants: participantsBalance,
            expenses: event.expenses,
            currentUser: currentUser
        )
        userTransactionHistory = result.history
        userTotalSpending = result.totalSpending

        userSettlementList = []
        if userBalance.status == .debt {
            userSettlementList = userBalance.settlement.map {
                SummarySettlementData(targetUser: $0.userPaid, amount: $0.amount, status: .NeedPayment)
            }
        } else if userBalance.status == .credit {
            let related = participantsBalance.filter { $0.settlement.contains { $0.userPaid == currentUser } }
            for balance in related {
                for settlement in balance.settlement {
                    userSettlementList.append(SummarySettlementData(targetUser: balance.user, amount: settlement.amount, status: .WaitingPayment))
                }
            }
        }
        userSettlementList.sort { $0.targetUser.name.lowercased() < $1.targetUser.name.lowercased() }

        selectedEvent?.userEventBalance = userBalance.balance
    }
}
