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
        VStack(alignment: .leading) {
            CustomNavTitle(title: "Assign Items")
            
            VStack (alignment: .leading, spacing: 10) {
                Text(eventExpenseViewModel.expenseName)
                    .font(.tabiTitle)
                HStack {
                    Image(systemName: "cylinder.split.1x2")
                        .font(.tabiBody)
                    Text("Custom Splitted")
                        .font(.tabiBody)
                }
                .padding([.bottom], 24)
            }
            
            ScrollView(showsIndicators: false){
                VStack(spacing: 0){
                    Text("Participants")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding([.bottom], 12)
                        .font(.tabiHeadline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .center){
                            ForEach(eventExpenseViewModel.selectedParticipants) { person in
                                VStack(alignment: .center){
                                    Circle()
                                        .frame(width: 40, height: 40)
                                        .padding(5)
                                        .background{
                                            Circle()
                                                .frame(width: 50, height: 50)
                                                .foregroundColor(.buttonGreen)
                                                .opacity(expenseAssignViewModel.selectedAsignee != person ? 0 : 1)
                                            Circle()
                                                .frame(width: 45, height: 45)
                                                .foregroundColor(.bgWhite)
                                                .opacity(expenseAssignViewModel.selectedAsignee != person ? 0 : 1)
                                        }
                                    Text(person.name.getFirstName())
                                        .font(.tabiBody)
                                        .fontWeight(expenseAssignViewModel.selectedAsignee == person ? .bold : .regular)
                                        .lineLimit(1)
                                }
                                .onTapGesture {
                                    expenseAssignViewModel.toggleAsignee(user: person)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(.bgWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.black)
                    .font(.tabiBody)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.clear)
                            .stroke(.bgGreyOverlay, lineWidth: 0.5)
                            .padding(0.5)
                    }
                    .padding([.bottom], 24)
                    Text("All Items")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.tabiHeadline)
                        .padding([.bottom], 12)
                    ForEach(eventExpenseViewModel.items){ item in
                        VStack{
                            HStack(alignment: .center){
                                VStack(alignment: .leading){
                                    Text(item.itemName)
                                        .font(.tabiHeadline)
                                    Text("Rp \(item.itemPrice.formatPrice())")
                                        .font(.tabiBody)
                                }
                                Spacer()
                                Text (String(item.itemQuantity.formatted(.number)) + "x")
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
                            
                            if !item.assignees.isEmpty{
                                HStack (spacing: 5) {
                                    HStack (spacing: -10){
                                        ForEach(item.assignees) { asignee in
                                            Circle()
                                                .frame(width: 20, height: 32)
                                        }
                                    }
                                    Image(systemName: "chevron.right")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 10, height: 10)
                                }
                                .padding(.top, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .onTapGesture {
                                    expenseAssignViewModel.selectedItem = item
                                    expenseAssignViewModel.isShowingQuantityChangeSheet.toggle()
                                }
                            }
                        }
                        .padding(12)
                        .background(.bgWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.clear)
                                .stroke(.bgGreyOverlay, lineWidth: 0.5)
                                .padding(0.5)
                        }
                        .padding(.bottom, 12)
                    }
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
        .background(.bgBlueElevated)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            expenseAssignViewModel.selectedAsignee = eventExpenseViewModel.selectedParticipants.first
        }
        .sheet(isPresented: Bindable(expenseAssignViewModel).isShowingQuantityChangeSheet) {
            if let item = Bindable(eventExpenseViewModel).items.first(where: { $0.id == expenseAssignViewModel.selectedItem.id }){
                QuantityChangeView(item: item, close: $expenseAssignViewModel.isShowingQuantityChangeSheet)
                    .presentationDetents(
                        [.medium, .large],
                        selection: Bindable(expenseAssignViewModel).settingsDetent
                    )
            }
        }
    }
}

#Preview {
    ExpenseAssignView()
        .environment(Routes())
        .environment(EventExpenseViewModel())
}
