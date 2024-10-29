//
//  EventNavigation.swift
//  Tabi Split
//
//  Created by Elian Richard on 28/10/24.
//

import SwiftUI

struct EventNavigation: View {
    
    @Environment(EventViewModel.self) private var eventViewModel
    var body: some View {
        ZStack {
            HStack {
                RoundedRectangle(cornerRadius: .infinity)
                    .fill(.bgWhite)
                    .frame(maxWidth: 100, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, alignment: eventViewModel.selectedSection == .expenses ? .leading : .trailing)
            
            HStack (spacing: 0) {
                ForEach(EventSectionEnum.allCases) { section in
                    Text("\(section.displayName)")
                        .frame(maxWidth: 100, maxHeight: .infinity)
                        .foregroundStyle(eventViewModel.selectedSection == section ? .textBlue : .textBlack)
                        .font(.custom(eventViewModel.selectedSection == section ? UIConfig.Font.Name.Medium : UIConfig.Font.Name.Regular, size: UIConfig.Font.Size.Body))
                        .onTapGesture {
                            withAnimation {
                                eventViewModel.selectedSection = section
                            }
                        }
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(.uiGray)
        .frame(width: 210, height: 44, alignment: .center)
        .clipShape(RoundedRectangle(cornerRadius: .infinity))
    }
}
