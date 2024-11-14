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
    
    var body: some View {
        VStack (spacing: .spacingRegular) {
            TopNavigation(title: "Add New Expenses")
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20){
                    InputWithLabel(label: "Expense Name",
                                   placeholder: "Expense Name",
                                   text: Bindable(eventExpenseViewModel).expenseName,
                                   errorMessage: viewModel.expenseNameError,
                                   inputBackgroundColor: .bgWhite,
                                   inputCornerRadius: 16
                    )
                    DropDownInput(
                        label: "Paid by",
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
                        placeholder: "Split by",
                        items: SplitMethod.allCases,
                        keyPath: \.splitDescription,
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
                                           inputBackgroundColor: .bgWhite,
                                           inputCornerRadius: 16)
                        }
                    } // Input nominal kalau equally
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
                }
            }
            
            CustomButton(text: "Next") {
                viewModel.validateInput()
                if (eventExpenseViewModel.selectedMethod == .custom && viewModel.isValid) {
                    routes.navigate(to: .ExpenseAddItemsView)
                } else if (eventExpenseViewModel.selectedMethod == .equally && viewModel.isValid) {
                    eventExpenseViewModel.totalSpending = eventExpenseViewModel.expenseTotalInput
                    routes.navigate(to: .ExpenseResultView)
                }
            }
        }
        .onAppear{
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
        .background(.bgWhite)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    AddExpenseView()
        .environment(Routes())
        .environment(EventViewModel())
        .environment(EventExpenseViewModel())
}
