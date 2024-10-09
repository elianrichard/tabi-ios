//
//  AddExpense.swift
//  Tabi
//
//  Created by Dharmawan Ruslan on 02/10/24.
//

import Foundation
import SwiftUI
import PhotosUI

struct AddExpenseView: View {
    @State var viewModel: AddExpenseViewModel = AddExpenseViewModel()
    @EnvironmentObject var routes: Routes
    
    var body: some View {
        //        NavigationView {
        VStack{
            ScrollView(){
                VStack(alignment: .leading){
                    Text("Title")
                        .padding([.top, .bottom], 5)
                    TextField("Title", text: $viewModel.expenseName)
                        .padding(10)
                        .background(Color(.midLightGray))
                        .cornerRadius(5)
                } // Title
                VStack(alignment: .leading){
                    Text("Paid by")
                        .padding([.top, .bottom], 5)
                    Menu {
                        ForEach(viewModel.peoples, id: \.id) { people in
                            Button(people.name, action: {
                                viewModel.selectedCoverer = people
                            })
                            .frame(maxWidth: .infinity)
                        }
                    } label: {
                        HStack{
                            if viewModel.selectedCoverer != nil{
                                Text(viewModel.selectedCoverer!.name)
                            }else{
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
                    LazyVGrid(columns: viewModel.gridItem, spacing: 16){
                        ForEach(viewModel.peoples, id: \.id) { people in
                            VStack{
                                Circle()
                                    .frame(width: 40, height: 40)
                                    .background{
                                        Circle()
                                            .frame(width: 50, height: 50)
                                            .foregroundColor(.gray)
                                            .opacity(!viewModel.selectedParticipants.contains(people) ? 0 : 0.5)
                                    }
                                Text(people.name)
                                    .font(.subheadline)
                                    .lineLimit(1)
                            }
                            .onTapGesture {
                                if !viewModel.selectedParticipants.contains(people){
                                    viewModel.selectedParticipants.append(people)
                                }else{
                                    let removeIndex = viewModel.selectedParticipants.firstIndex(of: people)
                                    viewModel.selectedParticipants.remove(at: removeIndex!)
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
                        viewModel.gridItem = Array(repeating: .init(.flexible()), count: 5)
                    }
                } // Participants
                VStack(alignment: .leading){
                    Text("Split Method")
                        .padding([.top, .bottom], 5)
                    Menu {
                        ForEach(viewModel.methods, id: \.self) { method in
                            Button(method, action: {
                                viewModel.selectedMethod = method
                            })
                            .frame(maxWidth: .infinity)
                        }
                    } label: {
                        HStack{
                            if viewModel.selectedMethod != ""{
                                Text(viewModel.selectedMethod)
                            }else{
                                Text("Split Method")
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
                if viewModel.selectedMethod == "Split Equally"{
                    VStack(alignment: .leading){
                        Text("Total Bill (RP)")
                            .padding([.top, .bottom], 5)
                        HStack{
                            Text("Rp")
                            TextField("0", value: $viewModel.expenseTotal, format: .number .grouping(.automatic)
                            )
                            .keyboardType(.numberPad)
                        }
                        .padding(10)
                        .background(Color(.midLightGray))
                        .cornerRadius(5)
                    }
                } // Input nominal kalau equally
                VStack(alignment: .leading){
                    Text("Payment Receipt")
                        .padding([.top, .bottom], 5)
                    PhotosPicker(selection: $viewModel.receiptImage, matching: .images, photoLibrary: .shared()){
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
                } // Title
            }
            .padding([.top, .leading, .trailing], 30)
            .navigationTitle("Add New Expense")
            .navigationBarTitleDisplayMode(.inline)
            BottomButton(text: "Next")
                .onTapGesture {
                    routes.navigate(to: .ExpenseSplitView)
                }
        }
        //        }
    }
}

#Preview {
    AddExpenseView()
}
