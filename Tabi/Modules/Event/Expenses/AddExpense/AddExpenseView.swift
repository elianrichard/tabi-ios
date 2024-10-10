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
<<<<<<<< HEAD:Tabi/Modules/Event/EventExpense/AddExpenseView.swift
    @Environment(EventViewModel.self) private var eventViewModel
    @Environment(EventExpenseViewModel.self) private var eventExpenseViewModel
========
    @State var viewModel: AddExpenseViewModel = AddExpenseViewModel()
>>>>>>>> sprint-1:Tabi/Modules/Event/Expenses/AddExpense/AddExpenseView.swift
    @Environment(Routes.self) private var routes
    
    var body: some View {
        VStack {
            ZStack {
                Text("Add Expense")
                    .font(.title2)
                HStack {
                    Button {
                        routes.navigateBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.black)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            ScrollView() {
                VStack(alignment: .leading){
                    Text("Paid by")
                        .padding([.top, .bottom], 5)
                    Menu {
                        ForEach(eventViewModel.selectedEvent?.participants ?? []) { person in
                            Button(person.name, action: {
                                eventExpenseViewModel.selectedCoverer = person
                            })
                            .frame(maxWidth: .infinity)
                        }
                    } label: {
                        HStack{
<<<<<<<< HEAD:Tabi/Modules/Event/EventExpense/AddExpenseView.swift
                            if eventExpenseViewModel.selectedCoverer != nil{
                                Text(eventExpenseViewModel.selectedCoverer!.name)
========
                            if viewModel.selectedCoverer != nil{
                                Text(viewModel.selectedCoverer!.name)
>>>>>>>> sprint-1:Tabi/Modules/Event/Expenses/AddExpense/AddExpenseView.swift
                            } else{
                                Text("Paid by")
                            }
                            Spacer()
                            Image(systemName: "chevron.down")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .foregroundColor(.black)
                        .background(Color(.midLightGray))
                        .cornerRadius(5)
                    }
                } // Paid  by
                VStack(alignment: .leading){
                    Text("Participants")
                        .padding([.top, .bottom], 5)
                    LazyVGrid(columns: eventExpenseViewModel.gridItem, spacing: 16){
                        ForEach(eventViewModel.selectedEvent?.participants ?? []) { person in
                            VStack{
                                Circle()
                                    .frame(width: 40, height: 40)
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
                                    let removeIndex = eventExpenseViewModel.selectedParticipants.firstIndex(of: person)
                                    eventExpenseViewModel.selectedParticipants.remove(at: removeIndex!)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(
                        Color(.midLightGray)
                    )
                    .cornerRadius(5)
                    .onAppear{
                        eventExpenseViewModel.gridItem = Array(repeating: .init(.flexible()), count: 5)
                    }
                } // Participants
                VStack(alignment: .leading){
                    Text("Split Method")
                        .padding([.top, .bottom], 5)
                    Menu {
                        ForEach(SplitMethod.allCases) { method in
                            Button(method.splitDescription, action: {
                                eventExpenseViewModel.selectedMethod = method
                            })
                            .frame(maxWidth: .infinity)
                        }
                    } label: {
                        HStack{
                            if let method = eventExpenseViewModel.selectedMethod {
                                Text(method.splitDescription)
                            } else{
                                Text("Select Split Method")
                            }
                            Spacer()
                            Image(systemName: "chevron.down")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .foregroundColor(.black)
                        .background(Color(.midLightGray))
                        .cornerRadius(5)
                    }
                } // Split Method
                if eventExpenseViewModel.selectedMethod ==  .equally {
                    VStack(alignment: .leading){
                        Text("Total Bill (Rp)")
                            .padding([.top, .bottom], 5)
                        HStack{
                            Text("Rp")
                            TextField("", text: Bindable(eventExpenseViewModel).expenseTotal)
                            .keyboardType(.numberPad)
                            .onReceive(Just(eventExpenseViewModel.expenseTotal)) { _ in
                                eventExpenseViewModel.expenseTotal = eventExpenseViewModel.expenseTotal.formatPrice()
                            }
                        }
                        .padding(10)
                        .background(Color(.midLightGray))
                        .cornerRadius(5)
                    }
                } // Input nominal kalau equally
                VStack(alignment: .leading){
                    Text("Payment Receipt")
                        .padding([.top, .bottom], 5)
                    PhotosPicker(selection: Bindable(eventExpenseViewModel).receiptImage, matching: .images, photoLibrary: .shared()){
                        VStack(spacing: 10){
                            Image(systemName: "photo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 30)
                                .foregroundColor(.gray)
                            Text("Upload an image")
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.gray)
                    .background(Color(.midLightGray))
                    .cornerRadius(5)
                }
            }
            Button {
<<<<<<<< HEAD:Tabi/Modules/Event/EventExpense/AddExpenseView.swift
                if (eventExpenseViewModel.selectedMethod == .custom) {
                    routes.navigate(to: .ExpenseCustomSplitView)
                } else {
                    routes.navigate(to: .ExpenseEqualSplitView)
                }
========
                routes.navigate(to: .ExpenseSplitView)
>>>>>>>> sprint-1:Tabi/Modules/Event/Expenses/AddExpense/AddExpenseView.swift
            } label: {
                BottomButton(text: "Next")
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    AddExpenseView()
        .environment(Routes())
        .environment(EventViewModel())
        .environment(EventExpenseViewModel())
}
