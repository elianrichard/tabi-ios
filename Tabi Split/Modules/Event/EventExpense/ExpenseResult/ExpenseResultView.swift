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
                if !eventExpenseViewModel.isEditView {
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
                if !eventExpenseViewModel.isEditView {
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
                    if !eventExpenseViewModel.isEditView {
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
                    if eventExpenseViewModel.isEdit {
                        eventExpenseViewModel.handleUpdateExpense(event)
                        eventExpenseViewModel.isEdit = false
                    } else {
                        eventExpenseViewModel.finalizeExpense(event)
                    }
                    routes.mutlipleNavigate(to: [.HomeView, .EventDetailView])
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
}

#Preview {
    ExpenseResultView()
        .environment(Routes())
        .environment(EventViewModel())
        .environment(EventExpenseViewModel())
}
