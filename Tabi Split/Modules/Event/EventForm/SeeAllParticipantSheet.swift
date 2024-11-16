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
    
    var body: some View {
        VStack{
            SheetXButton(toggle: $isPresented)
            VStack(spacing: .spacingMedium){
                Text("All Participants")
                    .font(.tabiTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack{
                    Icon(systemName: "magnifyingglass", color: .textGrey, size: 18)
                    TextField("", text: $nameToBeSearched, prompt: Text("Search").foregroundStyle(.textGrey))
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .background(.uiWhite)
                .clipShape(RoundedRectangle(cornerRadius: .infinity))
                .foregroundStyle(.black)
                .font(.tabiBody)
                .overlay {
                    RoundedRectangle(cornerRadius: .infinity)
                        .fill(.clear)
                        .stroke(.bgGreyOverlay, lineWidth: 0.5)
                        .padding(0.5)
                }
                ScrollView{
                    LazyVStack (spacing: .spacingTight){
                        Divided{
                            ForEach (eventViewModel.selectedEvent?.participants.filter {
                                nameToBeSearched.isEmpty || $0.name.lowercased().contains(nameToBeSearched.lowercased())
                            } ?? []) { user in
                                HStack{
                                    UserAvatar(userData: user)
                                    VStack(alignment: .leading){
                                        Text(user.name)
                                            .font(.tabiHeadline)
                                        Text(user.phone)
                                            .font(.tabiBody)
                                            .foregroundColor(.textGrey)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .padding()
        .padding([.top], 10)
    }
}

#Preview {
    SeeAllParticipantSheet(isPresented: .constant(false ))
        .environment(EventViewModel())
}
