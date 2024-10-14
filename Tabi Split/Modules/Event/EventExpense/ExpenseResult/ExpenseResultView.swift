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
        Text("Expense Result")
//        VStack(alignment: .leading){
//            Text(viewModel.expenseTitle)
//                .font(.title)
//            HStack(){
//                Image(systemName: "cylinder.split.1x2")
//                Text(viewModel.splitMethod.splitDescription)
//            }
//            .frame(maxWidth: .infinity, alignment: .leading)
//            .padding([.top, .bottom], 5)
//            ScrollView{
//                if viewModel.splitMethod == .equally {
//                    ForEach(viewModel.peoples, id: \.id){ people in
//                        HStack{
//                            Circle()
//                                .frame(width: 40, height: 40)
//                            Text(people.name + "'s Expense")
//                            Spacer()
//                            Text("Rp")
//                                .font(.title2)
//                            Text(String(Float(people.share * viewModel.totalSpentAll).formatted(.number)))
//                                .font(.title2)
//                        }
//                        .padding()
//                        .background(Color(.midLightGray))
//                        .cornerRadius(20)
//                    }
//                }else if viewModel.splitMethod == .custom {
//                    ForEach(viewModel.peopleItems){ people in
//                        VStack{
//                            HStack{
//                                Circle()
//                                    .frame(width: 40, height: 40)
//                                Text(people.name)
//                                    .font(.title3)
//                                Spacer()
//                                Text("Rp " + String(round(people.totalSpending).formatted(.number)))
//                                    .font(.title3)
//                                    .fontWeight(.semibold)
//                            }
//                            Divider()
//                            ForEach(people.items){ item in
//                                HStack(alignment: .top){
//                                    Text(item.itemName)
//                                        .font(.subheadline)
//                                    Spacer()
//                                    Text("x" + String(item.itemQuantity))
//                                        .font(.subheadline)
//                                    Text("Rp " + String(Float(item.itemPrice ?? 0).formatted(.number)))
//                                        .frame(width: 100, alignment: .trailing)
//                                        .lineLimit(1)
//                                        .font(.subheadline)
//                                }
//                            }
//                            DisclosureGroup() {
//                                ForEach(viewModel.additionalCharges) { additionalCharge in
//                                    HStack {
//                                        Text(additionalCharge.additionalChargeType.name)
//                                        Spacer()
//                                        Text("Rp " + String(Float(additionalCharge.amount ?? 0).formatted(.number)))
//                                    }
//                                    .font(.subheadline)
//                                }
//                            } label: {
//                                HStack {
//                                    Text("Bill Details")
//                                        .font(.headline)
//                                        .padding(.vertical, 5)
//                                }
//                            }
//                        }
//                        .padding()
//                        .background(Color(.midLightGray))
//                        .cornerRadius(10)
//                    }
//                }
//            }
//            BottomButton(text: "Done")
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
//        .padding()
    }
}

#Preview {
    ExpenseResultView()
}
