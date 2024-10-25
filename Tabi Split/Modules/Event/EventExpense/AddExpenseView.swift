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
    @State private var viewModel = AddExpenseViewModel()
    
    var body: some View {
        VStack {
            ZStack {
                Text("Add New Expense")
                    .font(.tabiSubtitle)
                HStack {
                    Button {
                        routes.navigateBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.black)
                            .font(.tabiSubtitle)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding([.bottom], 30)
            ScrollView() {
                VStack(spacing: 20){
                    InputWithLabel(label: "Expense Name",
                                   placeholder: "Expense Name",
                                   inputBackgroundColor: .bgWhite,
                                   inputCornerRadius: 16,
                                   text: Bindable(eventExpenseViewModel).expenseName)
                    //                .onSubmit(registerViewModel.validateName)
                    DropDownInput(
                        label: "Paid by",
                        items: eventViewModel.selectedEvent?.participants ?? [],
                        keyPath: \UserData.name,
                        backgroundColor: .bgWhite,
                        cornerRadius: 16,
                        selectedItem: Bindable(eventExpenseViewModel).selectedCoverer
                    )
                    VStack(alignment: .leading, spacing: 8){
                        HStack{
                            Text("Select Participants")
                                .font(.tabiBody)
                            Spacer()
                            Button{
                                viewModel.toggleSeeAll.toggle()
                            }label: {
                                Text("See All")
                                    .font(.tabiBody)
                            }
                        }
                        ScrollView(.vertical) {
                            HStack(alignment: .center){
                                ForEach(eventViewModel.selectedEvent?.participants ?? []) { person in
                                    VStack(alignment: .center){
                                        Circle()
                                            .frame(width: 40, height: 40)
                                            .padding(5)
                                            .background{
                                                Circle()
                                                    .frame(width: 50, height: 50)
                                                    .foregroundColor(.gray)
                                                    .opacity(!eventExpenseViewModel.selectedParticipants.contains(person) ? 0 : 0.5)
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
                                .stroke(viewModel.isParticipantsError ? .buttonRed : .bgGreyOverlay, lineWidth: 0.5)
                        }
                    } // Participants
                    DropDownInput(
                        label: "Split Bill Method",
                        label2: "Split by",
                        items: SplitMethod.allCases,
                        keyPath: \.splitDescription,
                        backgroundColor: .bgWhite,
                        cornerRadius: 16,
                        selectedItem: Bindable(eventExpenseViewModel).selectedMethod
                    )
                    if eventExpenseViewModel.selectedMethod ==  .equally {
                        VStack(alignment: .leading){
                            Text("Total Bill (Rp)")
                                .padding([.top, .bottom], 5)
                            HStack{
                                Text("Rp")
                                TextField("10.000", text: $viewModel.placeholderPrice)
                                    .keyboardType(.numberPad)
                                    .onChange(of: viewModel.placeholderPrice) {
                                        viewModel.placeholderPrice = viewModel.placeholderPrice.formatPrice()
                                        eventExpenseViewModel.expenseTotalInput = Float(viewModel.placeholderPrice.removeDots()) ?? 0
                                    }
                                    .padding(10)
                                    .background(.uiGray)
                                    .cornerRadius(5)
                                    .onReceive(Just(eventExpenseViewModel.expenseTotalInput)) { _ in
                                        viewModel.placeholderPrice =  eventExpenseViewModel.expenseTotalInput  != 0 ? eventExpenseViewModel.expenseTotalInput.formatPrice() : ""
                                    }
                            }
                            .padding(10)
                            .background(Color(.uiGray))
                            .cornerRadius(5)
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
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                        .foregroundStyle(.black)
                        .font(.tabiBody)
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
                                            .stroke(viewModel.isParticipantsError ? .buttonRed : .bgGreyOverlay, lineWidth: 0.5)
                                    }
                            }
                        }
                        .onTapGesture {
                            routes.navigate(to: .ReceiptUploadView)
                        }
                        .contentShape(Rectangle())
                    }
                }
            }
            Button {
                if (eventExpenseViewModel.selectedMethod == .custom) {
                    routes.navigate(to: .ExpenseAddItemsView)
                } else if (eventExpenseViewModel.selectedMethod == .equally) {
                    eventExpenseViewModel.totalSpending = eventExpenseViewModel.expenseTotalInput
                    routes.navigate(to: .ExpenseResultView)
                }
            } label: {
                BottomButton(text: "Next")
            }
        }
        .sheet(isPresented: $viewModel.toggleSeeAll) {
            ShowAllParticipantsGrid(close: $viewModel.toggleSeeAll)
                .presentationDetents(
                    [.medium, .large],
                    selection: $viewModel.settingsDetent
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
