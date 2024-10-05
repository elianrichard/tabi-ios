//
//  EventModel.swift
//  Tabi
//
//  Created by Elian Richard on 04/10/24.
//

import SwiftUI

enum EventCardStatus {
    case debt
    case credit
    case settled
    
    var id: String {
        switch self {
        case .credit:
            "credit"
        case .debt:
            "debt"
        case .settled:
            "settled"
        }
    }
    
    var statusDisplay: String {
        switch self {
        case .credit:
            "Ows you"
        case .debt:
            "You owe"
        case .settled:
            "Settled"
        }
    }
    
    var statusColor: Color {
        switch self {
        case .credit:
            .green
        case .debt:
            .red
        case .settled:
            .gray
        }
    }
}
