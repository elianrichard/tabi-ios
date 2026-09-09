//
//  AddExpense.swift
//  Tabi
//
//  Created by Dharmawan Ruslan on 02/10/24.
//

import Foundation
import SwiftUI
import PhotosUI
import Combine

struct AddExpenseView: View {
    @Environment(EventViewModel.self) private var eventViewModel
    @Environment(EventExpenseViewModel.self) private var eventExpenseViewModel
    @Environment(Router.self) private var router
    @State var viewModel: AddExpenseViewModel = AddExpenseViewModel()
    @State var hasPreviewed: Bool = false
    @State private var isShowReceiptPreview: Bool = false

    @FocusState private var focusedField: FocusField?
    
    var body: some View {
        VStack (spacing: .spacingRegular) {
            TopNavigation(title: eventExpenseViewModel.isEdit ? "Edit Expense" : "Add New Expenses", additionalBackFunction: {
                eventExpenseViewModel.isEdit = false
                if !eventExpenseViewModel.isQuickScanned {                
                    eventExpenseViewModel.uploadedReceiptImage = nil
                }
            })
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    InputWithLabel(label: "Expense Name",
                                   placeholder: "Enter expense name",
                                   text: Bindable(eventExpenseViewModel).expenseName,
                                   errorMessage: viewModel.expenseNameError,
                                   focusedField: $focusedField,
                                   focusCase: .field1
                    )
                    DropDownInput(
                        label: "Paid By",
                        placeholder: "Choose who paid",
                        items: eventViewModel.selectedEvent?.participants.sorted(by: { $0.name < $1.name }) ?? [],
                        keyPath: \UserData.name,
                        backgroundColor: .bgWhite,
                        cornerRadius: 16,
                        selectedItem: Bindable(eventExpenseViewModel).selectedCoverer,
                        errorMessage: viewModel.paidByError
                    )
                    VStack(alignment: .leading, spacing: 8){
                        HStack{
                            Text("Participants")
                                .font(.tabiBody)
                            Spacer()
                        }
                        HStack(alignment: .center){
                            if eventExpenseViewModel.selectedParticipants != [] {
                                
                                HStack (spacing: -6) {
                                    ForEach(Array(eventExpenseViewModel.selectedParticipants.enumerated()), id: \.offset) { index, user in
                                        if (index < 4) {
                                            if (eventExpenseViewModel.selectedParticipants.count > 4 && index == 3) {
                                                Circle()
                                                    .fill(.uiGray)
                                                    .frame(width: 40)
                                                    .overlay {
                                                        Text("+\(eventExpenseViewModel.selectedParticipants.count - 3)")
                                                            .font(.tabiBody)
                                                    }
                                            } else {
                                                UserAvatar(userData: user)
                                                    .zIndex(Double(4-index))
                                            }
                                        }
                                    }
                                    if (eventExpenseViewModel.selectedParticipants.count < 4) {
                                        ForEach(Array(0 ..< (4-eventExpenseViewModel.selectedParticipants.count)), id: \.self) { _ in
                                            Circle()
                                                .frame(width: 40)
                                                .opacity(0)
                                        }
                                    }
                                }
                                Spacer()
                                Button{
                                    viewModel.toggleSeeAll.toggle()
                                }label:{
                                    HStack{
                                        Text("Edit")
                                            .font(.tabiBody)
                                            .foregroundColor(.textBlue)
                                        Icon(systemName: "chevron.right", color: .textBlue, size: 18)
                                    }
                                }
                            }else{
                                Button{
                                    viewModel.toggleSeeAll.toggle()
                                }label:{
                                    HStack{
                                        Text("Select Participants")
                                            .font(.tabiBody)
                                            .foregroundColor(.textBlue)
                                        Spacer()
                                        Icon(systemName: "chevron.right", color: .textBlue, size: 18)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                        .background(.bgWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.black)
                        .font(.tabiBody)
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.clear)
                                .stroke(viewModel.participantsError != nil ? .buttonRed : .bgGreyOverlay, lineWidth: 0.5)
                                .padding(0.5)
                        }
                        if let message = viewModel.participantsError {
                            Text(message)
                                .font(.tabiBody)
                                .foregroundStyle(.buttonRed)
                        }
                    } // Participants
                    DropDownInput(
                        label: "Split Bill Method",
                        placeholder: "Choose split bill method",
                        items: SplitMethod.allCases,
                        keyPath: \.splitName,
                        backgroundColor: .bgWhite,
                        cornerRadius: 16,
                        selectedItem: Bindable(eventExpenseViewModel).selectedMethod,
                        errorMessage: viewModel.splitBillMethodError
                    )
                    if eventExpenseViewModel.selectedMethod ==  .equally {
                        VStack(alignment: .leading){
                            InputWithLabel(label: "Total Bill",
                                           placeholder: "0",
                                           price: Bindable(eventExpenseViewModel).expenseTotalInput,
                                           errorMessage: viewModel.totalBillError,
                                           focusedField: $focusedField,
                                           focusCase: .field2
                            )
                        }
                    } // Input nominal kalau equally
                    // Receipt field shown in both flows. In quick scan the scanned
                    // image is already attached (hasReceipt == true) and appears here
                    // so it's persisted with the expense and can be viewed/changed.
                    VStack(alignment: .leading, spacing: 8){
                        HStack(spacing: 0){
                            Text("Purchase Receipt ")
                                .font(.tabiBody)
                            Text("(optional)")
                                .font(.tabiBody)
                                .foregroundColor(.textGrey)
                        }
                        HStack(spacing: .spacingRegular){
                            CustomButton(text: eventExpenseViewModel.hasReceipt ? "Uploaded Image" : "Upload Image", type: .tertiary, icon: eventExpenseViewModel.hasReceipt ? "photo" : "square.and.arrow.up", iconSize: 20, customTextColor: .buttonBlue){
                                // With a receipt attached, the button previews it;
                                // removing (Clear) is the way to replace it. Without
                                // one, it opens the upload sheet.
                                if eventExpenseViewModel.hasReceipt {
                                    isShowReceiptPreview = true
                                } else {
                                    viewModel.toggleReceiptSheet.toggle()
                                }
                            }
                            .lineLimit(1)
                            .font(.tabiHeadline)
                            .overlay {
                                RoundedRectangle(cornerRadius: .infinity)
                                    .fill(.clear)
                                    .stroke(.buttonBlue, lineWidth: 1.5)
                                    .padding(1.5)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: .infinity))

                            // Clear button — beside the upload button. Removes the
                            // receipt so a different one can be attached.
                            if eventExpenseViewModel.hasReceipt {
                                Button{
                                    eventExpenseViewModel.uploadedReceiptImage = nil
                                    eventExpenseViewModel.uploadedReceiptId = nil
                                }label:{
                                    HStack(spacing: 4){
                                        Icon(systemName: "xmark", color: .buttonRed, size: 10)
                                        Text("Clear")
                                            .font(.tabiBody2)
                                            .foregroundStyle(.buttonRed)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            // One flow for both manual and quick scan: custom → items page (items
            // pre-filled by OCR for quick scan), equally → result.
            CustomButton(text: "Next") {
                viewModel.validateInput()
                if (eventExpenseViewModel.selectedMethod == .custom && viewModel.isValid) {
                    print("[AddExpense] Next (custom) — image=\(eventExpenseViewModel.uploadedReceiptImage != nil), ocrLines=\(eventExpenseViewModel.lastOCRLines.count), isQuickScanned=\(eventExpenseViewModel.isQuickScanned)")
                    // Custom split with an attached image → OCR (if not done yet)
                    // then AI-refine, for any entry point (manual attach, quick scan,
                    // or a shared receipt). Skipped on edit without a re-upload
                    // (no image present, only the stored id).
                    if eventExpenseViewModel.uploadedReceiptImage != nil {
                        Task {
                            eventExpenseViewModel.runOCRIfNeeded()
                            await eventExpenseViewModel.refineReceiptWithAI()
                            router.push(.expenseAddItems)
                        }
                    } else {
                        router.push(.expenseAddItems)
                    }
                } else if (eventExpenseViewModel.selectedMethod == .equally && viewModel.isValid) {
                    eventExpenseViewModel.totalSpending = eventExpenseViewModel.expenseTotalInput
                    router.push(.expenseResult)
                }
            }
        }
        .onAppear{
            if eventExpenseViewModel.isQuickScanned && eventExpenseViewModel.selectedMethod == nil{
                eventExpenseViewModel.selectedMethod = .custom
            }
            hasPreviewed = false
            // A receipt shared into the app: attach it here (not during navigation)
            // and mark it previewed so the onChange below doesn't push the review
            // screen — the image just sits in the receipt field.
            if let shared = eventExpenseViewModel.pendingSharedReceiptImage {
                // Mark previewed BEFORE attaching so the onChange below cannot push
                // the review screen for a shared receipt.
                hasPreviewed = true
                eventExpenseViewModel.pendingSharedReceiptImage = nil
                eventExpenseViewModel.attachReceiptImage(shared)
                print("[AddExpense] attached shared receipt \(Int(shared.size.width))x\(Int(shared.size.height)) — hasReceipt=\(eventExpenseViewModel.hasReceipt)")
            }
            viewModel = AddExpenseViewModel(eventExpenseViewModel: eventExpenseViewModel)
            if eventExpenseViewModel.selectedParticipants == [] {
                eventExpenseViewModel.selectedParticipants = eventViewModel.selectedEvent?.participants ?? []
            }
        }
        .sheet(isPresented: Bindable(viewModel).toggleSeeAll) {
            SelectParticipantsSheet(isPresented: Bindable(viewModel).toggleSeeAll)
                .presentationDetents(
                    [.medium, .large],
                    selection: Bindable(viewModel).settingsDetent
                )
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: Bindable(viewModel).toggleReceiptSheet){
            ReceiptUploadSheet(height: $viewModel.receiptSheetHeight, isPresented: Bindable(viewModel).toggleReceiptSheet)
                .presentationDetents([.height(viewModel.receiptSheetHeight)])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $isShowReceiptPreview) {
            // Preview the attached receipt: local image (create) or stored id (edit).
            if let image = eventExpenseViewModel.uploadedReceiptImage {
                ReceiptViewerView(image: image, isPresented: $isShowReceiptPreview)
            } else if let id = eventExpenseViewModel.uploadedReceiptId, !id.isEmpty {
                ReceiptViewerView(receiptId: id, isPresented: $isShowReceiptPreview)
            }
        }
        .onChange(of: eventExpenseViewModel.uploadedReceiptImage){
            if !hasPreviewed && eventExpenseViewModel.uploadedReceiptImage != nil{
                hasPreviewed.toggle()
                router.push(.receiptUploadReview)
            }
        }
        .padding()
        .addBackgroundColor(.bgWhite) {
            focusedField = nil
        }
        .onAppear {
            focusedField = .field1
        }
        .navigationBarBackButtonHidden(true)
    }
}


#Preview {
    AddExpenseView()
        .environment(Router())
        .environment(EventViewModel())
        .environment(EventExpenseViewModel())
}
