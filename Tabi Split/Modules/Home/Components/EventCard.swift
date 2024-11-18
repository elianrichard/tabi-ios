//
//  EventCardView.swift
//  Tabi
//
//  Created by Elian Richard on 04/10/24.
//

import SwiftUI

struct EventCard : View {
    var event: EventData
    var status: EventCardStatusEnum = .settled
    var isNew: Bool = false
    
    init(event: EventData) {
        self.event = event
        if (event.userEventBalance > 0) {
            self.status = .credit
        } else if (event.userEventBalance < 0) {
            self.status = .debt
        } else {
            self.status = .settled
        }
        if (event.expenses.count == 0) {
            isNew = true
        }
    }
    
    var body : some View {
        VStack (alignment: .leading, spacing: 10) {
            HStack (spacing: 12) {
                Image(EventIconEnum(rawValue: event.eventIcon)?.resource ?? .eventIcon1)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40)
                    .clipShape(Circle())
                VStack (alignment: .leading, spacing: 4) {
                    Text("\(event.eventName)")
                        .font(.tabiHeadline)
                    HStack (alignment: .center, spacing: 8) {
                        Circle()
                            .fill(event.completionDate != nil ? .buttonPurple : .buttonGreen)
                            .frame(width: 12)
                        Text(event.completionDate != nil
                             ? "Completed on \(Date().customDateFormat("dd MMM yyyy").string(from: event.completionDate ?? Date()))"
                             : "Ongoing Event"
                        )
                        .font(.tabiBody)
                    }
                }
            }
            Rectangle()
                .fill(Color(UIColor(hex: "#D9D9D9")))
                .frame(height: 1)
            HStack (spacing: .spacingTight) {
                HStack (spacing: -6) {
                    ForEach(Array(event.participants.enumerated()), id: \.offset) { index, user in
                        if (index < 4) {
                            if (event.participants.count > 4 && index == 3) {
                                Circle()
                                    .fill(.uiGray)
                                    .frame(width: 40)
                                    .overlay {
                                        Text("+\(event.participants.count - 3)")
                                            .font(.tabiBody)
                                    }
                            } else {
                                UserAvatar(userData: user)
                                    .zIndex(Double(4-index))
                            }
                        }
                    }
                    if (event.participants.count < 4) {
                        ForEach(Array(0 ..< (4-event.participants.count)), id: \.self) { _ in
                            Circle()
                                .frame(width: 40)
                                .opacity(0)
                        }
                    }
                }
                HStack {
                    if (isNew) {
                        Text("New Event")
                    } else if (status == .settled) {
                        Text(status.statusDisplay)
                    } else {
                        Text(status.statusDisplay)
                        Spacer()
                        Text("Rp\(event.userEventBalance.formatPrice(isShowSign: false))")
                    }
                }
                .font(.tabiBody2)
                .padding(.horizontal, .spacingTight)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(isNew ? .bgBlueElevated : status.statusColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .fill(.clear)
                .stroke(.uiGray, lineWidth: 2)
        }
    }
}

#Preview {
    let tempExpense: [Expense] = [Expense(name: "Test", coverer: UserData(name: "test", phone: "test"), price: 10_000, splitMethod: .equally)]
    let tempParticipants: [UserData] = [
        UserData(name: "A", phone: "A"),
        UserData(name: "A", phone: "A"),
        UserData(name: "A", phone: "A"),
        UserData(name: "A", phone: "A"),
        UserData(name: "A", phone: "A"),
        UserData(name: "A", phone: "A"),
        UserData(name: "A", phone: "A"),
        UserData(name: "A", phone: "A"),
    ]
    
    ScrollView {
        EventCard(
            event: EventData(eventName: "New York Trip", completionDate: nil, userEventBalance: 0, participants: tempParticipants)
        )
        EventCard(
            event: EventData(eventName: "New York Trip",
                             completionDate: nil,
                             userEventBalance: 2_500_000,
                             participants: tempParticipants,
                             expenses: tempExpense
                            )
        )
        EventCard(
            event: EventData(eventName: "New York Trip", completionDate: nil, userEventBalance: -1_000_000,
                             participants: tempParticipants, expenses: tempExpense)
        )
        EventCard(
            event: EventData(eventName: "New York Trip", completionDate: Date(), userEventBalance: 500_000,
                             participants: tempParticipants, expenses: tempExpense)
        )
        EventCard(
            event: EventData(eventName: "New York Trip", completionDate: Date(), userEventBalance: -100_000,
                             participants: tempParticipants, expenses: tempExpense)
        )
        EventCard(
            event: EventData(eventName: "New York Trip", completionDate: Date(), userEventBalance: 0,
                             participants: tempParticipants, expenses: tempExpense)
        )
    }.padding()
}
