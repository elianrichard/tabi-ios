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
        VStack{
            ScrollView{
                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 5), spacing: 16){
                    ForEach(eventViewModel.selectedEvent?.participants ?? []) { person in
                        VStack{
                            Circle()
                                .frame(width: 40, height: 40)
                                .background{
                                    Circle()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(.gray)
                                        .opacity(!eventExpenseViewModel.selectedParticipants.contains(person) ? 0 : 0.5)
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
                .padding()
                .background(
                    Color(.uiGray)
                )
                .cornerRadius(5)
            }
            BottomButton(text: "Save")
                .onTapGesture {
                    close.toggle()
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .padding([.top], 10)
    }
}
