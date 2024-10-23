//
//  AssignCustomSplitView.swift
//  Tabi
//
//  Created by Dharmawan Ruslan on 07/10/24.
//

import Foundation
import SwiftUI

struct ExpenseAssignView: View {
    @State var expenseAssignViewModel = ExpenseAssignViewModel()
    @Environment(EventExpenseViewModel.self) private var eventExpenseViewModel
    @Environment(Routes.self) private var routes
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ZStack {
                Text("Assign Items")
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
            VStack (alignment: .leading, spacing: 10) {
                Text(eventExpenseViewModel.expenseName)
                    .font(.title)
                HStack {
                    Image(systemName: "cylinder.split.1x2")
                    Text("Custom Splitted")
                }
            }
            
            ScrollView {
                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 5), spacing: 16){
                    ForEach(eventExpenseViewModel.selectedParticipants) { person in
                        VStack{
                            Circle()
                                .frame(width: 40, height: 40)
                                .background{
                                    Circle()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(.gray)
                                        .opacity(expenseAssignViewModel.selectedAsignee != person ? 0 : 0.5)
                                }
                            Text(person.name.getFirstName())
                                .font(.subheadline)
                                .lineLimit(1)
                        }
                        .onTapGesture {
                            expenseAssignViewModel.toggleAsignee(user: person)
                        }
                    }
                }
                .padding()
                .background(
                    .uiGray
                )
                .cornerRadius(5)
                Text("All Items")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.title3)
                    .padding([.top, .bottom], 10)
                ForEach(eventExpenseViewModel.items){ item in
                    HStack(alignment: .center){
                        VStack(alignment: .leading){
                            Text(item.itemName)
                            Text("Rp \(item.itemPrice.formatPrice())")
                                .fontWeight(.semibold)
                            if !item.assignees.isEmpty{
                                HStack (spacing: 5) {
                                    HStack (spacing: -10){
                                        ForEach(item.assignees) { asignee in
                                            Circle()
                                                .frame(width: 20, height: 20)
                                        }
                                    }
                                    Image(systemName: "chevron.right")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 10, height: 10)
                                }
                            }
                        }
                        Spacer()
                        Text (String(item.itemQuantity) + "x")
                            .fontWeight(.bold)
                        if (expenseAssignViewModel.selectedAsignee != nil) {
                            VStack{
                                if item.assignees.filter({$0.user == expenseAssignViewModel.selectedAsignee}).count == 0 {
                                    Image(systemName: "circle")
                                        .padding([.leading], 50)
                                } else{
                                    Image(systemName: "checkmark.circle.fill")
                                        .padding([.leading], 50)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                expenseAssignViewModel.assignExpenseItem(item: item)
                            }
                        }
                    }
                    .padding(10)
                    .background(.uiGray)
                    .cornerRadius(10)
                }
            }
            Spacer()
            
            Button {
                eventExpenseViewModel.calculatePeopleItems()
                routes.navigate(to: .ExpenseResultView)
            } label: {
                BottomButton(text: "Next")
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .onAppear {
            expenseAssignViewModel.selectedAsignee = eventExpenseViewModel.selectedParticipants.first
        }
    }
}

#Preview {
    ExpenseAssignView()
        .environment(Routes())
        .environment(EventExpenseViewModel())
}
