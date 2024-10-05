//
//  HomeView.swift
//  Tabi
//
//  Created by Elian Richard on 03/10/24.
//

import SwiftUI

var temporaryEvents: [EventData] = [
    EventData(eventName: "Korea Trip", completionDate: nil, userEventBalance: 0, transactions: []),
    EventData(eventName: "London Trip", completionDate: Date(), userEventBalance: 300_000, transactions: [10]),
    EventData(eventName: "Paris Trip", completionDate: Date(), userEventBalance: -300_000, transactions: [10]),
    EventData(eventName: "New York Trip", completionDate: nil, userEventBalance: 0, transactions: [10])
]

struct HomeView: View {
    @EnvironmentObject var routes: Routes
    @StateObject var homeViewModel = HomeViewModel()
    
    var body: some View {
        ZStack {
            VStack (alignment: .leading, spacing: 0) {
                HStack (spacing: 10){
                    HStack (spacing: 10 ){
                        Circle()
                            .fill(Color(UIColor(hex: "#D9D9D9")))
                            .frame(width: 40)
                        Text("Hi, You!")
                            .font(.body)
                    }
                    Spacer()
                    Button {
                        print("Notifications")
                    } label: {
                        Image(systemName: "bell.circle.fill")
                            .font(.title)
                            .foregroundStyle(.black)
                    }
                }
                Spacer(minLength: 52)
                VStack (alignment: .leading, spacing: 15) {
                    Text("Events")
                        .font(.title)
                    ScrollView (.horizontal, showsIndicators: false) {
                        HStack (spacing: 10) {
                            ForEach(HomeFilterItems.allCases) { item in
                                Button {
                                    homeViewModel.selectedFilter = item
                                } label: {
                                    NuggetView(text: item.displayName, isSelected: item == homeViewModel.selectedFilter)
                                }
                            }
                        }
                    }
                }
                Spacer(minLength: 30)
                ScrollView {
                    VStack (spacing: 11) {
                        ForEach(temporaryEvents) { event in
                            EventCardView(event: event)
                        }
                    }
                }
                Spacer(minLength: 50)
                
            }
            .padding()
            VStack {
                HStack {
                    Button {
                        print("Navigate to Create Event")
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(.black)
                            .font(.title)
                            .frame(width: 70, height: 70)
                            .background(Color(UIColor(hex: "#EBEBEB")))
                            .clipShape(RoundedRectangle(cornerRadius: 50))
                    }
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(20)
            .ignoresSafeArea()
        }
    }
}

#Preview {
    HomeView()
}
