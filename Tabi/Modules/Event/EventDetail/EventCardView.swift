//
//  EventCardView.swift
//  Tabi
//
//  Created by Elian Richard on 04/10/24.
//

import SwiftUI

struct EventCardView : View {
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
                Circle()
                    .fill(Color(UIColor(hex: "#D9D9D9")))
                    .frame(width: 40)
                VStack (alignment: .leading, spacing: 4) {
                    Text("\(event.eventName)")
                        .font(.body)
                        HStack (spacing: 8) {
                            Circle()
                                .fill(event.completionDate != nil ? .gray : .green)
                                .frame(width: 10)
                            Text(event.completionDate != nil
                                 ? "Completed on \(Date().customDateFormat("dd MMMM yyyy").string(from: event.completionDate ?? Date()))"
                                 : "Ongoing Event"
                            ).font(.caption)
                        }
                }
            }
            Rectangle()
                .fill(Color(UIColor(hex: "#D9D9D9")))
                .frame(height: 1)
            HStack (spacing: 32) {
                HStack (spacing: -20) {
                    Circle()
                        .fill(Color(UIColor(hex: "#C2C2C2")))
                        .frame(width: 40)
                    Circle()
                        .fill(Color(UIColor(hex: "#D3D3D3")))
                        .frame(width: 40)
                    Circle()
                        .fill(Color(UIColor(hex: "#D9D9D9")))
                        .frame(width: 40)
                    
                }
                Text(isNew ? "New Event" : status == .settled ? "\(status.statusDisplay)" : "\(status.statusDisplay) \(String(format: "%.0f", event.userEventBalance).formatPrice())")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(isNew ? .white : status.statusColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor(hex: "#EBEBEB")))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    EventCardView(
        event: EventData(eventName: "New York Trip", completionDate: nil, userEventBalance: 0)
    )
}
