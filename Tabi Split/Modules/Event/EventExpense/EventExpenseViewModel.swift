//
//  EventExpenseViewModel.swift
//  Tabi
//
//  Created by Elian Richard on 10/10/24.
//

import Foundation
import SwiftUI
import PhotosUI

@Observable
final class EventExpenseViewModel: ObservableObject {
    var expenseName: String = ""
    var selectedParticipants: [UserData] = []
    var selectedMethod: SplitMethod?
    var selectedCoverer: UserData?
    var expenseTotal: String = ""
    
    var gridItem: [GridItem] = []
    var receiptImage: PhotosPickerItem? = nil
}
