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
                HomeTopBar()
                Spacer(minLength: 52)
                EventFilterList(homeViewModel: homeViewModel)
                Spacer(minLength: 30)
                if (!homeViewModel.filteredEvents.isEmpty) {
                    ScrollView {
                        VStack (spacing: 11) {
                            ForEach(homeViewModel.filteredEvents) { event in
                                EventCard(event: event)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        eventViewModel.selectedEvent = event
                                        routes.navigate(to: .EventDetailView)
                                    }
                            }
                        }
                    }
                } else {
                    EventEmptyList()
                }
            }
            .padding()
            
            VStack {
                HStack {
                    Button {
                        eventViewModel.selectedEvent = nil
                        routes.navigate(to: .EventFormView)
                    } label: {
                        Icon(systemName: "plus", color: .textWhite, size: 24)
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
