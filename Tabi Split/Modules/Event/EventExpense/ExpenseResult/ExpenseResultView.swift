//
//  ExpenseResultView.swift
//  Tabi
//
//  Created by Dharmawan Ruslan on 08/10/24.
//

import Foundation
import SwiftUI

struct ExpenseResultView: View {
    @Environment(Router.self) var router
    @Environment(EventExpenseViewModel.self) var eventExpenseViewModel
    @Environment(ProfileViewModel.self) var profileViewModel
    @Environment(EventViewModel.self) var eventViewModel
    
    @State private var contentSize: CGSize = .zero
    @State private var isShowReceiptSheet = false
    
    var body: some View {
        VStack (alignment: .leading) {
            TopNavigation(title: "Expense Result", RightToolbar: {
                // Only the expense's creator or the event owner may edit/delete it.
                if !eventExpenseViewModel.isEditView && !eventViewModel.isEventCompleted && canManageExpense {
                    ElipsisMenu {
                        Button {
                            eventExpenseViewModel.isEdit = true
                            eventExpenseViewModel.isQuickScanned = false
                            router.push(.addExpense)
                        } label: {
                            Label("Edit Expense", systemImage: "pencil")
                        }
                        Button (role: .destructive) {
                            Task {
                                if await eventExpenseViewModel.handleDeleteExpense(event: eventViewModel.selectedEvent){
                                    router.pop()
                                }
                            }
                        } label: {
                            Label("Delete Expense", systemImage: "trash")
                        }
                    }
                }
            })
            
            VStack (alignment: .leading, spacing: .spacingRegular) {
                // Title + timestamp
                VStack (alignment: .leading, spacing: .spacingXSmall) {
                    if !eventExpenseViewModel.isEditView {
                        Text("\(Date().customDateFormat("dd MMM yyyy  •  HH:mm").string(from: eventExpenseViewModel.selectedExpense?.dateOfCreation ?? Date()))")
                            .font(.tabiBody)
                            .foregroundStyle(.textGrey)
                    }
                    Text(eventExpenseViewModel.expenseName)
                        .font(.tabiTitle)
                        .foregroundStyle(.textBlack)
                }

                // Hero total (result view only) + who paid.
                if !eventExpenseViewModel.isEditView {
                    VStack (alignment: .leading, spacing: .spacingXSmall) {
                        Text("Total spending")
                            .font(.tabiBody)
                            .foregroundStyle(.textGrey)
                        Text("Rp\(eventExpenseViewModel.totalSpending.formatPrice())")
                            .font(.tabiLargeTitle)
                            .foregroundStyle(.buttonDarkBlue)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.spacingRegular)
                    .background(.bgBlueElevated)
                    .clipShape(RoundedRectangle(cornerRadius: .radiusMedium))
                }

                // Metadata chips: split method (yellow) + coverer (green).
                HStack (spacing: .spacingSmall) {
                    if let method = eventExpenseViewModel.selectedMethod {
                        Nugget(text: method.splitDescription, icon: .resource(method.icon), color: .yellow)
                    }
                    if !eventExpenseViewModel.isEditView, let coverer = eventExpenseViewModel.selectedCoverer {
                        Nugget(text: "\(coverer.name.getFirstName()) paid", icon: .system("person.fill"), color: .green)
                    }
                }
            }
            .padding([.bottom], 24)
            
            ScrollView(showsIndicators: false) {
                VStack (spacing: .spacingTight) {
                    if eventExpenseViewModel.selectedMethod == .equally {
                        if eventExpenseViewModel.selectedParticipants.contains(where: { profileViewModel.isCurrentUser($0) }) {
                            ExpenseResultEqualCard(person: profileViewModel.user)
                        }
                        ForEach(eventExpenseViewModel.selectedParticipants.filter { !profileViewModel.isCurrentUser($0) }) { person in
                            ExpenseResultEqualCard(person: person)
                        }
                    } else if eventExpenseViewModel.selectedMethod == .custom {
                        if let currentPersonItem = eventExpenseViewModel.peopleItems.first(where: { profileViewModel.isCurrentUser($0.user) }) {
                            ExpenseResultCustomCard(person: currentPersonItem)
                        }
                        ForEach(eventExpenseViewModel.peopleItems.filter { !profileViewModel.isCurrentUser($0.user) }) { person in
                            ExpenseResultCustomCard(person: person)
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
            //            .frame(maxWidth: .infinity, maxHeight: contentSize.height)
            
            //            TEMPORARILY DISABLED: UPLOAD IMAGE RECEIPT
            if (false) {
                if !eventExpenseViewModel.isEditView {
                    CustomButton(text: "Check Purchase Receipt", type: .tertiary) {
                        isShowReceiptSheet = true
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            
            Spacer()
            
            if let event = eventViewModel.selectedEvent, eventExpenseViewModel.isEditView {
                CustomButton(text: "Save Expense") {
                    Task {
                        if eventExpenseViewModel.isEdit {
                            if await eventExpenseViewModel.handleUpdateExpense(event: event) {
                                eventExpenseViewModel.isEdit = false
                                router.popToRoot()
                                router.push(.eventDetail)
                            }
                        } else {
                            if await eventExpenseViewModel.finalizeExpense(event) {
                                router.popToRoot()
                                router.push(.eventDetail)
                                return
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .addBackgroundColor(.bgWhite)
        .sheet(isPresented: $isShowReceiptSheet) {
            VStack (spacing: 0) {
                SheetXButton(toggle: $isShowReceiptSheet)
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
            .addBackgroundColor(.bgWhite)
            .presentationDetents([.height(700)])
            .presentationDragIndicator(.visible)
        }
        .navigationBarBackButtonHidden(true)
    }

    /// Whether the current user may edit or delete this expense: they created it
    /// or they own the event. Falls back to the coverer for legacy expenses that
    /// have no stored creator (e.g. rows imported before the field existed).
    private var canManageExpense: Bool {
        let creator = eventExpenseViewModel.selectedExpense?.creator
            ?? eventExpenseViewModel.selectedCoverer
        let isCreator = creator.map { profileViewModel.isCurrentUser($0) } ?? false
        return isCreator || eventViewModel.isUserCreator
    }
}

#Preview {
    ExpenseResultView()
        .environment(Router())
        .environment(EventViewModel())
        .environment(EventExpenseViewModel())
        .environment(ProfileViewModel())
}
