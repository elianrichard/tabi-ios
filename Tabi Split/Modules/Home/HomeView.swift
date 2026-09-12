//
//  HomeView.swift
//  Tabi
//
//  Created by Elian Richard on 03/10/24.
//

import SwiftUI

struct HomeView: View {
    @Environment(Router.self) private var router
    @State var homeViewModel = HomeViewModel()
    @Environment(EventViewModel.self) var eventViewModel: EventViewModel
    @Environment(ProfileViewModel.self) var profileViewModel: ProfileViewModel
    @Environment(LoadingViewModel.self) var loadingViewModel: LoadingViewModel
    
    var body: some View {
        ZStack {
            VStack (alignment: .leading, spacing: 0) {
                HomeTopBar(homeViewModel: homeViewModel)
                    .padding(.horizontal)
                Spacer(minLength: .spacingMedium)
                EventFilterList(homeViewModel: homeViewModel)
                Spacer(minLength: 30)
                if (!homeViewModel.filteredEvents.isEmpty) {
                    ScrollView (showsIndicators: false) {
                        LazyVStack (spacing: 11) {
                            ForEach(homeViewModel.filteredEvents) { event in
                                EventCard(event: event)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        eventViewModel.selectedEvent = event
                                        router.push(.eventDetail)
                                    }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 90)
                    }
                    .refreshable {
                        await refreshData(isShowLoading: false)
                    }
                } else {
                    ScrollView (showsIndicators: false) {
                        EventEmptyList()
                            .frame(maxWidth: .infinity, minHeight: 400)
                    }
                    .refreshable {
                        await refreshData(isShowLoading: false)
                    }
                }
            }
            .padding(.top)
            
            if homeViewModel.filteredEvents.count != 0 {
                VStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .mask(LinearGradient(gradient: Gradient(colors: [.black, .black, .black.opacity(0)]), startPoint: .bottom, endPoint: .top))
                        .frame(maxWidth: .infinity, maxHeight: 120)
                        .allowsHitTesting(false)
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            
            VStack {
                HStack {
                    Button {
                        eventViewModel.selectedEvent = nil
                        router.push(.eventForm)
                    } label: {
                        Icon(systemName: "plus", color: .textWhite, size: 24)
                            .frame(width: 64, height: 64)
                            .background(.buttonBlue)
                            .clipShape(RoundedRectangle(cornerRadius: .infinity))
                    }
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(20)
        }
        .ignoresSafeArea()
        .padding(.top)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if SwiftDataService.shared.consumeRecoveryNotice() {
                ToastViewModel.shared.show("Local data was reset and is reloading from your account.", style: .info, duration: 6)
            }
            Task {
                await refreshData(isShowLoading: true)
            }
            // Home = first authed screen, so the push prompt lands after sign-in.
            // Re-running on every appear also re-binds the token after account switch.
            Task { await PushService.shared.requestAuthorizationAndRegister() }
        }
    }

    private func refreshData(isShowLoading: Bool) async {
        profileViewModel.refreshUserData()
        let loadingBinding = isShowLoading ? Bindable(loadingViewModel).isLoading : .constant(false)
        if await homeViewModel.refreshEventData(currentUser: profileViewModel.user, isShowLoading: loadingBinding) {
            SwiftDataService.shared.deleteUsersWithNoId()
        }
    }
}

#Preview {
    HomeView()
        .environment(EventViewModel())
        .environment(Router())
}
