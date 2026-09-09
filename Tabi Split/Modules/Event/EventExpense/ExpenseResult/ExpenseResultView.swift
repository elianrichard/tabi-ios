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

    /// The stored receipt image id for this expense, if any. Prefers the saved
    /// expense's value; falls back to the just-uploaded id during the add flow.
    private var receiptId: String? {
        let id = eventExpenseViewModel.selectedExpense?.receiptId
            ?? eventExpenseViewModel.uploadedReceiptId
        guard let id, !id.isEmpty else { return nil }
        return id
    }

    /// Whether any receipt can be shown: a stored id, or the freshly picked local
    /// image in the add flow that hasn't been uploaded yet (so has no id).
    /// Drives the "See Receipt" button at the bottom of the page.
    private var hasReceipt: Bool {
        receiptId != nil || eventExpenseViewModel.uploadedReceiptImage != nil
    }
    
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

                // Metadata chips: split method (yellow) + coverer (green). The
                // receipt is opened from the "See Receipt" button at the bottom.
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
            
            Spacer()

            // Bottom actions: See Receipt (when one is attached) sits above the
            // Save button in the add/edit flow, and alone on the saved result.
            if hasReceipt {
                CustomButton(text: "See Receipt", type: .secondary, icon: "doc.text.image") {
                    isShowReceiptSheet = true
                }
            }

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
                                // Successful create is a natural "felt value"
                                // moment — maybe ask for an App Store rating.
                                RatingPromptManager.shared.registerSuccessfulExpense()
                                return
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .addBackgroundColor(.bgWhite)
        .fullScreenCover(isPresented: $isShowReceiptSheet) {
            // Same precedence as ExpenseHeaderView: the just-picked local image
            // (add flow, not yet uploaded) before the stored id.
            if let image = eventExpenseViewModel.uploadedReceiptImage {
                ReceiptViewerView(image: image, isPresented: $isShowReceiptSheet)
            } else if let receiptId {
                ReceiptViewerView(receiptId: receiptId, isPresented: $isShowReceiptSheet)
            }
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
