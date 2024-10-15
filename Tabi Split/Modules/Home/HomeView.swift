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
                            ForEach(HomeFilterEnum.allCases) { item in
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
                        Text("You don't have any\nevents yet.")
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
        .navigationBarBackButtonHidden(true)
        .onAppear {
            let data = SwiftDataService.shared.fetchAllEvents()
            homeViewModel.populateEvents(data: data ?? [])
        }
        .onAppear {
            let events = SwiftDataService.shared.fetchAllEvents() ?? []
            for event in events {
                print(event.eventName)
                let expenses = SwiftDataService.shared.fetchAllExpense(event)
                for expense in expenses {
                    print(expense.name)
                    for person in expense.participants {
                        print(person.name)
                    }
                    
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .environment(EventViewModel())
        .environment(Routes())
}
