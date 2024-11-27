//
//  SelectParticipantsSheet.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 23/10/24.
//

import Foundation
import SwiftUI

struct SelectParticipantsSheet: View {
    @Environment(EventViewModel.self) private var eventViewModel
    @Environment(EventExpenseViewModel.self) private var eventExpenseViewModel
    @Environment(ProfileViewModel.self) private var profileViewModel

    @Binding var isPresented: Bool
    
    var participants: [UserData] {
        var value: [UserData] = []
        if let selectedEvent = eventViewModel.selectedEvent {
            value.append(contentsOf: selectedEvent.participants.filter { !profileViewModel.isCurrentUser($0) }.sorted(by: { $0.name < $1.name }))
        }
        value.insert(profileViewModel.user, at: 0)
        return value
    }
    
    var body: some View {
        VStack{
            SheetXButton(toggle: $isPresented)
            VStack(spacing: .spacingMedium){
                Text("Select Participants")
                    .font(.tabiTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ScrollView{
                    VStack{
                        LazyVStack (spacing: .spacingTight){
                            Divided{
                                ForEach (participants) { person in
                                    HStack{
                                        UserCard(user: person, isShowYouText: true)
                                        Spacer()
                                        Circle()
                                            .stroke(eventExpenseViewModel.selectedParticipants.contains(person) ? .buttonBlue : .textGrey, lineWidth: 1)
                                            .fill(eventExpenseViewModel.selectedParticipants.contains(person) ? .buttonBlue : .clear)
                                            .frame(width: 20)
                                            .overlay {
                                                if eventExpenseViewModel.selectedParticipants.contains(person) {
                                                    Icon(systemName: "checkmark", color: .textWhite, size: 10)
                                                }
                                            }
                                            .offset(x: -1)
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if !eventExpenseViewModel.selectedParticipants.contains(person){
                                            eventExpenseViewModel.selectedParticipants.append(person)
                                        } else {
                                            if let removeIndex = eventExpenseViewModel.selectedParticipants.firstIndex(of: person) {
                                                eventExpenseViewModel.selectedParticipants.remove(at: removeIndex)
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                }
                CustomButton(text: "Done"){
                    isPresented.toggle()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .padding()
        .padding([.top], 10)
    }
}

#Preview {
    SelectParticipantsSheet(isPresented: .constant(false))
        .environment(EventViewModel())
        .environment(EventExpenseViewModel())
}
