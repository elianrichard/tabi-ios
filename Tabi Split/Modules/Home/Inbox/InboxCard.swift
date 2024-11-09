//
//  InboxCard.swift
//  Tabi Split
//
//  Created by Elian Richard on 07/11/24.
//

import SwiftUI

struct InboxCard : View {
    var inboxItem: InboxData
    
    var body: some View {
        HStack (spacing: .spacingTight) {
            UserAvatar(userData: inboxItem.targetUser)
            VStack (alignment: .leading, spacing: .spacingSmall) {
                Text(inboxItem.type.generateText(targetUser: inboxItem.targetUser, amount: inboxItem.amount, eventName: inboxItem.eventName))
                    .font(.tabiHeadline)
                Text(inboxItem.dateTime.toTimeElapsedText())
                    .font(.tabiBody)
                    .foregroundStyle(.textGrey)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, .spacingTight)
        .padding(.horizontal, .spacingRegular)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(inboxItem.isUnread ? .bgBlueElevated : .clear)
        .clipShape(RoundedRectangle(cornerRadius: .radiusSmall))
    }
}

#Preview {
    ScrollView {
        VStack {
            InboxCard(inboxItem: InboxData(type: .NeedConfirmation, targetUser: UserData(name: "Ferry", phone: "Phone"), eventName: "Jepara Trip", dateTime: Date().addingTimeInterval(-10), isUnread: true))
            InboxCard(inboxItem: InboxData(type: .NeedConfirmation, targetUser: UserData(name: "Ferry", phone: "Phone"), eventName: "Jepara Trip", dateTime: Date().addingTimeInterval(-Date.secondsInMinute)))
            InboxCard(inboxItem: InboxData(type: .NeedConfirmation, targetUser: UserData(name: "Ferry", phone: "Phone"), eventName: "Jepara Trip", dateTime: Date().addingTimeInterval(-Date.secondsInMinute * 2)))
            InboxCard(inboxItem: InboxData(type: .NeedConfirmation, targetUser: UserData(name: "Ferry", phone: "Phone"), eventName: "Jepara Trip", dateTime: Date().addingTimeInterval(-Date.secondsInHour)))
            InboxCard(inboxItem: InboxData(type: .NeedConfirmation, targetUser: UserData(name: "Ferry", phone: "Phone"), eventName: "Jepara Trip", dateTime: Date().addingTimeInterval(-Date.secondsInHour * 2)))
            InboxCard(inboxItem: InboxData(type: .NeedConfirmation, targetUser: UserData(name: "Ferry", phone: "Phone"), eventName: "Jepara Trip", dateTime: Date().addingTimeInterval(-Date.secondsInWeek)))
            InboxCard(inboxItem: InboxData(type: .NeedConfirmation, targetUser: UserData(name: "Ferry", phone: "Phone"), eventName: "Jepara Trip", dateTime: Date().addingTimeInterval(-Date.secondsInWeek * 2)))
            InboxCard(inboxItem: InboxData(type: .NeedConfirmation, targetUser: UserData(name: "Ferry", phone: "Phone"), eventName: "Jepara Trip", dateTime: Date().addingTimeInterval(-Date.secondsInYear)))
            InboxCard(inboxItem: InboxData(type: .NeedConfirmation, targetUser: UserData(name: "Ferry", phone: "Phone"), eventName: "Jepara Trip", dateTime: Date().addingTimeInterval(-Date.secondsInYear * 2)))
            InboxCard(inboxItem: InboxData(type: .NeedPayment, targetUser: UserData(name: "Ferry", phone: "Phone"), eventName: "Jepara Trip", dateTime: Date().yesterday(), amount: 10_000))
        }
        .padding(.horizontal)
    }
}
