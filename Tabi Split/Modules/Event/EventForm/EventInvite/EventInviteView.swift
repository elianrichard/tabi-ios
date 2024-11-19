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
    @State private var isShowCustomParticipantSheet = false
    
    @State private var customName = ""
    @State private var customPhone = ""
    
    @State private var customNameError: String? = nil
    @State private var customPhoneError: String? = nil
    
    @FocusState private var focusedField: FocusField?
    
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
                                if (eventInviteViewModel.searchUserText == "") {
                                    EventInviteCardView(userData: profileViewModel.user, isCurrentUser: true)
                                }
                                ForEach(eventInviteViewModel.selectedContactsList.filter{ $0 != profileViewModel.user }) { contact in
                                    EventInviteCardView(userData: contact, isSelected: true)
                                }
                                ForEach(eventInviteViewModel.unselectedContactsList) { contact in
                                    EventInviteCardView(userData: contact)
                                }
                                if (eventInviteViewModel.searchUserText != "") {
                                    Button {
                                        customName = eventInviteViewModel.searchUserText
                                        isShowCustomParticipantSheet = true
                                    } label: {
                                        HStack (spacing: .spacingTight) {
                                            Icon(systemName: "plus", color: .buttonBlue, size: 20)
                                                .frame(width: 40, height: 40)
                                                .addDashedCircleBorder()
                                            Text("Add \(eventInviteViewModel.searchUserText) as a participant")
                                                .font(.tabiBody)
                                                .foregroundStyle(.buttonBlue)
                                                .multilineTextAlignment(.leading)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, .spacingTight)
                                    }
                                }
                            }
                        }
                    }
                    
                    CustomButton(text: eventInviteViewModel.isLoadContactLoading ? "Loading Contacts..." : "Add", isEnabled: !eventInviteViewModel.isLoadContactLoading && eventInviteViewModel.selectedContactsList.count > 1) {
                        eventViewModel.selectedEvent?.participants = eventInviteViewModel.selectedContacts
                        eventInviteViewModel.searchUserText = ""
                        routes.navigateBack()
                    }
                }
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if eventInviteViewModel.allContacts.count == 0,
               let currentUser = SwiftDataService.shared.getCurrentUser(),
               let allUsers = SwiftDataService.shared.getAllUsers(excludeLoggedUser: true) {
                DispatchQueue.global(qos: .background).async {
                    eventInviteViewModel.fillUpContacts(currentUser: currentUser, registeredUsers: allUsers)
                }
            }
            if let selectedEvent = eventViewModel.selectedEvent {
                eventInviteViewModel.selectedContacts = selectedEvent.participants
            }
        }
        .sheet(isPresented: $isShowCustomParticipantSheet) {
            CustomSheet(xToggleBinding: $isShowCustomParticipantSheet) {
                VStack (alignment: .center, spacing: .spacingMedium) {
                    Text("Add Participant Details")
                        .font(.tabiTitle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    VStack (spacing: .spacingRegular) {
                        DialogBox(image: .dialogIcon, iconSize: 36, text: "Enter the phone number to be connected to their account.", isClosable: false)
                        VStack (alignment: .center, spacing: .spacingRegular) {
                            InputWithLabel(label: "Name", placeholder: "Enter participant name", text: $customName, errorMessage: customNameError, focusedField: $focusedField, focusCase: .field1)
                            InputWithLabel(label: "Phone Number", isOptional: true, placeholder: "Enter phone number", text: $customPhone, errorMessage: customPhoneError, inputTypePicked: .phone, focusedField: $focusedField, focusCase: .field2)
                        }
                    }
                }
                Spacer()
                CustomButton (text: "Save") {
                    let phone = customPhone.formattedAsPhoneNumber()
                    
                    if customName == "" {
                        customNameError = "Name cannot be empty"
                        return
                    } else { customNameError = nil }
                    
                    if eventInviteViewModel.allContacts.contains(where: { $0.phone == phone }) || phone == profileViewModel.user.phone {
                        customPhoneError = "Phone number already registered"
                        return
                    } else { customPhoneError = nil }
                    
                    let newUser = UserData(name: customName, phone: customPhone != "" ? phone : "")
                    eventInviteViewModel.allContacts.append(newUser)
                    eventInviteViewModel.selectedContacts.append(newUser)
                    eventInviteViewModel.searchUserText = ""
                    isShowCustomParticipantSheet = false
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowQrSheet) {
            CustomSheet (xToggleBinding: $isShowQrSheet) {
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
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
    
}

#Preview {
    EventInviteView()
        .environment(Routes())
        .environment(EventViewModel())
        .environment(EventInviteViewModel())
}
