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
    func refreshEventData (currentUser: UserData, isGuest: Bool) {
        Task {
            if !isGuest {
                do {
                    isLoading = true
                    let data = try await EventService.shared.getAllEvents()
                    // TODO: Migrate instead of delete, do this after expense CRUD is done
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
