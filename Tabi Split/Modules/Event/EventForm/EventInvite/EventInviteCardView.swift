//
//  EventInviteCardView.swift
//  Tabi
//
//  Created by Elian Richard on 08/10/24.
//

import SwiftUI
import Contacts

struct EventInviteCardView: View {
    @Environment(EventInviteViewModel.self) private var eventInviteViewModel
    
    var name: String
    var number: String
    var label: String
    
    @State var isSelected: Bool = false
    var isLast: Bool = false
    
    var body: some View {
        VStack (spacing: 0) {
            HStack {
                HStack (spacing: .spacingSmall) {
                    UserAvatar(userData: UserData(name: name, phone: number))
                    VStack (alignment: .leading, spacing: .spacingXSmall) {
                        Text("\(name) (\(label))")
                            .font(.tabiHeadline)
                        Text("\(number)")
                            .font(.tabiBody)
                    }
                }
                Spacer()
                Circle()
                    .stroke(isSelected ? .buttonGreen : .textGrey, lineWidth: 1)
                    .fill(isSelected ? .buttonGreen : .clear)
                    .frame(width: 20)
                    .overlay {
                        if isSelected {
                            Icon(systemName: "checkmark", color: .textWhite, size: 10)
                        }
                    }
                    .offset(x: -1)
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
            isSelected = eventInviteViewModel.selectedContacts.contains(where: { $0.phone == number })
        }
    }
}

#Preview {
    VStack{
        EventInviteCardView(name: "Albert Einstein", number: "02134567890", label: "Home")
    }
    .padding()
    .environment(EventInviteViewModel())
}
