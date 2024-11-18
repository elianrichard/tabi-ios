//
//  ExpenseResultCustomCard.swift
//  Tabi Split
//
//  Created by Elian Richard on 06/11/24.
//

import SwiftUI

struct ExpenseResultCustomCard: View {
    @Environment(EventExpenseViewModel.self) private var eventExpenseViewModel
    var person: PersonItem
    
    var body: some View {
        VStack (spacing: .spacingTight) {
            HStack {
                UserAvatar(userData: person.user)
                Text("\(person.user.name.getFirstName())'s")
                    .font(.tabiHeadline)
                Spacer()
                Text("Rp\(eventExpenseViewModel.calculatePersonSpending(person: person).formatPrice())")
                    .font(.tabiHeadline)
            }
            
            Divider()
            
            VStack (spacing: .spacingXSmall) {
                ForEach (person.items) { item in
                    HStack(alignment: .top, spacing: .spacingRegular){
                        Text(item.itemName)
                            .font(.tabiHeadline)
                        Text("\(String(item.itemQuantity.rounded(toDecimalPlaces: 1)))x")
                            .font(.tabiBody)
                        Spacer()
                        Text("Rp\((Float(item.itemQuantity) * item.itemPrice).formatPrice())")
                            .font(.tabiBody)
                    }
                }
            }
            
            DisclosureGroup() {
                Divider()
                    .padding(.vertical, .spacingSmall)
                VStack (spacing: .spacingXSmall) {
                    ForEach(person.additional) { additionalItem in
                        HStack {
                            Text((AdditionalChargeType(rawValue: additionalItem.additionalChargeType) ?? .other).name)
                            Spacer()
                            Text("Rp\(additionalItem.amount.formatPrice())")
                        }
                        .font(.subheadline)
                    }
                }
            } label: {
                Text("See Details")
                    .font(.tabiBody)
            }
            .accentColor(.textBlack)
        }
        .padding(.vertical, .spacingTight)
        .padding(.horizontal, .spacingMedium)
        .background(.bgWhite)
        .clipShape(RoundedRectangle(cornerRadius: .radiusMedium))
        .overlay {
            RoundedRectangle(cornerRadius: .radiusMedium)
                .fill(.clear)
                .strokeBorder(.uiGray, lineWidth: 1)
        }
    }
}
