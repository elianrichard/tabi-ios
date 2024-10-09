//
//  AssignCustomSplitView.swift
//  Tabi
//
//  Created by Dharmawan Ruslan on 07/10/24.
//

import Foundation
import SwiftUI

struct AssignCustomSplitView: View {
    @State var viewModel: AssignCustomSplitViewModel = AssignCustomSplitViewModel()
    
    var body: some View {
        VStack(alignment: .leading){
            Text(viewModel.expenseTitle)
                .font(.title)
            HStack(){
                Image(systemName: "cylinder.split.1x2")
                Text("Custom Split")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding([.top, .bottom], 5)
            ScrollView{
                
                LazyVGrid(columns: viewModel.gridItem, spacing: 16){
                    ForEach(viewModel.peoples, id: \.id) { people in
                        VStack{
                            Circle()
                                .frame(width: 40, height: 40)
                                .background{
                                    Circle()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(.gray)
                                        .opacity(viewModel.selectedAsignee != people ? 0 : 0.5)
                                }
                            Text(people.name)
                                .font(.subheadline)
                                .lineLimit(1)
                        }
                        .onTapGesture {
                            if viewModel.selectedAsignee != people{
                                viewModel.selectedAsignee = people
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
                    viewModel.selectedAsignee = viewModel.peoples.first!
                }
                Text("All Items")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.title3)
                    .padding([.top, .bottom], 10)
                ForEach(viewModel.items, id: \.id){ item in
                    HStack(alignment: .center){
                        VStack(alignment: .leading){
                            Text(item.itemName)
                            Text("Rp " + String((item.itemPrice?.formatted(.number))!))
                                .fontWeight(.semibold)
                            if !item.asignees.isEmpty{
                                HStack{
                                    ZStack{
                                        ForEach(Array(item.asignees.enumerated()), id: \.offset){ index, asignee in
                                            Circle()
                                                .frame(width: 20, height: 20)
                                                .offset(CGSize(width: index*10, height: 0))
                                            if asignee == item.asignees.last{
                                                Image(systemName: "chevron.right")
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 20, height: 20)
                                                    .offset(CGSize(width: index*10+20, height: 0))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        Spacer()
                        Text(String(item.itemQuantity) + "x")
                            .fontWeight(.bold)
                        VStack{
                            if !item.asignees.contains(viewModel.selectedAsignee){
                                Image(systemName: "circle")
                                    .padding([.leading], 50)
                            }else{
                                Image(systemName: "checkmark.circle.fill")
                                    .padding([.leading], 50)
                            }
                        }
                        .onTapGesture {
                            let itemIndex = viewModel.items.firstIndex(of: item)!
                            if !item.asignees.contains(viewModel.selectedAsignee){
                                viewModel.items[itemIndex].asignees.append(viewModel.selectedAsignee)
                            }else{
                                let removeIndex = item.asignees.firstIndex(of: viewModel.selectedAsignee)!
                                viewModel.items[itemIndex].asignees.remove(at: removeIndex)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(.midLightGray))
                    .cornerRadius(10)
                }
            }
        }
        .navigationTitle("Assign the items")
        .navigationBarTitleDisplayMode(.inline)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }
}

#Preview {
    AssignCustomSplitView()
}
