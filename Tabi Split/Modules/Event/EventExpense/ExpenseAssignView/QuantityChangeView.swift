//
//  QuantityChangeView.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 22/10/24.
//

import Foundation
import SwiftUI

struct QuantityChangeView: View {
    @Environment(EventExpenseViewModel.self) private var eventExpenseViewModel
    @Environment(ProfileViewModel.self) private var profileViewModel
    @Binding var item: ExpenseItem
    @Binding var close: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            SheetXButton(toggle: $close)
            VStack(alignment: .leading, spacing: .spacingMedium) {
                VStack(alignment: .leading, spacing: .spacingXSmall) {
                    Text(item.itemName)
                        .font(.tabiTitle)
                    Text("Quantity: " + String(item.itemQuantity.formatted(.number)))
                        .font(.tabiBody)
                        .foregroundStyle(.textGrey)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: .spacingTight) {
                        ForEach(Array(item.assignees.enumerated()), id: \.offset) { (index, assignee) in
                            HStack(alignment: .center){
                                UserAvatar(userData: assignee.user, size: 40)
                                    .padding([.trailing], 12)
                                HStack(spacing: 0){
                                    Text(assignee.user.name.getFirstTwoWords())
                                        .font(.tabiHeadline)
                                        .lineLimit(1)
                                    if profileViewModel.user == assignee.user {
                                        Text(" (You)")
                                            .font(.tabiBody)
                                            .foregroundColor(.textGrey)
                                    }
                                }
                                Spacer()
                                QuantityCounter(quantity: Bindable(assignee).share, letZero: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(.bgWhite)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.clear)
                                    .stroke(.bgGreyOverlay, lineWidth: 0.5)
                                    .padding(0.5)
                            }
                        }
                    }
                }

                CustomButton(text: "Save") {
                    close.toggle()
                }
            }
        }
        .onDisappear{
            eventExpenseViewModel.removeZeroShareAssignee(item: item)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .padding([.top], 10)
        .addBackgroundColor(.bgWhite)
    }
}

#Preview {
    QuantityChangeView(item: .constant(ExpenseItem(itemName: "Teh tarik", itemPrice: 10000, itemQuantity: 10, assignees: [ExpensePerson(user: UserData(name: "Darma", email: ""), share: 1), ExpensePerson(user: UserData(name: "Eko", email: ""), share: 2)])), close: .constant(true))
        .environment(EventExpenseViewModel())
}
