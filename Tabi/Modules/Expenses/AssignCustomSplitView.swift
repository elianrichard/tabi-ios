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
                        }else{
                            viewModel.selectedAsignee = nil
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
            Text("All Items")
                .font(.title3)
                .padding([.top, .bottom], 10)
            ForEach(viewModel.items, id: \.id){ item in
                HStack(alignment: .center){
                    VStack(alignment: .leading){
                        Text(item.itemName)
                        Text("Rp " + String((item.itemPrice?.formatted(.number))!))
                    }
                    Text(String(item.itemQuantity) + "x")
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
