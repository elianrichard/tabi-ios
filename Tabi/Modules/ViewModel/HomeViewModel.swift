//
//  HomeViewModel.swift
//  Tabi
//
//  Created by Elian Richard on 03/10/24.
//

import Foundation

@Observable class HomeViewModel: ObservableObject {
    var text = "Hello from view model"
    
    func editText() {
        text = "Edited from view model"
    }
}
