//
//  ExpenseResultView.swift
//  Tabi
//
//  Created by Dharmawan Ruslan on 08/10/24.
//

import Foundation
import SwiftUI

struct ExpenseResultView: View {
    @Environment(Routes.self) var routes
    @Environment(EventExpenseViewModel.self) var eventExpenseViewModel
    @Environment(EventViewModel.self) var eventViewModel
    
    @State private var contentSize: CGSize = .zero
    @State private var isShowReceiptSheet = false
    
    var body: some View {
        VStack (alignment: .leading) {
            TopNavigation(title: "Expense Result", RightToolbar: {
                if eventExpenseViewModel.selectedExpense != nil && !eventExpenseViewModel.isEdit {
                    ElipsisMenu {
                        Button {
                            eventExpenseViewModel.isEdit = true
                            routes.navigate(to: .AddExpenseView)
                        } label: {
                            Label("Edit Expense", systemImage: "pencil")
                        }
                        Button (role: .destructive) {
                            if let event = eventViewModel.selectedEvent {
                                eventExpenseViewModel.handleDeleteExpense(event)
                                routes.navigateBack()
                            }
                        } label: {
                            Label("Delete Expense", systemImage: "trash")
                        }
                    }
                }
            })
            
            VStack (alignment: .leading, spacing: .spacingSmall) {
                if eventExpenseViewModel.selectedExpense != nil && !eventExpenseViewModel.isEdit {
                    Text("\(Date().customDateFormat("dd MMM yyyy  HH:mm").string(from: eventExpenseViewModel.selectedExpense?.dateOfCreation ?? Date()))")
                        .font(.tabiBody)
                        .foregroundStyle(.textGrey)
                }
                VStack (alignment: .leading, spacing: .spacingTight) {
                    Text(eventExpenseViewModel.expenseName)
                        .font(.tabiTitle)
                    HStack {
                        Icon(eventExpenseViewModel.selectedMethod?.icon)
                        Text(eventExpenseViewModel.selectedMethod?.splitDescription ?? "")
                            .font(.tabiBody)
                    }
                    if eventExpenseViewModel.selectedExpense != nil && !eventExpenseViewModel.isEdit {
                        HStack (spacing: .spacingTight) {
                            Text("Rp\(eventExpenseViewModel.totalSpending.formatPrice())")
                                .font(.tabiHeadline)
                                .foregroundStyle(.buttonDarkBlue)
                            Rectangle()
                                .fill(.textGrey)
                                .frame(width: 1, height: 14)
                            Text("\(eventExpenseViewModel.selectedCoverer?.name ?? "") paid")
                                .font(.tabiBody)
                                .foregroundStyle(.textGrey)
                        }
                    }
                }
            }
            .padding([.bottom], 24)
            
            ScrollView(showsIndicators: false) {
                VStack (spacing: .spacingTight) {
                    if eventExpenseViewModel.selectedMethod == .equally {
                        ForEach(eventExpenseViewModel.selectedParticipants){ person in
                            ExpenseResultEqualCard(person: person)
                        }
                    } else if eventExpenseViewModel.selectedMethod == .custom {
                        ForEach(eventExpenseViewModel.peopleItems) { person in
                            VStack {
                                HStack {
                                    UserAvatar(userData: person.user)
                                    Text("\(person.name.getFirstName())'s")
                                        .font(.tabiHeadline)
                                    Spacer()
                                    Text("Rp\(eventExpenseViewModel.calculatePersonSpending(person: person).formatPrice())")
                                        .font(.tabiHeadline)
                                }
                                Divider()
                                    .padding(.vertical, 6)
                                ForEach (person.items) { item in
                                    HStack(alignment: .top){
                                        Text(item.itemName)
                                            .font(.tabiHeadline)
                                        Text("x" + String(item.itemQuantity.formatted(.number)))
                                            .font(.tabiBody)
                                        Spacer()
                                        Text("Rp \((Float(item.itemQuantity) * item.itemPrice).formatPrice())")
                                            .frame(width: 100, alignment: .trailing)
                                            .lineLimit(1)
                                            .font(.tabiBody)
                                    }
                                }
                                
                                DisclosureGroup() {
                                    Divider()
                                        .padding(.vertical, 6)
                                    ForEach(person.additional) { additionalItem in
                                        HStack {
                                            Text((AdditionalChargeType(rawValue: additionalItem.additionalChargeType) ?? .other).name)
                                            Spacer()
                                            Text("Rp \(additionalItem.amount.formatPrice())")
                                        }
                                        .font(.subheadline)
                                    }
                                } label: {
                                    HStack {
                                        Text("See Details")
                                            .font(.tabiBody)
                                    }
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
                }
                .overlay(
                    GeometryReader { geo in
                        Color.clear.onAppear {
                            contentSize = geo.size
                        }
                    }
                )
            }
            .frame(maxWidth: .infinity, maxHeight: contentSize.height)
            
            if eventExpenseViewModel.selectedExpense != nil && !eventExpenseViewModel.isEdit { CustomButton(text: "Check Purchase Receipt", type: .tertiary) {
                isShowReceiptSheet = true
            }
            .frame(maxWidth: .infinity, alignment: .center)
            }
            
            Spacer()
            
            if eventExpenseViewModel.selectedExpense == nil {
                CustomButton(text: "Save Expense") {
                    if let event = eventViewModel.selectedEvent {
                        eventExpenseViewModel.finalizeExpense(event)
                        routes.mutlipleNavigate(to: [.HomeView, .EventDetailView])
                    }
                }
            } else if eventExpenseViewModel.isEdit {
                CustomButton(text: "Save Expense") {
                    if let event = eventViewModel.selectedEvent {
                        eventExpenseViewModel.handleUpdateExpense(event)
                        eventExpenseViewModel.isEdit = false
                        routes.mutlipleNavigate(to: [.HomeView, .EventDetailView])
                    }
                }
            }
        }
        .padding()
        .addBackgroundColor(.bgBlueElevated)
        .sheet(isPresented: $isShowReceiptSheet) {
            VStack (spacing: 0) {
                HStack{
                    Spacer()
                    Button {
                        isShowReceiptSheet = false
                    } label : {
                        Icon(systemName: "xmark", color: .textGrey, size: 12)
                            .frame(width: 32, height: 32)
                            .background(.uiGray)
                            .clipShape(Circle())
                    }
                }
                VStack (alignment: .leading, spacing: .spacingMedium) {
                    Text("Purchase Receipt")
                        .font(.tabiTitle)
                    RoundedRectangle(cornerRadius: .radiusLarge)
                        .fill(.bgWhite)
                        .overlay {
                            Image(.samplePaymentReceipt)
                                .resizable()
                                .scaledToFit()
                                .padding(.spacingRegular)
                        }
                }
            }
            .padding()
            .addBackgroundColor(.bgBlueElevated)
            .presentationDetents([.height(700)])
            .presentationDragIndicator(.visible)
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    ExpenseResultView()
        .environment(Routes())
        .environment(EventViewModel())
        .environment(EventExpenseViewModel())
}
