//
//  EventFilterList.swift
//  Tabi Split
//
//  Created by Elian Richard on 28/10/24.
//

import SwiftUI

struct EventFilterList: View {
    @Bindable var homeViewModel: HomeViewModel
    
    var body: some View {
        VStack (alignment: .leading, spacing: 15) {
            Text("Events")
                .font(.tabiLargeTitle)
            ScrollView (.horizontal, showsIndicators: false) {
                HStack (spacing: 10) {
                    ForEach(HomeFilterEnum.allCases) { item in
                        Button {
                            homeViewModel.selectedFilter = item
                        } label: {
                            Nugget(text: item.displayName, isSelected: item == homeViewModel.selectedFilter)
                        }
                    }
                }
            }
        }
    }
}
