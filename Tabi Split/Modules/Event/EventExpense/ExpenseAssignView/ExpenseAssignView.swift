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

    private var filteredItems: [ExpenseItem] {
        expenseAssignViewModel.filteredItems(eventExpenseViewModel.items)
    }

    private var filteredParticipants: [UserData] {
        eventExpenseViewModel.selectedParticipants.filter {
            searchQuery.isEmpty || $0.name.lowercased().contains(searchQuery.lowercased())
        }
    }

    private var emptyFilterMessage: String {
        switch expenseAssignViewModel.itemFilter {
        case .all:
            return "No items to assign."
        case .assigned:
            let name = expenseAssignViewModel.selectedAsignee?.name.getFirstName()
            return name.map { "\($0) has no assigned items yet." } ?? "No assigned items yet."
        case .unassigned:
            return "Every item is assigned."
        }
    }

    /// The participant picker (search + selectable avatars). Pinned above the
    /// scrolling item list so the selected participant stays in view while assigning.
    private var participantSelector: some View {
        VStack(alignment: .leading, spacing: .spacingTight){
            HStack(spacing: .spacingXSmall) {
                Icon(systemName: "info.circle.fill", color: .buttonBlue, size: 14)
                Text(expenseAssignViewModel.selectedAsignee == nil
                     ? "Select a participant to assign items"
                     : "Tap items below to assign to \(expenseAssignViewModel.selectedAsignee?.name.getFirstName() ?? "")")
                    .font(.tabiBody2)
                    .foregroundStyle(.buttonBlue)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            SearchInput(text: $searchQuery, placeholder: "Search Participant")
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: Array(repeating: .init(.fixed(rowHeight), spacing: rowSpacing), count: 2), alignment: .top, spacing: .spacingSmall) {
                    ForEach(filteredParticipants) { person in
                        HStack(alignment: .center, spacing: .spacingXSmall){
                            UserAvatar(userData: person)
                                .padding(4)
                                .background{
                                    Circle()
                                        .frame(width: 48, height: 48)
                                        .foregroundColor(.buttonBlue)
                                        .opacity(expenseAssignViewModel.selectedAsignee != person ? 0 : 1)
                                    Circle()
                                        .frame(width: 43, height: 43)
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
                        .frame(width: 180, height: rowHeight, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            expenseAssignViewModel.toggleAsignee(user: person)
                        }
                    }
                }
                // Inset the row content from the box edges so cards don't hug the
                // rounded corners.
                .padding(.horizontal, 12)
            }
            // Constrain the horizontal ScrollView to exactly the two rows — a
            // ScrollView otherwise greedily expands to fill the parent height,
            // which was the empty space below the avatars.
            .frame(height: rowHeight * 2 + rowSpacing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
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
    }

    private let rowHeight: CGFloat = 52
    private let rowSpacing: CGFloat = 8

    var body: some View {
        VStack(alignment: .leading) {
            TopNavigation(title: "Assign Items")
            // Split-method + See Receipt nuggets (no expense-name title here).
            ExpenseHeaderView(showTitle: false)
            // Everything up to the filter segment is pinned; only the item cards scroll.
            participantSelector
                .padding([.bottom], 16)

            HStack {
                Text("Items")
                    .font(.tabiHeadline)
                Spacer()
                Text("\(filteredItems.count) of \(eventExpenseViewModel.items.count)")
                    .font(.tabiBody)
                    .foregroundStyle(.textGrey)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding([.bottom], 12)

            // Filter the item list: all, only the selected participant's assigned
            // items, or items with no assignees yet.
            Picker("Filter items", selection: Bindable(expenseAssignViewModel).itemFilter) {
                ForEach(ItemAssignmentFilter.allCases) { filter in
                    Text(filter.label).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding([.bottom], 16)
            .onChange(of: expenseAssignViewModel.itemFilter) {
                // Only the All tab clears the selection (it's a participant-agnostic
                // overview); Assigned/Unassigned keep the selected participant so the
                // per-person view stays in context.
                if expenseAssignViewModel.itemFilter == .all {
                    expenseAssignViewModel.selectedAsignee = nil
                }
            }

            ScrollView(showsIndicators: false){
                VStack(spacing: 0){
                    if filteredItems.isEmpty {
                        Text(emptyFilterMessage)
                            .font(.tabiBody)
                            .foregroundStyle(.textGrey)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 32)
                    }

                    ForEach(filteredItems){ item in
                        VStack{
                            HStack(alignment: .top){
                                VStack(alignment: .leading){
                                    Text(item.itemName)
                                        .font(.tabiHeadline)
                                    Text("Rp \(item.itemPrice.formatPrice())")
                                        .font(.tabiBody)
                                }
                                Spacer()
                                HStack (spacing: .spacingRegular) {
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
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            expenseAssignViewModel.assignExpenseItem(item: item)
                                        }
                                    }
                                }
                            }
                            
                            if !item.assignees.isEmpty{
                                HStack (spacing: 5) {
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
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        expenseAssignViewModel.selectedItem = item
                                        expenseAssignViewModel.isShowingQuantityChangeSheet.toggle()
                                    }
                                    Spacer()
                                    // Clear all assignees — only when no participant
                                    // is selected (in participant mode you toggle with
                                    // the checkbox instead).
                                    if expenseAssignViewModel.selectedAsignee == nil {
                                        Button {
                                            expenseAssignViewModel.clearAssignees(item: item)
                                        } label: {
                                            HStack (spacing: 4) {
                                                Icon(systemName: "xmark", color: .buttonRed, size: 10)
                                                Text("Clear")
                                                    .font(.tabiBody2)
                                                    .foregroundStyle(.buttonRed)
                                            }
                                        }
                                    }
                                }
                                .padding(.top, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
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
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

#Preview {
    ExpenseAssignView()
        .environment(Router())
        .environment(EventExpenseViewModel())
}
