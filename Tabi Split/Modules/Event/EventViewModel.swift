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
            }
        }
    }
    //    eventName and eventIcon need to be Bindable var, so user can change
    var eventName: String = ""
    var eventIcon: EventIconEnum = .icon1
    
    var isEventCompleted: Bool = false
    var completionDate: Date?
    var isNoParticipants: Bool {
        if let event = selectedEvent {
            return event.participants.count == 1
        } else { return true }
    }
    
    var participantsBalance: [PersonBalanceData] = []
    var userTransactionHistory: [SummaryHistoryData] {
        if let event = selectedEvent {
            var data: [SummaryHistoryData] = []
            var totalSpending: Float = 0
            
            for expense in event.expenses {
                var balance: Float = 0
//                calculate lent from expense
                if expense.coverer.name == "You" {
                    balance += expense.price
                }
//                calculate debt from expense
                if (expense.splitMethod == SplitMethod.custom.id) {
                    var tempAmount: Float = 0
                    for item in expense.items {
                        for assignee in item.assignees {
                            if assignee.user.name == "You" {
                                let amountDebt = Float(assignee.share * item.itemPrice).rounded(toDecimalPlaces: 1).properRound()
                                tempAmount += amountDebt
                            }
                        }
                    }
                    totalSpending += tempAmount
                    balance -= tempAmount
                } else if (expense.splitMethod == SplitMethod.equally.id) {
                    if (expense.participants.contains(where: { $0.name == "You" })) {
                        let amountDebt = Float(expense.price / Float(expense.participants.count)).rounded(toDecimalPlaces: 1).properRound()
                        balance -= amountDebt
                    }
                }
                
                data.append(SummaryHistoryData(expenseName: expense.name, expenseDate: expense.dateOfCreation, amount: balance))
            }
            userTotalSpending = totalSpending
            return data.sorted(by: { $0.expenseDate > $1.expenseDate })
        } else { return [] }
    }
    var userBalance: Float {
        if let userBalanceData = participantsBalance.first(where: { $0.user.name == "You" }) {
            //            person balance always set whenever lent and debt are set, see PersonalBalanceData class
            return userBalanceData.balance
        } else { return 0 }
    }
    var summaryStatus: EventCardStatusEnum {
        if (userBalance > 0) {
            return .credit
        } else if (userBalance < 0) {
            return .debt
        } else {
            return .settled
        }
    }
    
    @MainActor
    func handleCreateEditEvent (selectedContacts: [UserData]) {
        if let selectedEvent = selectedEvent {
            selectedEvent.eventName = eventName
            selectedEvent.eventIcon = eventIcon.id
            selectedEvent.participants = selectedContacts
        } else {
            SwiftDataService.shared.addEvent(EventData(eventName: eventName, eventIcon: eventIcon, participants: [UserData(name: "You", phone: "08123456789")] + selectedContacts))
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
        isEventCompleted = true
        completionDate = Date()
    }
    
    func calculateOptimization() {
        let debug = false
        
        guard let event = selectedEvent else { return }
        participantsBalance = event.participants.map { PersonBalanceData(user: $0) }
        
        //        FILL THE PERSON LENT AND PERSON DEBT EXPENSE
        
        for expense in event.expenses {
            if debug { print(expense.name + "-" + "Coverer: " + expense.coverer.name + " \(expense.price.formatPrice())") }
            guard let personPaid = participantsBalance.first(where: { $0.user == expense.coverer }) else { return }
            personPaid.lent += expense.price
            
            if (expense.splitMethod == SplitMethod.custom.id) {
                for item in expense.items {
                    for assignee in item.assignees {
                        guard let personBuy = participantsBalance.first(where: { $0.user == assignee.user }) else { return }
                        let amountDebt = Float(assignee.share * item.itemPrice).rounded(toDecimalPlaces: 1).properRound()
                        if debug { print("Participants: " + assignee.user.name, "debt: ", amountDebt) }
                        personBuy.debt += amountDebt
                    }
                }
            } else if (expense.splitMethod == SplitMethod.equally.id) {
                for person in expense.participants {
                    guard let personBuy = participantsBalance.first(where: { $0.user == person }) else { return }
                    let amountDebt = Float(expense.price / Float(expense.participants.count)).rounded(toDecimalPlaces: 1).properRound()
                    personBuy.debt += amountDebt
                }
            }
        }
        
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
