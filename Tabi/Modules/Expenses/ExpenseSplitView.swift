//
//  ExpenseSplitView.swift
//  Tabi
//
//  Created by Dharmawan Ruslan on 07/10/24.
//

import Foundation
import SwiftUI

struct ExpenseSplitView:View {
    @State var viewModel = ExpenseSplitViewModel()
    
    var body: some View {
        VStack(alignment: .leading){
            Text(viewModel.expenseTitle)
                .font(.title)
            HStack(){
                Image(systemName: "cylinder.split.1x2")
                Text(viewModel.splitMethod.splitDescription)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding([.top, .bottom], 5)
            ScrollView{
                if viewModel.splitMethod == .equally {
                    VStack{
                        ForEach(viewModel.peoples, id: \.id){ people in
                            HStack{
                                Circle()
                                    .frame(width: 40, height: 40)
                                Text(people.name + "'s Expense")
                                Spacer()
                                Text("Rp")
                                    .font(.title2)
                                Text(String(Float(people.share * viewModel.totalSpending!).formatted(.number)))
                                    .font(.title2)
                            }
                            .padding()
                            .background(Color(.midLightGray))
                            .cornerRadius(20)
                        }
                    }
                    BottomButton(text: "Done")
                }else if viewModel.splitMethod == .custom {
                    ForEach($viewModel.items, id: \.id){item in
                        AddItemContainer(itemNum: viewModel.itemCount, item: item, viewModel: $viewModel)
                    }
                    Button{
                        viewModel.items.append(Item(itemName: "", itemPrice: nil, itemQuantity: 1))
                        viewModel.itemCount += 1
                    }label: {
                        Text("+ Add Item")
                            .padding()
                            .padding([.leading, .trailing], 20)
                            .background(Color(.lightGray))
                            .cornerRadius(50)
                            .foregroundColor(.black)
                    }
                    Divider()
                    VStack(alignment: .leading){
                        Text("Additional Charge (optional)")
                            .font(.title3)
                            .padding([.bottom], 10)
                        Text("Amount")
                        ForEach($viewModel.additionalCharges, id: \.id){ additionalCharge in
                            //                        Text("test \(additionalCharge.additionalChargeType.name)")
                            HStack {
                                Menu {
                                    ForEach(AdditionalChargeType.allCases) { type in
                                        Button(type.id, action: {
                                            let index = viewModel.additionalCharges.firstIndex(of: additionalCharge.wrappedValue)
                                            viewModel.additionalCharges[index!].additionalChargeType = type
                                        })
                                        .frame(maxWidth: .infinity)
                                    }
                                } label: {
                                    HStack{
                                        Text(additionalCharge.wrappedValue.additionalChargeType.name)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(10)
                                    .foregroundColor(.black)
                                    .background(Color(.midLightGray))
                                    .cornerRadius(5)
                                }
                                HStack{
                                    Text("Rp")
                                    TextField("0", value: additionalCharge.amount, format: .number .grouping(.automatic)
                                    )
                                    .keyboardType(.numberPad)
                                }
                                .padding(10)
                                .background(Color(.midLightGray))
                                .cornerRadius(5)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Button{
                        viewModel.additionalCharges.append(AdditionalCharge(additionalChargeType: .tax, amount: nil))
                    }label: {
                        Text("+ Add more")
                            .padding()
                            .foregroundColor(.black)
                    }
                    HStack{
                        Text("Total Bill")
                            .fontWeight(.heavy)
                        Spacer()
                        Text("Rp " + String(viewModel.totalSpending!.formatted(.number)))
                            .onChange(of: viewModel.items){
                                viewModel.calculateTotal()
                            }
                            .onChange(of: viewModel.additionalCharges){
                                viewModel.calculateTotal()
                            }
                            .fontWeight(.heavy)
                    }
                    BottomButton(text: "Next")
                }
            }
        }
        .navigationTitle("Add items")
        .navigationBarTitleDisplayMode(.inline)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }
}

#Preview {
    ExpenseSplitView()
}
