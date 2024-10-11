//
//  EventInviteCardView.swift
//  Tabi
//
//  Created by Elian Richard on 08/10/24.
//

import SwiftUI
import Contacts

struct EventInviteCardView: View {
    @EnvironmentObject var eventInviteViewModel: EventInviteViewModel
    
    var name: String
    var number: String
    var label: String
    
    @State var isSelected: Bool = false
    var isLast: Bool = false
    
    var body: some View {
        VStack (spacing: 0) {
            HStack {
                VStack (alignment: .leading, spacing: 6) {
                    HStack (spacing: 0) {
                        Text("\(name) (\(label))")
                    }
                    Text("\(number)")
                        .font(.caption)
                }
                Spacer()
                if isSelected {
                    Circle()
                        .fill(.green)
                        .frame(width: 16)
                        .offset(x: -1)
                } else {
                    Circle()
                        .stroke(.black, lineWidth: 1)
                        .fill(.clear)
                        .frame(width: 16)
                        .offset(x: -1)
                }
            }
            .padding(.vertical, 12)
            .background(.clear)
            .contentShape(Rectangle())
            .onTapGesture {
                if (!isSelected) {
                    eventInviteViewModel.selectedContacts.append(UserData(name: name, phone: number))
                } else {
                    eventInviteViewModel.selectedContacts = eventInviteViewModel.selectedContacts.filter { $0.phone != number }
                }
                isSelected = !isSelected
            }
            
            if (isLast == false) {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(UIColor(hex: "#D9D9D9")))
            }
        }
        .onAppear {
//            print(eventInviteViewModelsel)
            isSelected = eventInviteViewModel.selectedContacts.contains(where: { $0.phone == number })
        }
    }
}

#Preview {
    EventInviteCardView(name: "Albert Einstein", number: "02134567890", label: "Home")
}
