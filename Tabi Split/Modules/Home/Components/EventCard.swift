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
                Image(.sampleEventPicture)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40)
                    .clipShape(Circle())
                VStack (alignment: .leading, spacing: 4) {
                    Text("\(event.eventName)")
                        .font(.tabiHeadline)
                    HStack (alignment: .center, spacing: 8) {
                            Circle()
                                .fill(event.completionDate != nil ? .gray : .buttonGreen)
                                .frame(width: 12)
                            Text(event.completionDate != nil
                                 ? "Completed on \(Date().customDateFormat("dd MMMM yyyy").string(from: event.completionDate ?? Date()))"
                                 : "Ongoing Event"
                            )
                            .font(.tabiBody)
                        }
                }
            }
            Rectangle()
                .fill(Color(UIColor(hex: "#D9D9D9")))
                .frame(height: 1)
            HStack {
                HStack (spacing: -20) {
                    Image(.samplePersonProfile1)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40)
                        .clipShape(Circle())
                        .zIndex(3)
                    Image(.samplePersonProfile2)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40)
                        .clipShape(Circle())
                        .zIndex(2)
                    Image(.samplePersonProfile3)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40)
                        .clipShape(Circle())
                        .zIndex(1)
                }
                Spacer()
                Text(isNew ? "New Event" : status == .settled ? "\(status.statusDisplay)" : "\(status.statusDisplay) \(String(format: "%.0f", event.userEventBalance).formatPrice())")
                    .font(.tabiBody)
                    .padding(.vertical, UIConfig.Spacing.Small)
                    .padding(.horizontal, UIConfig.Spacing.Large)
                    .background(isNew ? .uiGray : status.statusColor)
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
    VStack {
        EventCard(
            event: EventData(eventName: "New York Trip", completionDate: nil, userEventBalance: 0)
        )
    }
}
