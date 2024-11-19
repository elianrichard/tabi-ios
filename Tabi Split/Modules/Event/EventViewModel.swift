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
    
    @MainActor
    func handleCreateEditEvent (selectedContacts: [UserData], currentUser: UserData) {
        var participants = selectedContacts.map { $0 }
        participants.append(currentUser)
        
        if let selectedEvent {
            selectedEvent.eventName = eventName
            selectedEvent.eventIcon = eventIcon.id
            selectedEvent.participants = participants
        } else {
            let newEvent = EventData(eventName: eventName, eventIcon: eventIcon, participants: [])
            SwiftDataService.shared.addEvent(newEvent)
            newEvent.participants.append(contentsOf: participants)
            SwiftDataService.shared.saveModelContext()
        }
    }
    
    @MainActor
    func handleDeleteEvent () {
        if let selectedEvent {
            SwiftDataService.shared.deleteEvent(selectedEvent)
        }
    }
    
    @MainActor
    func completeEvent() {
        if let selectedEvent {
            SwiftDataService.shared.completeEvent(selectedEvent)
        }
    }
    
    @MainActor
    func incompleteEvent() {
        if let selectedEvent {
            SwiftDataService.shared.incompleteEvent(selectedEvent)
        }
    }
    
    func calculateOptimization(currentUser: UserData) {
        let debug = true // enable this to debug print
        
        var userSummaryData: [SummaryHistoryData] = []
        var userTotalSpendingTemp: Float = 0
        guard let event = selectedEvent else { return }
        participantsBalance = event.participants.map { PersonBalanceData(user: $0) }
        
        //        FILL THE PERSON LENT AND PERSON DEBT EXPENSE
        
        for expense in event.expenses {
            var userBalanceTemp: Float = 0
            if debug { print(expense.name + " - " + "Coverer: " + expense.coverer.name + " \(expense.price.formatPrice())") }
            guard let personPaid = participantsBalance.first(where: { $0.user == expense.coverer }) else { return }
            personPaid.lent += expense.price
            
            if expense.coverer == currentUser {
                userBalanceTemp += expense.price
            }
            
            if (expense.splitMethod == SplitMethod.custom.id) {
                let totalAdditionalCharges: Float = expense.additionalCharges.reduce(0) { $0 + $1.amount }
                let itemTotalAmount = expense.items.reduce(0) {$0 + $1.itemPrice}
                for item in expense.items {
                    let itemTotalShares = item.assignees.reduce(0) { $0 + ($1.share) }
                    for assignee in item.assignees {
                        guard let personBuy = participantsBalance.first(where: { $0.user == assignee.user }) else { return }
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
                    guard let personBuy = participantsBalance.first(where: { $0.user == person }) else { return }
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
        
        userTotalSpending = userTotalSpendingTemp
        userTransactionHistory = userSummaryData.sorted(by: { $0.expenseDate > $1.expenseDate })
        
        //        CALCULATE EACH PERSON BALANCE BASED ON LENT AND DEBT VALUE
        if debug {
            for participant in participantsBalance {
                print("\(participant.user.name) balance: " + String(participant.balance.formatPrice()))
            }
        }
        
        let personWithDebt: [PersonBalanceData] = participantsBalance.filter { $0.balance < 0 }
        let personWithLent: [PersonBalanceData] = participantsBalance.filter { $0.balance > 0 }
        
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
