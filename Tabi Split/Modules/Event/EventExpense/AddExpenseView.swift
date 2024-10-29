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
    @State var viewModel: AddExpenseViewModel?
    
    var body: some View {
        VStack (spacing: .spacingRegular) {
            TopNavigation(title: "Add New Expenses")
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20){
                    InputWithLabel(label: "Expense Name",
                                   placeholder: "Expense Name",
                                   text: Bindable(eventExpenseViewModel).expenseName,
                                   errorMessage: viewModel?.expenseNameError,
                                   inputBackgroundColor: .bgWhite,
                                   inputCornerRadius: 16
                                   )
                    //              .onSubmit(registerViewModel.validateName)
                    DropDownInput(
                        label: "Paid by",
                        items: eventViewModel.selectedEvent?.participants ?? [],
                        keyPath: \UserData.name,
                        backgroundColor: .bgWhite,
                        cornerRadius: 16,
                        selectedItem: Bindable(eventExpenseViewModel).selectedCoverer,
                        errorMessage: viewModel?.paidByError
                    )
                    VStack(alignment: .leading, spacing: 8){
                        HStack{
                            Text("Select Participants")
                                .font(.tabiBody)
                            Spacer()
                            Button{
                                viewModel?.toggleSeeAll.toggle()
                            }label: {
                                Text("See All")
                                    .font(.tabiBody)
                            }
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .center){
                                ForEach(eventViewModel.selectedEvent?.participants ?? []) { person in
                                    VStack(alignment: .center){
                                        Circle()
                                            .frame(width: 40, height: 40)
                                            .padding(5)
                                            .background{
                                                Circle()
                                                    .frame(width: 50, height: 50)
                                                    .foregroundColor(.buttonGreen)
                                                    .opacity(!eventExpenseViewModel.selectedParticipants.contains(person) ? 0 : 1)
                                                Circle()
                                                    .frame(width: 45, height: 45)
                                                    .foregroundColor(.bgWhite)
                                                    .opacity(!eventExpenseViewModel.selectedParticipants.contains(person) ? 0 : 1)
                                            }
                                        Text(person.name.getFirstName())
                                            .font(.subheadline)
                                            .lineLimit(1)
                                    }
                                    .onTapGesture {
                                        if !eventExpenseViewModel.selectedParticipants.contains(person){
                                            eventExpenseViewModel.selectedParticipants.append(person)
                                        } else {
                                            if let removeIndex = eventExpenseViewModel.selectedParticipants.firstIndex(of: person) {
                                                eventExpenseViewModel.selectedParticipants.remove(at: removeIndex)
                                            }
                                        }
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
                                .stroke(viewModel?.participantsError != nil ? .buttonRed : .bgGreyOverlay, lineWidth: 0.5)
                        }
                        if let message = viewModel?.participantsError {
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
                        errorMessage: viewModel?.splitBillMethodError
                    )
                    if eventExpenseViewModel.selectedMethod ==  .equally {
                        VStack(alignment: .leading){
                            InputWithLabel(label: "Total Bill",
                                           placeholder: "0",
                                           price: Bindable( eventExpenseViewModel).expenseTotalInput,
                                           errorMessage: viewModel?.totalBillError,
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
                        VStack(spacing: 10){
                            Image(systemName: "photo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 30)
                                .foregroundColor(.gray)
                            Text("Upload an image")
                                .foregroundColor(.gray)
                        }
                        .opacity(eventExpenseViewModel.uploadedReceiptImage != nil ? 0 : 1)
                        .frame(height: 150)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.black)
                        .font(.tabiBody)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                        .background{
                            if eventExpenseViewModel.uploadedReceiptImage != nil{
                                Image(uiImage: eventExpenseViewModel.uploadedReceiptImage ?? UIImage())
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            }else{
                                Color(.bgWhite)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.clear)
                                            .stroke(.bgGreyOverlay, lineWidth: 0.5)
                                    }
                            }
                        }
                        .cornerRadius(16)
                        .onTapGesture {
                            routes.navigate(to: .ReceiptUploadView)
                        }
                        .contentShape(Rectangle())
                    }
                }
            }
            
            CustomButton(text: "Next") {
                viewModel?.validateInput()
                if let isValid = viewModel?.isValid {
                    if (eventExpenseViewModel.selectedMethod == .custom && isValid) {
                        routes.navigate(to: .ExpenseAddItemsView)
                    } else if (eventExpenseViewModel.selectedMethod == .equally && isValid) {
                        eventExpenseViewModel.totalSpending = eventExpenseViewModel.expenseTotalInput
                        routes.navigate(to: .ExpenseResultView)
                    }
                }
            }
        }
        .onAppear{
            viewModel = AddExpenseViewModel(eventExpenseViewModel: eventExpenseViewModel)
        }
        .sheet(isPresented: viewModel != nil ? Bindable(viewModel!).toggleSeeAll : .constant(false)) {
            ShowAllParticipantsGrid(close: viewModel != nil ? Bindable(viewModel!).toggleSeeAll : .constant(false))
                .presentationDetents(
                    [.medium, .large],
                    selection: viewModel != nil ? Bindable(viewModel!).settingsDetent : .constant(PresentationDetent.medium)
                )
        }
        .padding()
        .background(.bgBlueElevated)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    AddExpenseView()
        .environment(Routes())
        .environment(EventViewModel())
        .environment(EventExpenseViewModel())
}
