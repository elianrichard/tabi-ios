//
//  EventFormViewModel.swift
//  Tabi
//
//  Created by Elian Richard on 06/10/24.
//

import SwiftUI

@Observable
final class EventViewModel {
    var selectedSection: EventSectionEnum = .expenses
    
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
           let personBalance = participantsBalance.first(where: { $0.user.isSameUser(as: currentUser) }) {
            return personBalance
        } else { return PersonBalanceData(user: UserData(name: "Unkown", email: "")) }
    }
    var userTotalSpending: Float = 0
    var userSettlementList: [SummarySettlementData] = []
    
    var isApiCallLoading = false
    
    @MainActor
    func handleEditEvent (selectedContacts: [UserData], currentUser: UserData) async -> Bool {
        guard let selectedEvent else { return false }
        isApiCallLoading = true
        defer { isApiCallLoading = false }

        do {
            var participants: [UserData] = selectedContacts
            let checkUsersResponse = try await ProfileService.shared.checkUsers(emails: selectedContacts.map{ $0.email }.filter { !$0.isEmpty })
            let registeredUsers : [UserData] = checkUsersResponse.users.map{ user in
                if let image = ProfileImageEnum(rawValue: user.avatar_url) {
                    UserData(userId: user.user_id, name: user.name, email: user.email ?? "", image: image, imageUrl: "" )
                } else {
                    UserData(userId: user.user_id, name: user.name, email: user.email ?? "", image: .owl, imageUrl: user.avatar_url )
                }
            }

            let unregisteredUsers: [UserData] = selectedContacts.filter { contact in
                return !registeredUsers.contains(where: { user in user.email == contact.email })
            }

            // A dummy that already has a userId was created on a previous invite.
            // Keep its anchor (id + image) and send it as a normal participant so
            // the backend reuses the existing row instead of minting a new dummy
            // with a fresh random avatar. Only brand-new dummies (empty userId)
            // are sent via dummy_users (name + client-chosen avatar).
            let anchoredDummyUsers: [UserData] = unregisteredUsers.filter { !$0.userId.isEmpty }
            var newDummyUsers: [UserData] = unregisteredUsers.filter { $0.userId.isEmpty }

            let participantsToSend = registeredUsers + anchoredDummyUsers
            let response = try await EventService.shared.updateEvent(event: EventData(eventId: selectedEvent.eventId, eventName: eventName, eventIcon: eventIcon, participants: participantsToSend, creatorId: selectedEvent.creatorId), newDummyUsers: newDummyUsers)

            var registeredDummyUsers: [UserData] = []
            for dummyInfo in response.dummy_user_info {
                if let user = newDummyUsers.first(where: { $0.name == dummyInfo.dummy_name }) {
                    // Anchor the new dummy to the backend's id, and adopt the
                    // avatar it assigned so the image stays fixed from now on.
                    user.userId = dummyInfo.dummy_user_id
                    if let avatar = dummyInfo.avatar_url, let image = ProfileImageEnum(rawValue: avatar) {
                        user.image = image.id
                    }
                    registeredDummyUsers.append(user)
                    newDummyUsers.remove(user)
                }
            }
            participants = registeredUsers + anchoredDummyUsers + registeredDummyUsers
            selectedEvent.eventName = eventName
            selectedEvent.eventIcon = eventIcon.id
            selectedEvent.participants = participants
            SwiftDataService.shared.saveModelContext()
        } catch {
            print("Edit Event failed: \(error)")
            return false
        }
        return true

    }

    @MainActor
    func handleCreateEvent (currentUser: UserData) async -> Bool {
        isApiCallLoading = true
        defer { isApiCallLoading = false }

        do {
            let response = try await EventService.shared.createEvent(name: eventName, image: eventIcon.id)
            let eventId = response.event_id
            // Source creatorId from the same authoritative identity the edit gate
            // reads (UserDefaults JWT userId) rather than currentUser.userId, which
            // can be "" when the SwiftData user row hasn't resolved yet — an empty
            // creatorId would make isUserCreator false and hide the Edit menu.
            let creatorId = UserDefaultsService.shared.getCurrentUser()?.userId ?? currentUser.userId
            let newEvent = EventData(eventId: eventId, eventName: eventName, eventIcon: eventIcon, participants: [currentUser], creatorId: creatorId, isSynced: true)
            SwiftDataService.shared.addEvent(newEvent)
        } catch {
            print("Create event failed: \(error)")
            return false
        }
        return true
    }

    @MainActor
    func handleDeleteEvent () async -> Bool {
        guard let selectedEvent else { return false }
        isApiCallLoading = true
        defer { isApiCallLoading = false }

        do {
            try await EventService.shared.deleteEvent(event: selectedEvent)
            SwiftDataService.shared.deleteEvent(selectedEvent)
        } catch {
            print("Delete event failed: \(error)")
            return false
        }
        return true
    }

    @MainActor
    func completeEvent() async -> Bool {
        guard let selectedEvent else { return false }
        isApiCallLoading = true
        defer { isApiCallLoading = false }

        do {
            try await EventService.shared.completeEvent(event: selectedEvent)
            SwiftDataService.shared.completeEvent(selectedEvent)
        } catch {
            print("Event completion fail: \(error)")
            return false
        }
        return true
    }

    @MainActor
    func incompleteEvent() async -> Bool {
        guard let selectedEvent else { return false }
        isApiCallLoading = true
        defer { isApiCallLoading = false }

        do {
            try await EventService.shared.incompleteEvent(event: selectedEvent)
            SwiftDataService.shared.incompleteEvent(selectedEvent)
        } catch {
            print("Event incomplete fail: \(error)")
            return false
        }
        return true
    }
    
    func calculateOptimization(currentUser: UserData) {
        let debug = false // enable this to debug print

        var userSummaryData: [SummaryHistoryData] = []
        var userTotalSpendingTemp: Float = 0
        guard let event = selectedEvent else { print("[OPT] no selectedEvent -> bail"); return }
        if debug {
            print("[OPT] ===== calculateOptimization START event=\(event.eventName) =====")
            print("[OPT] currentUser name=\(currentUser.name) id=\(currentUser.userId) email=\(currentUser.email) ptr=\(ObjectIdentifier(currentUser))")
            print("[OPT] event.participants count=\(event.participants.count)")
            for p in event.participants {
                print("[OPT]   participant name=\(p.name) id=\(p.userId) email=\(p.email) ptr=\(ObjectIdentifier(p))")
            }
            print("[OPT] event.expenses count=\(event.expenses.count)")
        }
        participantsBalance = event.participants.map { PersonBalanceData(user: $0) }
        participantsBalance = participantsBalance.sorted(by: { $0.user.name.lowercased() < $1.user.name.lowercased() })
        
        //        FILL THE PERSON LENT AND PERSON DEBT EXPENSE
        
        for expense in event.expenses {
            var userBalanceTemp: Float = 0
            if debug { print(expense.name + " - " + "Coverer: " + expense.coverer.name + " \(expense.price.formatPrice()) split=\(expense.splitMethod) participants=\(expense.participants.count) items=\(expense.items.count)") }
            if debug { print("[OPT]   coverer name=\(expense.coverer.name) id=\(expense.coverer.userId) email=\(expense.coverer.email) ptr=\(ObjectIdentifier(expense.coverer))") }
            guard let personPaid = participantsBalance.first(where: { $0.user == expense.coverer }) else {
                print("[OPT] !! BAIL: coverer not in participantsBalance (identity ==). expense=\(expense.name) coverer.ptr=\(ObjectIdentifier(expense.coverer)) balanceUserPtrs=\(participantsBalance.map { ObjectIdentifier($0.user) })")
                return
            }
            personPaid.lent += expense.price
            
            if expense.coverer == currentUser {
                userBalanceTemp += expense.price
            }
            
            if (expense.splitMethod == SplitMethod.custom.id) {
                let totalAdditionalCharges: Float = expense.additionalCharges.reduce(0) { $0 + $1.amount }
                let itemTotalAmount = expense.items.reduce(0) {$0 + $1.itemPrice * $1.itemQuantity}
                for item in expense.items {
                    let itemTotalShares = item.assignees.reduce(0) { $0 + ($1.share) }
                    for assignee in item.assignees {
                        guard let personBuy = participantsBalance.first(where: { $0.user == assignee.user }) else {
                            print("[OPT] !! BAIL: assignee not in participantsBalance (custom split). expense=\(expense.name) item=\(item.itemName) assignee.name=\(assignee.user.name) assignee.ptr=\(ObjectIdentifier(assignee.user)) balanceUserPtrs=\(participantsBalance.map { ObjectIdentifier($0.user) })")
                            return
                        }
                        let personQuantity = (assignee.share / itemTotalShares) * item.itemQuantity
                        let amountSpent = personQuantity * item.itemPrice
                        let amountAdditional = totalAdditionalCharges * (amountSpent / itemTotalAmount)
                        let amountDebt = Float(amountSpent + amountAdditional).properRound()
                        if debug { print("Participants: " + assignee.user.name, "\(item.itemName) Spent: ", amountSpent, "Additional: ", amountAdditional, "debt: ", amountDebt) }
                        if (expense.coverer == currentUser && personBuy.user == currentUser) {
                            personPaid.lent -= amountDebt
                        } else {
                            personBuy.debt += amountDebt
                        }
                        if (assignee.user == currentUser) {
                            userTotalSpendingTemp += amountDebt
                            userBalanceTemp -= amountDebt
                        }
                    }
                }
            } else if (expense.splitMethod == SplitMethod.equally.id) {
                let amountDebt = Float(expense.price / Float(expense.participants.count)).rounded(toDecimalPlaces: 1).properRound()
                for person in expense.participants {
                    guard let personBuy = participantsBalance.first(where: { $0.user == person }) else {
                        print("[OPT] !! BAIL: participant not in participantsBalance (equally split). expense=\(expense.name) person.name=\(person.name) person.ptr=\(ObjectIdentifier(person)) balanceUserPtrs=\(participantsBalance.map { ObjectIdentifier($0.user) })")
                        return
                    }
                    if (expense.coverer == currentUser && personBuy.user == currentUser) {
                        personPaid.lent -= amountDebt
                    } else {
                        personBuy.debt += amountDebt
                    }
                    if (person == currentUser) {
                        userTotalSpendingTemp += amountDebt
                        userBalanceTemp -= amountDebt
                    }
                }
            }
            
            //            record the specific user balance history data
            if (userBalanceTemp != 0) {
                userSummaryData.append(SummaryHistoryData(expenseName: expense.name, expenseDate: expense.dateOfCreation, amount: userBalanceTemp))
            }
        }
        
        if debug { print("[OPT] all expenses processed OK (no early return). participantsBalance count=\(participantsBalance.count)") }

        userTotalSpending = userTotalSpendingTemp
        userTransactionHistory = userSummaryData.sorted(by: { $0.expenseDate > $1.expenseDate })
        
        //        CALCULATE EACH PERSON BALANCE BASED ON LENT AND DEBT VALUE
        if debug {
            for participant in participantsBalance {
                print("\(participant.user.name) balance: " + String(participant.balance.formatPrice()))
            }
        }
        
        let personWithDebt: [PersonBalanceData] = participantsBalance.filter { $0.balance < 0 }.sorted(by: { $0.balance < $1.balance })
        let personWithLent: [PersonBalanceData] = participantsBalance.filter { $0.balance > 0 }.sorted(by: { $0.balance < $1.balance })
        
        for debtUser in personWithDebt {
            for lentUser in personWithLent {
                if debug { print("lent: ", lentUser.user.name, lentUser.calculationBalance, "debt: ", debtUser.user.name, debtUser.calculationBalance) }
                if (lentUser.calculationBalance <= 0) { continue }
                let sum = debtUser.calculationBalance + lentUser.calculationBalance
                if debug { print(debtUser.user.name, lentUser.user.name, sum) }
                if (sum >= 0) {
                    debtUser.settlement.append(PersonSettlementData(userPaid: lentUser.user, amount: abs(debtUser.calculationBalance)))
                    debtUser.calculationBalance = 0
                    lentUser.calculationBalance = sum
                    break
                } else if (sum < 0) {
                    debtUser.settlement.append(PersonSettlementData(userPaid: lentUser.user, amount: lentUser.calculationBalance))
                    debtUser.calculationBalance = sum
                    lentUser.calculationBalance = 0
                }
            }
        }
        
        //        Fill up user's settlement list
        userSettlementList = []
        if userBalance.status == .debt {
            for settlement in userBalance.settlement {
                userSettlementList.append(SummarySettlementData(targetUser: settlement.userPaid, amount: settlement.amount, status: .NeedPayment))
            }
        } else if userBalance.status == .credit {
            let relatedPersonBalance = participantsBalance.filter { $0.settlement.contains(where: { $0.userPaid == currentUser }) }
            for balance in relatedPersonBalance {
                for settlement in balance.settlement {
                    userSettlementList.append(SummarySettlementData(targetUser: balance.user, amount: settlement.amount, status: .WaitingPayment))
                }
            }
        }
        userSettlementList = userSettlementList.sorted(by: { $0.targetUser.name.lowercased() < $1.targetUser.name.lowercased() })
        
        if let selectedEvent {
            selectedEvent.userEventBalance = userBalance.balance
        }
        
        if debug {
            print("=== CALCULATE FINISH ===")
            for person in participantsBalance {
                for settlement in person.settlement {
                    print("\(person.user.name) should pay \(settlement.userPaid.name) for amount of \(settlement.amount.formatPrice())")
                }
            }
            for person in participantsBalance {
                print("\(person.user.name) balance: \(person.balance) calculation balance: \(person.calculationBalance)")
            }
        }
    }
}
