//
//  AssignCustomSplitViewModel.swift
//  Tabi
//
//  Created by Dharmawan Ruslan on 07/10/24.
//

import Foundation
import SwiftUI

/// Which slice of the item list to show. "Assigned" is relative to the currently
/// selected participant; "Unassigned" means items with no assignees at all.
enum ItemAssignmentFilter: CaseIterable, Identifiable {
    // Order here drives the segmented control order: Unassigned first (the default
    // — the items still needing action), then Assigned, then All.
    case unassigned, assigned, all
    var id: Self { self }
    var label: String {
        switch self {
        case .all: return "All"
        case .assigned: return "Assigned"
        case .unassigned: return "Unassigned"
        }
    }
}

@Observable
class ExpenseAssignViewModel {
    var selectedAsignee: UserData? = nil
    var isShowingQuantityChangeSheet: Bool = false
    var selectedItem: ExpenseItem = ExpenseItem(itemName: "", itemPrice: 0, itemQuantity: 0)
    var settingsDetent = PresentationDetent.medium
    var itemFilter: ItemAssignmentFilter = .unassigned

    /// An item is FULLY assigned when the sum of its assignees' shares equals its
    /// quantity — e.g. a qty-3 item needs 3 shares total (one person taking 3, or
    /// A:2 + B:1). Anything less (including 0 assignees) is still unassigned.
    func isFullyAssigned(_ item: ExpenseItem) -> Bool {
        let assignedShares = item.assignees.reduce(0) { $0 + $1.share }
        return assignedShares >= item.itemQuantity && item.itemQuantity > 0
    }

    /// Applies the current filter to the given items. "Assigned" is scoped to the
    /// selected participant; with no participant selected it falls back to fully
    /// assigned items so the tab still shows something sensible.
    func filteredItems(_ items: [ExpenseItem]) -> [ExpenseItem] {
        switch itemFilter {
        case .all:
            return items
        case .assigned:
            if let selected = selectedAsignee {
                return items.filter { item in item.assignees.contains { $0.user == selected } }
            }
            // No participant selected: show items whose quantity is fully covered.
            return items.filter { isFullyAssigned($0) }
        case .unassigned:
            // Keep an item here until its quantity is fully covered by assignees.
            return items.filter { !isFullyAssigned($0) }
        }
    }

    /// Removes every assignee from an item (clears its whole assignment).
    func clearAssignees(item: ExpenseItem) {
        item.assignees.removeAll()
    }

    func assignExpenseItem(item: ExpenseItem) {
        let isAssigned = item.assignees.contains (where: { $0.user == selectedAsignee })
        if let user = selectedAsignee {
            if !isAssigned {
                item.assignees.append(ExpensePerson(user: user, share: 1))
            } else {
                item.assignees.removeAll(where: { $0.user == user })
                for assignee in item.assignees {
                    print(assignee.user.name)
                }
            }
        }
    }
    
    func toggleAsignee(user: UserData) {
        if selectedAsignee != user {
            selectedAsignee = user
        } else {
            selectedAsignee = nil
        }
    }
}
