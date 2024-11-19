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
    @Environment(Routes.self) private var routes
    @State var viewModel: AddExpenseViewModel = AddExpenseViewModel()
    @State var hasPreviewed: Bool = false
    
    @FocusState private var focusedField: FocusField?
    
    var body: some View {
        VStack (spacing: .spacingRegular) {
            TopNavigation(title: "Add New Expenses", additionalBackFunction: {
                eventExpenseViewModel.isEdit = false
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
                        items: eventViewModel.selectedEvent?.participants ?? [],
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
                                           price: Bindable( eventExpenseViewModel).expenseTotalInput,
                                           errorMessage: viewModel.totalBillError,
                                           focusedField: $focusedField,
                                           focusCase: .field2
                            )
                        }
                    } // Input nominal kalau equally
                    if !eventExpenseViewModel.isQuickScanned {
                        VStack(alignment: .leading, spacing: 8){
                            HStack(spacing: 0){
                                Text("Purchase Receipt ")
                                    .font(.tabiBody)
                                Text("(optional)")
                                    .font(.tabiBody)
                                    .foregroundColor(.textGrey)
                            }
                            HStack(spacing: 0){
                                CustomButton(text: eventExpenseViewModel.uploadedReceiptImage == nil ? "Upload Image" : "Uploaded Image", type: .tertiary, icon: eventExpenseViewModel.uploadedReceiptImage == nil ? "square.and.arrow.up" : "photo", iconSize: 20, customTextColor: .buttonBlue){
                                    viewModel.toggleReceiptSheet.toggle()
                                }
                                .lineLimit(1)
                                
                                if eventExpenseViewModel.uploadedReceiptImage != nil{
                                    Button{
                                        eventExpenseViewModel.uploadedReceiptImage = nil
                                    }label:{
                                        Icon(systemName: "xmark", color: .textGrey, size: 10)
                                    }
                                    .padding(.trailing, .spacingRegular)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: .infinity))
                            .font(.tabiHeadline)
                            .overlay {
                                RoundedRectangle(cornerRadius: .infinity)
                                    .fill(.clear)
                                    .stroke(.buttonBlue, lineWidth: 1.5)
                                    .padding(1.5)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else if eventExpenseViewModel.selectedMethod == .custom {
                        VStack (alignment: .leading, spacing: 16) {
                            Text("Items")
                                .font(.tabiHeadline)
                            ForEach(Array(eventExpenseViewModel.items.enumerated()), id: \.offset) { index, item in
                                AddItemContainer(item: Bindable(eventExpenseViewModel).items[index], index: index)
                            }
                            
                            HStack{
                                CustomButton(text: "+ Add Item", type: .secondary) {
                                    eventExpenseViewModel.createNewExpenseItem()
                                }
                                .frame(width: 120)
                            }
                            .frame(maxWidth: .infinity)
                            
                            Divider()
                                .padding(.horizontal, 16)
                            
                            VStack (alignment: .leading, spacing: 16) {
                                HStack(spacing: 0){
                                    Text("Additional Charge ")
                                        .font(.tabiBody)
                                    Text("(optional)")
                                        .font(.tabiBody)
                                        .foregroundColor(.textGrey)
                                }
                                VStack(alignment: .leading){
                                    ForEach(Array(eventExpenseViewModel.additionalCharges.enumerated()), id: \.offset) { index, item in
                                        AdditionalChargeContainer(item: Bindable(eventExpenseViewModel).additionalCharges[index])
                                    }
                                }
                                CustomButton(text: "+ Add More", type: .tertiary, vPadding: 0){
                                    eventExpenseViewModel.additionalCharges.append(AdditionalCharge(additionalChargeType: .tax, amount: 0))
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            
            if !eventExpenseViewModel.isQuickScanned || eventExpenseViewModel.selectedMethod == .equally {
                CustomButton(text: "Next") {
                    viewModel.validateInput()
                    if (eventExpenseViewModel.selectedMethod == .custom && viewModel.isValid) {
                        routes.navigate(to: .ExpenseAddItemsView)
                    } else if (eventExpenseViewModel.selectedMethod == .equally && viewModel.isValid) {
                        eventExpenseViewModel.totalSpending = eventExpenseViewModel.expenseTotalInput
                        routes.navigate(to: .ExpenseResultView)
                    }
                }
            }else{
                ZStack{
                    HStack(alignment: .top){
                        Text("Total")
                            .font(.tabiBody)
                        Spacer()
                        Text("Rp\(eventExpenseViewModel.totalSpending.formatPrice())")
                            .font(.tabiHeadline)
                    }
                    .padding(16)
                    .background{
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.bgBlueElevated)
                            .stroke(.buttonBlueSelected, lineWidth: 1)
                            .frame(maxWidth: .infinity)
                            .frame(height: 90)
                            .offset(CGSize(width: 0, height: 15))
                            .zIndex(1)
                    }
                    .offset(CGSize(width: 0, height: -50))
                        .zIndex(1)
                    CustomButton(text: "Next", isEnabled: eventExpenseViewModel.items.map({$0.itemPrice}).reduce(0, +) != 0, customBackgroundColor: eventExpenseViewModel.items.map({$0.itemPrice}).reduce(0, +) != 0 ? .buttonBlue : .buttonGrey) {
                        viewModel.validateInput()
                        if viewModel.isValid{
                            routes.navigate(to: .ExpenseAssignView)
                        }
                    }
                    .zIndex(2)
                }
                .padding([.top], 60)
            }
        }
        .onAppear{
            if eventExpenseViewModel.isQuickScanned && eventExpenseViewModel.selectedMethod == nil{
                eventExpenseViewModel.selectedMethod = .custom
            }
            hasPreviewed = false
            viewModel = AddExpenseViewModel(eventExpenseViewModel: eventExpenseViewModel)
            if eventExpenseViewModel.selectedParticipants == [] {
                eventExpenseViewModel.selectedParticipants = eventViewModel.selectedEvent?.participants ?? []
            }
        }
        .sheet(isPresented: Bindable(viewModel).toggleSeeAll) {
            ShowAllParticipants(isPresented: Bindable(viewModel).toggleSeeAll)
                .presentationDetents(
                    [.medium, .large],
                    selection: Bindable(viewModel).settingsDetent
                )
        }
        .sheet(isPresented: Bindable(viewModel).toggleReceiptSheet){
            ReceiptUploadSheet(height: $viewModel.receiptSheetHeight, isPresented: Bindable(viewModel).toggleReceiptSheet)
                .presentationDetents([.height(viewModel.receiptSheetHeight)])
        }
        .onChange(of: eventExpenseViewModel.uploadedReceiptImage){
            if !hasPreviewed && eventExpenseViewModel.uploadedReceiptImage != nil{
                hasPreviewed.toggle()
                routes.navigate(to: .ReceiptUploadReview)
            }
        }
        .padding()
        .addBackgroundColor(.bgWhite) {
            focusedField = nil
        }
        .navigationBarBackButtonHidden(true)
    }
}


#Preview {
    AddExpenseView()
        .environment(Routes())
        .environment(EventViewModel())
        .environment(EventExpenseViewModel())
}
