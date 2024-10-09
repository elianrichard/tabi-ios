//
//  ExpenseResultView.swift
//  Tabi
//
//  Created by Dharmawan Ruslan on 08/10/24.
//

import Foundation
import SwiftUI

struct ExpenseResultView: View {
    @State var viewModel: ExpenseResultViewModel = ExpenseResultViewModel()
    
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
                }else if viewModel.splitMethod == .custom {
                    ForEach(viewModel.peoples){ people in
                        VStack{
                            HStack{
                                Circle()
                                    .frame(width: 40, height: 40)
                                Text(people.name)
                                    .font(.title3)
                                Spacer()
                                Text("Rp " + String(people.totalSpending.formatted(.number)))
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            Divider()
                            ForEach(viewModel.items){ item in
                                if item.asignees.contains(people){
                                    HStack{
                                        Text(item.itemName)
                                            .font(.subheadline)
                                        Spacer()
                                        let asigneeIndex = item.asignees.firstIndex(of: people)
                                        Text("x" + String(item.asignees[asigneeIndex!].share))
                                            .font(.subheadline)
                                        Text("Rp " + String(Float(item.itemPrice ?? 0).formatted(.number)))
                                            .frame(width: 100, alignment: .trailing)
                                            .lineLimit(1)
                                            .font(.subheadline)
                                    }
                                }
                            }
                            List{
                                Section("Bill Details"){
                                    ForEach(viewModel.additionalCharges){additionalCharge in
                                        Text("Test")
//                                        Text(additionalCharge.additionalChargeType.name)
                                    }
                                }
                            }
                            .backgroundStyle(Color(.gray))
                        }
                        .padding()
                        .background(Color(.midLightGray))
                        .cornerRadius(10)
                    }
                }
            }
            BottomButton(text: "Done")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }
}

#Preview {
    ExpenseResultView()
}
