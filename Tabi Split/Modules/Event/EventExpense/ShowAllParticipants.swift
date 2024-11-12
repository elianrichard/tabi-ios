//
//  ShowAllParticipantsGrid.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 23/10/24.
//

import Foundation
import SwiftUI

struct ShowAllParticipants: View {
    @Environment(EventViewModel.self) private var eventViewModel
    @Environment(EventExpenseViewModel.self) private var eventExpenseViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack{
            SheetXButton(toggle: $isPresented)
            VStack(spacing: .spacingMedium){
                Text("Select Participants")
                    .font(.tabiTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ScrollView{
                    VStack{
                        VStack(spacing: .spacingTight){
                            Divided{
                                ForEach (eventViewModel.selectedEvent?.participants ?? []) { person in
                                    HStack{
                                        UserAvatar(userData: person)
                                        VStack(alignment: .leading){
                                            Text(person.name)
                                                .font(.tabiHeadline)
                                            Text(person.phone)
                                                .font(.tabiBody)
                                                .foregroundColor(.textGrey)
                                        }
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
    ShowAllParticipants(isPresented: .constant(false))
        .environment(EventViewModel())
        .environment(EventExpenseViewModel())
}
