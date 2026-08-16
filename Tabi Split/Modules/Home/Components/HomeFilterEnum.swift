//
//  FilterModel.swift
//  Tabi
//
//  Created by Elian Richard on 04/10/24.
//

enum HomeFilterEnum: Identifiable, CaseIterable {
    case all
    case youOwe
    case owsYou
    case settled
    
    var id: String {
        switch self {
        case .all:
            "all"
        case .youOwe:
            "youOwe"
        case .owsYou:
            "owsYou"
        case .settled:
            ".settled"
        }
    }
    
    var displayName: String {
        switch self {
        case .all:
            "All"
        case .youOwe:
            "Pay"
        case .owsYou:
            "Receive"
        case .settled:
            "Settled"
        }
    }
    
}
