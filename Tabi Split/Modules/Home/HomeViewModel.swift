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
            
            let newEvent = EventData(eventId: event.id, eventName: event.name, completionDate: (event.completion_date ?? "").convertIsoToDate(), eventIcon: image, participants: participants, createdAt: event.created_at.convertIsoToDate(), creatorId: event.creator_id, isSynced: true)
            SwiftDataService.shared.addEvent(newEvent)
            
            let eventExpenses = event.expenses
            
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
                let newExpense = Expense(expenseId: expense.id, name: expense.name, coverer: coverer, dateOfCreation: expense.created_at.convertIsoToDate(), price: expense.total_expense, splitMethod: method, participants: participants, isSynced: true)
                newEvent.expenses.append(newExpense)
                for additionalCharge in expense.additional_charges {
                    newExpense.additionalCharges.append(AdditionalCharge(additionalChargeBase: additionalCharge))
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
    func refreshEventData (currentUser: UserData, isGuest: Bool, isShowLoading: Binding<Bool>) async -> Bool {
        if (!isGuest && !isLoading) {
            do {
                isLoading = true
                isShowLoading.wrappedValue = true
                let data = try await EventService.shared.getAllEvents()

                // Drop synced rows only; unsynced rows stay queued for retry.
                let existing = SwiftDataService.shared.fetchAllEvents() ?? []
                for event in existing where event.isSynced {
                    SwiftDataService.shared.deleteEvent(event)
                }
                SwiftDataService.shared.saveModelContext()

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
                    
                    let newEvent = EventData(eventId: event.id, eventName: event.name, completionDate: (event.completion_date ?? "").convertIsoToDate(), eventIcon: image, participants: [], createdAt: event.created_at.convertIsoToDate(), creatorId: event.creator_id, isSynced: true)
                    SwiftDataService.shared.addEvent(newEvent)
                    newEvent.participants.append(contentsOf: participants)
                    
                    SwiftDataService.shared.saveModelContext()
                    let eventExpenses = event.expenses
                    
                    for expense in eventExpenses {
                        guard let coverer = SwiftDataService.shared.getUserByUserId(expense.coverer_id),
                              let method = SplitMethod(rawValue: expense.split_method) else { continue }
                        var participants: [UserData] = []
                        for item in expense.items {
                            for assignee in item.assignees {
                                if let user = SwiftDataService.shared.getUserByUserId(assignee.user_id) {
                                    if !participants.contains(where: { $0 == user }) {
                                        participants.append(user)
                                    }
                                }
                            }
                        }
                        
                        newEvent.expenses.append( Expense(expenseId: expense.id, name: expense.name, coverer: coverer, dateOfCreation: expense.created_at.convertIsoToDate(), price: expense.total_expense, splitMethod: method, participants: participants, isSynced: true) )
                        SwiftDataService.shared.saveModelContext()
                        
                        if let newExpense = newEvent.expenses.first(where: { $0.expenseId == expense.id }) {
                            for additionalCharge in expense.additional_charges {
                                newExpense.additionalCharges.append(AdditionalCharge(additionalChargeBase: additionalCharge))
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
                                SwiftDataService.shared.saveModelContext()
                            }
                        }
                        newEvent.calculateUserEventBalance(currentUser: currentUser)
                        SwiftDataService.shared.saveModelContext()
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
        isShowLoading.wrappedValue = false
        return true
    }
    
}
