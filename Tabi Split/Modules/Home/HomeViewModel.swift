//
//  HomeViewModel.swift
//  Tabi
//
//  Created by Elian Richard on 03/10/24.
//

import SwiftUI

@Observable
final class HomeViewModel {
    var selectedFilter: HomeFilterEnum = .all {
        didSet {
            filterEvents(by: selectedFilter)
        }
    }
    var events: [EventData] = []
    var filteredEvents: [EventData] = []
    var notificationCount: Int = 0
    var isLoading: Bool = false
    
    func filterEvents(by filter: HomeFilterEnum) {
        var eventData: [EventData] = []
        switch filter {
        case .all:
            eventData = events
        case .youOwe:
            eventData = events.filter { $0.userEventBalance < 0 }
        case .owsYou:
            eventData = events.filter { $0.userEventBalance > 0 }
        case .settled:
            eventData = events.filter { $0.userEventBalance == 0 }
        }
        filteredEvents = eventData
    }
    
    func handleMigration (currentUser: UserData, events: [EventData]) async {
        func swapUser (oldUser: UserData, users: [UserData]) -> UserData {
            if oldUser.phone != "" {
                return users.first(where: { $0.phone == oldUser.phone }) ?? oldUser
            } else {
                return users.first(where: { $0.name == oldUser.name && $0.phone == "" }) ?? oldUser
            }
        }
        
        do {
            for event in events {
                let createEventResponse = try await EventService.shared.createEvent(name: event.eventName, image: event.eventIcon)
                let newEvent = EventData(eventId: createEventResponse.event_id, eventName: event.eventName, creatorId: currentUser.userId)
                let checkUsersResponse = try await ProfileService.shared.checkUsers(phoneNumbers: event.participants.map{ $0.phone })
                var registeredUsers : [UserData] = checkUsersResponse.users.map{ user in
                    if let image = ProfileImageEnum(rawValue: user.avatar_url) {
                        UserData(userId: user.user_id, name: user.name, phone: user.phone ?? "", image: image, imageUrl: "" )
                    } else {
                        UserData(userId: user.user_id, name: user.name, phone: user.phone ?? "", image: .owl, imageUrl: user.avatar_url )
                    }
                }
                var unregisteredUsers: [UserData] = event.participants.filter { contact in
                    return !registeredUsers.contains(where: { user in user.phone == contact.phone }) && contact.name != "Guest"
                }
                registeredUsers.append(currentUser)
                newEvent.participants.append(contentsOf: registeredUsers)
                let editResponse = try await EventService.shared.updateEvent(event: newEvent, dummyNames: unregisteredUsers.map { $0.name })
                let updatedUnregisteredUsers: [UserData] = editResponse.dummy_user_info.compactMap { dummy in
                    if let dummyData = unregisteredUsers.first(where: { $0.name == dummy.dummy_name }) {
                        unregisteredUsers.remove(dummyData)
                        return UserData(userId: dummy.dummy_user_id, name: dummyData.name, phone: dummyData.phone)
                    } else { return nil }
                }
                let allUsers = registeredUsers + updatedUnregisteredUsers
                for expense in event.expenses {
                    var items: [ExpenseItem] = []
                    for item in expense.items {
                        let newItem = ExpenseItem(itemName: item.itemName, itemPrice: item.itemPrice, itemQuantity: item.itemQuantity)
                        for assignee in item.assignees {
                            if (assignee.user.name != "Guest" && assignee.user.phone != "") {
                                let expensePerson = ExpensePerson(user: swapUser(oldUser: assignee.user, users: allUsers), share: assignee.share)
                                newItem.assignees.append(expensePerson)
                            } else {
                                let expensePerson = ExpensePerson(user: currentUser, share: assignee.share)
                                newItem.assignees.append(expensePerson)
                            }
                        }
                        items.append(newItem)
                    }
                    let newExpense = Expense(name: expense.name, coverer: swapUser(oldUser: expense.coverer, users: allUsers), price: expense.price, splitMethod: SplitMethod(rawValue: expense.splitMethod) ?? .equally, items: items, additionalCharges: expense.additionalCharges)
                    for participant in newExpense.participants {
                        print(participant.name, participant.phone, participant.userId)
                    }
                    
                    for item in newExpense.items {
                        print(item.itemName)
                        for assignee in item.assignees {
                            print(assignee.user.name, assignee.user.phone, assignee.user.userId)
                        }
                    }
                    let _ = try await ExpenseService.shared.createExpense(event: newEvent, expense: newExpense)
                }
            }
        } catch {
            print("Migration failed: \(error)")
            return
        }
    }
    
    @MainActor
    func populateEventData(data: GetEventsResponse, currentUser: UserData) {
        for event in data.events {
            let image = EventIconEnum(rawValue: event.avatar_url) ?? .icon1
            var participants: [UserData] = []
            
            if let users = SwiftDataService.shared.getAllUsers() {
                for dataUser in event.participants {
                    if let targetUser = users.first(where: { dataUser.user_id == $0.userId }) {
                        targetUser.update(fromUserBase: dataUser)
                        participants.append(targetUser)
                    } else {
                        participants.append(UserData(userBase: dataUser))
                    }
                }
            }
            
            let newEvent = EventData(eventId: event.id, eventName: event.name, completionDate: (event.completion_date ?? "").convertIsoToDate(), eventIcon: image, participants: participants, createdAt: event.created_at.convertIsoToDate(), creatorId: event.creator_id)
            SwiftDataService.shared.addEvent(newEvent)
            
            guard let eventExpenses = event.expenses else { continue }
            
            for expense in eventExpenses {
                guard let coverer = SwiftDataService.shared.getUserByUserId(expense.coverer_id),
                      let method = SplitMethod(rawValue: expense.split_method) else { continue }
                var participants: [UserData] = []
                for item in expense.items {
                    for assignee in item.assignees {
                        if let user = SwiftDataService.shared.getUserByUserId(assignee.user_id) {
                            participants.append(user)
                        }
                    }
                }
                let newExpense = Expense(expenseId: expense.id, name: expense.name, coverer: coverer, dateOfCreation: expense.created_at.convertIsoToDate(), price: expense.total_expense, splitMethod: method, participants: participants)
                newEvent.expenses.append(newExpense)
                if let additionalCharges = expense.additional_charges {
                    for additionalCharge in additionalCharges {
                        newExpense.additionalCharges.append(AdditionalCharge(additionalChargeBase: additionalCharge))
                    }
                }
                
                for item in expense.items {
                    var itemAssignees: [ExpensePerson] = []
                    for assignee in item.assignees {
                        if let user = SwiftDataService.shared.getUserByUserId(assignee.user_id) {
                            itemAssignees.append(ExpensePerson(user: user, share: assignee.share))
                        }
                    }
                    let expenseItem = ExpenseItem(itemId: item.id, itemName: item.name, itemPrice: item.price, itemQuantity: item.quantity, assignees: itemAssignees)
                    newExpense.items.append(expenseItem)
                }
                newEvent.calculateUserEventBalance(currentUser: currentUser)
            }
            SwiftDataService.shared.saveModelContext()
        }
    }
    
    @MainActor
    func refreshEventData (currentUser: UserData, isGuest: Bool) {
        Task {
            if !isGuest {
                do {
                    isLoading = true
                    var data = try await EventService.shared.getAllEvents()
                    if let events = SwiftDataService.shared.fetchAllEvents() {
                        if events.count != 0 && data.events.count == 0 {
                            do {
                                print("Migration Starts")
                                await handleMigration(currentUser: currentUser, events: events)
                                data = try await EventService.shared.getAllEvents()
                            } catch {
                                print("Migration failed: \(error)")
                                return
                            }
                        }
                    }
                    SwiftDataService.shared.deleteAllEvents()
                    for event in data.events {
                        let image = EventIconEnum(rawValue: event.avatar_url) ?? .icon1
                        var participants: [UserData] = []
                        
                        if let users = SwiftDataService.shared.getAllUsers() {
                            for dataUser in event.participants {
                                if let targetUser = users.first(where: { dataUser.user_id == $0.userId }) {
                                    targetUser.update(fromUserBase: dataUser)
                                    participants.append(targetUser)
                                } else {
                                    participants.append(UserData(userBase: dataUser))
                                }
                            }
                        }
                        
                        let newEvent = EventData(eventId: event.id, eventName: event.name, completionDate: (event.completion_date ?? "").convertIsoToDate(), eventIcon: image, participants: [], createdAt: event.created_at.convertIsoToDate(), creatorId: event.creator_id)
                        SwiftDataService.shared.addEvent(newEvent)
                        newEvent.participants.append(contentsOf: participants)
                        
                        SwiftDataService.shared.saveModelContext()
                        guard let eventExpenses = event.expenses else { continue }
                        
                        for expense in eventExpenses {
                            guard let coverer = SwiftDataService.shared.getUserByUserId(expense.coverer_id),
                                  let method = SplitMethod(rawValue: expense.split_method) else { continue }
                            var participants: [UserData] = []
                            for item in expense.items {
                                for assignee in item.assignees {
                                    if let user = SwiftDataService.shared.getUserByUserId(assignee.user_id) {
                                        participants.append(user)
                                    }
                                }
                            }
                            
                            newEvent.expenses.append( Expense(expenseId: expense.id, name: expense.name, coverer: coverer, dateOfCreation: expense.created_at.convertIsoToDate(), price: expense.total_expense, splitMethod: method, participants: participants) )
                            
                            if let newExpense = newEvent.expenses.first(where: { $0.expenseId == expense.id }) {
                                if let additionalCharges = expense.additional_charges {
                                    for additionalCharge in additionalCharges {
                                        newExpense.additionalCharges.append(AdditionalCharge(additionalChargeBase: additionalCharge))
                                    }
                                }
                                
                                for item in expense.items {
                                    var itemAssignees: [ExpensePerson] = []
                                    for assignee in item.assignees {
                                        if let user = SwiftDataService.shared.getUserByUserId(assignee.user_id) {
                                            itemAssignees.append(ExpensePerson(user: user, share: assignee.share))
                                        }
                                    }
                                    let expenseItem = ExpenseItem(itemId: item.id, itemName: item.name, itemPrice: item.price, itemQuantity: item.quantity, assignees: itemAssignees)
                                    newExpense.items.append(expenseItem)
                                }
                            }
                            newEvent.calculateUserEventBalance(currentUser: currentUser)
                        }
                        SwiftDataService.shared.saveModelContext()
                    }
                } catch {
                    print("Fetch event failed: \(error)")
                }
            }
            
            if let data = SwiftDataService.shared.fetchAllEvents() {
                let eventData = data.sorted(by: { $0.createdAt > $1.createdAt })
                events = eventData
                filteredEvents = eventData
                selectedFilter = .all
            }
            
            isLoading = false
        }
    }
}
