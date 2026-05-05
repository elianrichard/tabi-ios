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
    @Environment(ProfileViewModel.self) private var profileViewModel
    @Environment(Router.self) private var router
    
    @State var searchQuery: String = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            TopNavigation(title: "Assign Items")
            VStack (alignment: .leading, spacing: .spacingTight) {
                Text(eventExpenseViewModel.expenseName)
                    .font(.tabiTitle)
                HStack {
                    Icon(eventExpenseViewModel.selectedMethod?.icon)
                    Text(eventExpenseViewModel.selectedMethod?.splitDescription ?? "")
                        .font(.tabiBody)
                }
            }
            .padding([.bottom], 24)
            ScrollView(showsIndicators: false){
                VStack(spacing: 0){
                    Text("Participants")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding([.bottom], 12)
                        .font(.tabiHeadline)
                    VStack(alignment: .leading, spacing: .spacingTight){
                        SearchInput(text: $searchQuery, placeholder: "Search")
                            .frame(maxWidth: .infinity)
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack (alignment: .center){
                                LazyHGrid(rows: Array(repeating: .init(.flexible()), count: 2), alignment: .top, spacing: .spacingRegular) {
                                    ForEach(eventExpenseViewModel.selectedParticipants.filter {
                                        searchQuery.isEmpty || $0.name.lowercased().contains(searchQuery.lowercased())
                                    }) { person in
                                        HStack(alignment: .center){
                                            UserAvatar(userData: person)
                                                .padding(5)
                                                .background{
                                                    Circle()
                                                        .frame(width: 50, height: 50)
                                                        .foregroundColor(.buttonBlue)
                                                        .opacity(expenseAssignViewModel.selectedAsignee != person ? 0 : 1)
                                                    Circle()
                                                        .frame(width: 45, height: 45)
                                                        .foregroundColor(.bgWhite)
                                                        .opacity(expenseAssignViewModel.selectedAsignee != person ? 0 : 1)
                                                }
                                            HStack(spacing: 0){
                                                Text(person.name.getFirstName() + " " + person.name.getLastName())
                                                    .font(.tabiBody)
                                                    .fontWeight(expenseAssignViewModel.selectedAsignee == person ? .bold : .regular)
                                                    .lineLimit(1)
                                                if profileViewModel.user == person {
                                                    Text(" (You)")
                                                        .font(.tabiBody)
                                                        .foregroundColor(.textGrey)
                                                }
                                            }
                                        }
                                        .frame(width: 196, alignment: .leading)
                                        .onTapGesture {
                                            expenseAssignViewModel.toggleAsignee(user: person)
                                        }
                                    }
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
                                        Circle()
                                            .stroke(item.assignees.contains(where: { $0.user == expenseAssignViewModel.selectedAsignee }) ? .buttonBlue : .textGrey, lineWidth: 1)
                                            .fill(item.assignees.contains(where: { $0.user == expenseAssignViewModel.selectedAsignee }) ? .buttonBlue : .clear)
                                            .frame(width: 20)
                                            .overlay {
                                                if item.assignees.contains(where: { $0.user == expenseAssignViewModel.selectedAsignee }) {
                                                    Icon(systemName: "checkmark", color: .textWhite, size: 10)
                                                }
                                            }
                                            .offset(x: -1)
                                    }
                                    .padding([.leading], 50)
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
                                            UserAvatar(userData: asignee.user, size: 32)
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
            
            CustomButton(text: "Next") {
                eventExpenseViewModel.calculatePeopleItems()
                router.push(.expenseResult)
            }
        }
        .padding()
        .background(.bgWhite)
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
        .environment(Router())
        .environment(EventExpenseViewModel())
}
