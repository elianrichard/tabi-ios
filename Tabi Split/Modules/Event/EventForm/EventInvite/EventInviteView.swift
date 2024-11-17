//
//  EventInviteView.swift
//  Tabi
//
//  Created by Elian Richard on 08/10/24.
//

import SwiftUI
import Contacts
import UniformTypeIdentifiers


struct EventInviteView: View {
    @Environment(Routes.self) private var routes
    @Environment(EventViewModel.self) private var eventViewModel
    @Environment(EventInviteViewModel.self) private var eventInviteViewModel
    @Environment(ProfileViewModel.self) private var profileViewModel
    
    @State private var isLinkCopied = false
    @State private var isShowQrSheet = false
    
    var body: some View {
        VStack (spacing: 0) {
            TopNavigation(title: "Add Participants", additionalBackFunction: {
                eventInviteViewModel.searchUserText = ""
            })
            VStack(spacing: .spacingMedium){
//                TEMPORARILY DISABLED: INVITE BY LINK AND QR CODE
                if (false) {
                    HStack (spacing: .spacingMedium) {
                        EventInviteShareButtonView(text: isLinkCopied ? "Copied!" : "Copy Link",
                                                   icon: isLinkCopied ? .checkIcon : .linkIcon,
                                                   action: {
                            if !isLinkCopied {
                                withAnimation (nil) {
                                    isLinkCopied = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation(nil)  {
                                        isLinkCopied = false
                                    }
                                }
                                UIPasteboard.general.setValue("https://tabieventinvitelink.com", forPasteboardType: UTType.plainText.identifier)
                            }
                        })
                        ShareLink(item: URL(filePath: "https://tabieventinvitelink.com")!) {
                            EventInviteShareButtonView(text: "Share Link", icon: .shareIcon)
                        }
                        EventInviteShareButtonView(text: "QR Code",
                                                   icon: .qrIcon,
                                                   action: {
                            isShowQrSheet = true
                        })
                    }
                }
                SearchInput(text: Bindable(eventInviteViewModel).searchUserText, placeholder: "Search or Add New Participants")
                VStack (spacing: .spacingTight) {
                    ScrollView (showsIndicators: false) {
                        LazyVStack (spacing: 0) {
                            Divided {
                                EventInviteCardView(userData: profileViewModel.user, isCurrentUser: true)
                                ForEach(eventInviteViewModel.selectedContactsList.filter{ $0 != profileViewModel.user }) { contact in
                                    EventInviteCardView(userData: contact, isSelected: true)
                                }
                                ForEach(eventInviteViewModel.unselectedContactsList) { contact in
                                    EventInviteCardView(userData: contact)
                                }
                            }
                        }
                    }
                    
                    CustomButton(text: "Add", isEnabled: eventInviteViewModel.selectedContacts.count > 0) {
                        eventViewModel.selectedEvent?.participants = eventInviteViewModel.selectedContacts
                        eventInviteViewModel.searchUserText = ""
                        routes.navigateBack()
                    }
                }
            }
        }
        .padding()
        .onAppear {
            if eventInviteViewModel.allContacts.count == 0, let currentUser = SwiftDataService.shared.getCurrentUser() {
                DispatchQueue.global(qos: .background).async {
                    eventInviteViewModel.fillUpContacts(currentUser: currentUser)
                }
            }
            if let selectedEvent = eventViewModel.selectedEvent {
                eventInviteViewModel.selectedContacts = selectedEvent.participants
            }
        }
        .sheet(isPresented: $isShowQrSheet) {
            VStack (spacing: 0) {
                SheetXButton(toggle: $isShowQrSheet)
                VStack (alignment: .center, spacing: .spacingSmall) {
                    Text("Show QR Code")
                        .font(.tabiTitle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    VStack (alignment: .center, spacing: .spacingSmall) {
                        Image(.sampleBarcodeQr)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .background(.red)
                        Text("Let your friends scan it to participate in your event")
                            .font(.tabiHeadline)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .padding()
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .navigationBarBackButtonHidden(true)
    }
    
}

#Preview {
    EventInviteView()
        .environment(Routes())
        .environment(EventViewModel())
        .environment(EventInviteViewModel())
}
