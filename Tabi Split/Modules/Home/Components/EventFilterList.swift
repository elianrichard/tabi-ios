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
                .padding(.horizontal)
            ScrollView (.horizontal, showsIndicators: false) {
                HStack (spacing: 10) {
                    ForEach(Array(HomeFilterEnum.allCases.enumerated()), id: \.offset) { index, item in
                        Button {
                            homeViewModel.selectedFilter = item
                        } label: {
                            VStack {
                                Nugget(text: item.displayName, isSelected: item == homeViewModel.selectedFilter)
                            }
                            .padding(.leading, index == 0 ? 14 : 0)
                            .padding(.trailing, index == HomeFilterEnum.allCases.count - 1 ? 14 : 0)
                        }
                    }
                }
            }
        }
    }
}
