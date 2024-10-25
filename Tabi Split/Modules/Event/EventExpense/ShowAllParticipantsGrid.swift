//
//  ShowAllParticipantsGrid.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 23/10/24.
//

import Foundation
import SwiftUI

struct ShowAllParticipantsGrid: View {
    @Environment(EventViewModel.self) private var eventViewModel
    @Environment(EventExpenseViewModel.self) private var eventExpenseViewModel
    @Binding var close: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20){
            Text("Select Participants")
                .font(.tabiTitle)
            ScrollView{
                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 5), spacing: 16){
                    ForEach(eventViewModel.selectedEvent?.participants ?? []) { person in
                        VStack{
                            Circle()
                                .frame(width: 40, height: 40)
                                .background{
                                    Circle()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(.buttonGreen)
                                        .opacity(!eventExpenseViewModel.selectedParticipants.contains(person) ? 0 : 1)
                                    Circle()
                                        .frame(width: 45, height: 45)
                                        .foregroundColor(.bgWhite)
                                        .opacity(!eventExpenseViewModel.selectedParticipants.contains(person) ? 0 : 1)
                                }
                            Text(person.name.getFirstName())
                                .font(.subheadline)
                                .lineLimit(1)
                        }
                        .onTapGesture {
                            if !eventExpenseViewModel.selectedParticipants.contains(person){
                                eventExpenseViewModel.selectedParticipants.append(person)
                            } else {
                                if let removeIndex = eventExpenseViewModel.selectedParticipants.firstIndex(of: person) {
                                    eventExpenseViewModel.selectedParticipants.remove(at: removeIndex)
                                }
                            }
                        }
                    }
                }
                .padding(12)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.clear)
                        .stroke(.bgGreyOverlay, lineWidth: 0.5)
                }
            }
            CustomButton(text: "Done", isEnabled: !eventExpenseViewModel.selectedParticipants.isEmpty ? true : false) {
                close.toggle()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .padding([.top], 10)
    }
}
