//
//  EventSettlementViewModel.swift
//  Tabi Split
//
//  Created by Elian Richard on 05/11/24.
//

import SwiftUI

@Observable
final class EventSettlementViewModel {
    var selectedSettlementType: SettlementCardTypeEnum = .NeedPayment
    var user: UserData = UserData(name: "Name", phone: "Phone")
    var receiptImage: UIImage?
}
