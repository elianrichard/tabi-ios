//
//  HomeView.swift
//  Tabi
//
//  Created by Elian Richard on 03/10/24.
//

import SwiftUI

struct HomeView: View {
    @Environment(Routes.self) private var routes
    @State var homeViewModel = HomeViewModel()
    @Environment(EventViewModel.self) var eventViewModel: EventViewModel

    var body: some View {
        ZStack {
            VStack (alignment: .leading, spacing: 0) {
                HStack (spacing: 10){
                    HStack (spacing: 10){
                        Image(.sampleUserProfile1)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2),radius: 4, y: 3)
                        Text("Hi, User!")
                            .font(.tabiHeadline)
                    }
                    Spacer()
                    Button {
                        print("Notifications")
                    } label: {
                        Image(systemName: "bell")
                            .font(.title3)
                            .foregroundStyle(.black)
                    }
                }
                Spacer(minLength: 52)
                VStack (alignment: .leading, spacing: 15) {
                    Text("Events")
                        .font(.tabiLargeTitle)
                    ScrollView (.horizontal, showsIndicators: false) {
                        HStack (spacing: 10) {
                            ForEach(HomeFilterEnum.allCases) { item in
                                Button {
                                    homeViewModel.selectedFilter = item
                                } label: {
                                    Nugget(text: item.displayName, isSelected: item == homeViewModel.selectedFilter)
                                }
                            }
                        }
                    }
                }
                Spacer(minLength: 30)
                if (!homeViewModel.filteredEvents.isEmpty) {
                    ScrollView {
                        VStack (spacing: 11) {
                            ForEach(homeViewModel.filteredEvents) { event in
                                EventCardView(event: event)
                                    .onTapGesture {
                                        eventViewModel.selectedEvent = event
                                        routes.navigate(to: .EventDetailView)
                                    }
                            }
                        }
                    }
                } else {
                    VStack (alignment: .center, spacing: 16) {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(UIColor(hex: "#D9D9D9")))
                            .frame(width: 300, height: 180)
                        Text("You don't have any\nevent yet...")
                            .multilineTextAlignment(.center)
                            .font(.title3)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    Spacer()
                }
                Spacer(minLength: 50)

            }
            .padding()
            VStack {
                HStack {
                    Button {
                        eventViewModel.selectedEvent = nil
                        routes.navigate(to: .EventFormView)
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(.white)
                            .font(.title)
                            .frame(width: 56, height: 56)
                            .background(.buttonBlue)
                            .clipShape(RoundedRectangle(cornerRadius: 50))
                    }
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(20)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            let data = SwiftDataService.shared.fetchAllEvents()
            homeViewModel.populateEvents(data: data ?? [])
        }
    }
}

#Preview {
    HomeView()
        .environment(EventViewModel())
        .environment(Routes())
}
