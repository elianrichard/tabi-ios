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

    var userData: UserData
    var label: String
    
    @State var isSelected: Bool = false
    var isLast: Bool = false
    
    
    var body: some View {
        VStack (spacing: 0) {
            HStack {
                HStack (spacing: .spacingSmall) {
                    UserAvatar(userData: userData)
                    VStack (alignment: .leading, spacing: .spacingXSmall) {
                        Text("\(userData.name) (\(label))")
                            .font(.tabiHeadline)
                        Text("\(userData.phone)")
                            .font(.tabiBody)
                            .foregroundStyle(.textGrey)
                    }
                }
                Spacer()
                Circle()
                    .stroke(isSelected ? .buttonBlue : .textGrey, lineWidth: 1)
                    .fill(isSelected ? .buttonBlue : .clear)
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
                    eventInviteViewModel.selectedContacts.append(userData)
                } else {
                    eventInviteViewModel.selectedContacts = eventInviteViewModel.selectedContacts.filter { $0.phone != userData.phone }
                }
                isSelected = !isSelected
            }
        }
        .onAppear {
            isSelected = eventInviteViewModel.selectedContacts.contains(where: { $0.phone == userData.phone })
        }
    }
}
