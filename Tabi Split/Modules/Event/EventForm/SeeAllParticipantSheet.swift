//
//  SeeAllParticipantSheet.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 12/11/24.
//

import Foundation
import SwiftUI

struct SeeAllParticipantSheet: View {
    @Environment(EventViewModel.self) private var eventViewModel
    @Binding var isPresented: Bool
    @State var nameToBeSearched: String = ""
    var participantsList: [UserData] = []
    
    var body: some View {
        CustomSheet (xToggleBinding: $isPresented) {
            VStack(spacing: .spacingMedium) {
                Text("All Participants")
                    .font(.tabiTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                SearchInput(text: $nameToBeSearched, placeholder: "Search")
                ScrollView{
                    LazyVStack (spacing: .spacingTight){
                        Divided{
                            ForEach (participantsList.filter {
                                nameToBeSearched.isEmpty || $0.name.lowercased().contains(nameToBeSearched.lowercased())
                            }) { user in
                                UserCard(user: user)
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    SeeAllParticipantSheet(isPresented: .constant(false ))
        .environment(EventViewModel())
}
