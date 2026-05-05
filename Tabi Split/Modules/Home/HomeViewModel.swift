//
//  HomeViewModel.swift
//  Tabi
//
//  Created by Elian Richard on 03/10/24.
//

import SwiftUI
import OSLog

private let homeLogger = Logger(subsystem: "com.tabi.split", category: "HomeViewModel")

@Observable
final class HomeViewModel {
    var selectedFilter: HomeFilterEnum = .all {
        didSet { filterEvents(by: selectedFilter) }
    }
    var events: [EventData] = []
    var filteredEvents: [EventData] = []
    var notificationCount: Int = 0
    var isLoading: Bool = false
    var error: AppError?

    func filterEvents(by filter: HomeFilterEnum) {
        switch filter {
        case .all:      filteredEvents = events
        case .youOwe:   filteredEvents = events.filter { $0.userEventBalance < 0 }
        case .owsYou:   filteredEvents = events.filter { $0.userEventBalance > 0 }
        case .settled:  filteredEvents = events.filter { $0.userEventBalance == 0 }
        }
    }

    // TODO: Handle Migration
    func handleMigration(currentUser: UserData, events: [EventData]) async {
        func swapUser(oldUser: UserData, users: [UserData]) -> UserData {
            if oldUser.name == "Guest" && oldUser.phone == "" { return currentUser }
            if oldUser.phone != "" {
                return users.first(where: { $0.phone == oldUser.phone }) ?? oldUser
            }
            return users.first(where: { $0.name == oldUser.name && $0.phone == "" }) ?? oldUser
        }

        do {
            for event in events {
                let createEventResponse = try await EventService.shared.createEvent(name: event.eventName, image: event.eventIcon)
                let newEvent = EventData(eventId: createEventResponse.event_id, eventName: event.eventName, creatorId: currentUser.userId)
                let checkUsersResponse = try await ProfileService.shared.checkUsers(phoneNumbers: event.participants.map { $0.phone })
                var registeredUsers: [UserData] = checkUsersResponse.users.map { user in
                    if let image = ProfileImageEnum(rawValue: user.avatar_url) {
                        UserData(userId: user.user_id, name: user.name, phone: user.phone ?? "", image: image, imageUrl: "")
                    } else {
                        UserData(userId: user.user_id, name: user.name, phone: user.phone ?? "", image: .owl, imageUrl: user.avatar_url)
                    }
                }
                var unregisteredUsers = event.participants.filter { contact in
                    !registeredUsers.contains(where: { $0.phone == contact.phone }) && contact.name != "Guest"
                }
                registeredUsers.append(currentUser)
                newEvent.participants.append(contentsOf: registeredUsers)
                let editResponse = try await EventService.shared.updateEvent(event: newEvent, dummyNames: unregisteredUsers.map { $0.name })
                let updatedUnregistered: [UserData] = editResponse.dummy_user_info.compactMap { dummy in
                    guard let match = unregisteredUsers.first(where: { $0.name == dummy.dummy_name }) else { return nil }
                    unregisteredUsers.remove(match)
                    return UserData(userId: dummy.dummy_user_id, name: match.name, phone: match.phone)
                }
                let allUsers = registeredUsers + updatedUnregistered
                for expense in event.expenses {
                    var items: [ExpenseItem] = []
                    for item in expense.items {
                        let newItem = ExpenseItem(itemName: item.itemName, itemPrice: item.itemPrice, itemQuantity: item.itemQuantity)
                        for assignee in item.assignees {
                            newItem.assignees.append(ExpensePerson(user: swapUser(oldUser: assignee.user, users: allUsers), share: assignee.share))
                        }
                        items.append(newItem)
                    }
                    let newExpense = Expense(
                        name: expense.name,
                        coverer: swapUser(oldUser: expense.coverer, users: allUsers),
                        price: expense.price,
                        splitMethod: SplitMethod(rawValue: expense.splitMethod) ?? .equally,
                        items: items,
                        additionalCharges: expense.additionalCharges
                    )
                    let _ = try await ExpenseService.shared.createExpense(event: newEvent, expense: newExpense)
                }
            }
        } catch {
            homeLogger.error("Migration failed: \(error.localizedDescription)")
        }
    }

    @MainActor
    func populateEventData(data: GetEventsResponse, currentUser: UserData) {
        for event in data.events {
            let newEvent = buildEventFromAPI(event, currentUser: currentUser)
            SwiftDataService.shared.addEvent(newEvent)
            buildExpenses(for: newEvent, from: event.expenses, currentUser: currentUser)
            SwiftDataService.shared.saveModelContext()
        }
    }

    @MainActor
    func refreshEventData(currentUser: UserData, isGuest: Bool, isShowLoading: Binding<Bool>) async -> Bool {
        if !isGuest && !isLoading {
            do {
                isLoading = true
                isShowLoading.wrappedValue = true
                let data = try await EventService.shared.getAllEvents()
                SwiftDataService.shared.deleteAllEvents()
                for event in data.events {
                    let newEvent = buildEventFromAPI(event, currentUser: currentUser)
                    SwiftDataService.shared.addEvent(newEvent)
                    buildExpenses(for: newEvent, from: event.expenses, currentUser: currentUser)
                    SwiftDataService.shared.saveModelContext()
                }
            } catch {
                homeLogger.error("Fetch events failed: \(error.localizedDescription)")
                self.error = .from(error)
            }
        }

        if let data = SwiftDataService.shared.fetchAllEvents() {
            let sorted = data.sorted { $0.createdAt > $1.createdAt }
            events = sorted
            filteredEvents = sorted
            selectedFilter = .all
        }

        isLoading = false
        isShowLoading.wrappedValue = false
        return true
    }

    // MARK: - Private helpers

    @MainActor
    private func buildEventFromAPI(_ event: EventBase, currentUser: UserData) -> EventData {
        let image = EventIconEnum(rawValue: event.avatar_url) ?? .icon1
        var participants: [UserData] = []
        if let users = SwiftDataService.shared.getAllUsers() {
            for dataUser in event.participants {
                if let existing = users.first(where: { dataUser.user_id == $0.userId }) {
                    existing.update(fromUserBase: dataUser)
                    participants.append(existing)
                } else {
                    participants.append(UserData(userBase: dataUser))
                }
            }
        }
        let newEvent = EventData(
            eventId: event.id,
            eventName: event.name,
            completionDate: (event.completion_date ?? "").convertIsoToDate(),
            eventIcon: image,
            participants: participants,
            createdAt: event.created_at.convertIsoToDate(),
            creatorId: event.creator_id
        )
        return newEvent
    }

    @MainActor
    private func buildExpenses(for newEvent: EventData, from apiExpenses: [ExpenseEventBase], currentUser: UserData) {
        for expense in apiExpenses {
            guard let coverer = SwiftDataService.shared.getUserByUserId(expense.coverer_id),
                  let method = SplitMethod(rawValue: expense.split_method) else { continue }

            var participants: [UserData] = []
            for item in expense.items {
                for assignee in item.assignees {
                    if let user = SwiftDataService.shared.getUserByUserId(assignee.user_id),
                       !participants.contains(where: { $0 == user }) {
                        participants.append(user)
                    }
                }
            }

            let newExpense = Expense(
                expenseId: expense.id,
                name: expense.name,
                coverer: coverer,
                dateOfCreation: expense.created_at.convertIsoToDate(),
                price: expense.total_expense,
                splitMethod: method,
                participants: participants
            )
            newEvent.expenses.append(newExpense)

            for charge in expense.additional_charges {
                newExpense.additionalCharges.append(AdditionalCharge(additionalChargeBase: charge))
            }
            for item in expense.items {
                let assignees = item.assignees.compactMap { a -> ExpensePerson? in
                    guard let user = SwiftDataService.shared.getUserByUserId(a.user_id) else { return nil }
                    return ExpensePerson(user: user, share: a.share)
                }
                newExpense.items.append(ExpenseItem(itemId: item.id, itemName: item.name, itemPrice: item.price, itemQuantity: item.quantity, assignees: assignees))
            }
            newEvent.calculateUserEventBalance(currentUser: currentUser)
        }
    }
}
