//
//  EventInviteView.swift
//  Tabi
//
//  Created by Elian Richard on 08/10/24.
//

import SwiftUI
import Contacts
import UniformTypeIdentifiers
import CoreImage.CIFilterBuiltins

struct EventInviteView: View {
    @Environment(Routes.self) private var routes
    @Environment(EventViewModel.self) private var eventViewModel
    @Environment(EventInviteViewModel.self) private var eventInviteViewModel
    @Environment(ProfileViewModel.self) private var profileViewModel
    
    @State private var isLinkCopied = false
    @State private var isShowQrSheet = false
    @State private var isShowCustomParticipantSheet = false
    
    @State private var sheetHeight: CGFloat = 0
    
    private var deeplinkHost = "tabi-web.vercel.app"
    
    var body: some View {
        VStack (spacing: 0) {
            TopNavigation(title: "Add Participants", additionalBackFunction: {
                eventInviteViewModel.searchUserText = ""
            })
            VStack(spacing: .spacingMedium){
                if !profileViewModel.isGuest {
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
                                UIPasteboard.general.setValue("https://\(deeplinkHost)/join?eventId=\(eventViewModel.selectedEvent?.eventId ?? "")", forPasteboardType: UTType.plainText.identifier)
                            }
                        })
                        ShareLink(item: URL(filePath: "https://\(deeplinkHost)/join?eventId=\(eventViewModel.selectedEvent?.eventId ?? "")")) {
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
                    
                    CustomButton(text: eventInviteViewModel.isLoadContactLoading ? "Loading Contacts..." : "Add",
                                 isEnabled: !eventInviteViewModel.isLoadContactLoading && eventInviteViewModel.selectedContacts.count > 1) {
                        eventInviteViewModel.searchUserText = ""
                        if (eventViewModel.isDirectInvite) {
                            Task {
                                if await eventViewModel.handleEditEvent(selectedContacts: eventInviteViewModel.selectedContacts,
                                                                        currentUser: profileViewModel.user,
                                                                        isGuest: profileViewModel.isGuest) {
                                    routes.navigateBack()
                                }
                            }
                        } else {
                            routes.navigateBack()
                        }
                    }
                }
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if let currentUser = SwiftDataService.shared.getCurrentUser(),
               let allUsers = SwiftDataService.shared.getAllUsers(excludeLoggedUser: true, isUnique: true) {
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
                VStack (spacing: .spacingLarge) {
                    VStack (spacing: .spacingMedium) {
                        Image(.eventUnregistered)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                        VStack (spacing: .spacingSmall) {
                            Text("Add an unregistered participant?")
                                .font(.tabiSubtitle)
                                .multilineTextAlignment(.center)
                            Text("You can replace **'\(eventInviteViewModel.searchUserText)'** with their real account later.")
                                .font(.tabiBody)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    CustomButton (text: "Add") {
                        let newUser = UserData(name: eventInviteViewModel.searchUserText, phone: "")
                        eventInviteViewModel.allContacts.append(newUser)
                        eventInviteViewModel.selectedContacts.append(newUser)
                        eventInviteViewModel.searchUserText = ""
                        isShowCustomParticipantSheet = false
                    }
                }
            }
            .presentationDetents([.height(sheetHeight)])
            .presentationDragIndicator(.visible)
            .background (
                GeometryReader { geometry in
                    Color.clear.onAppear {
                        sheetHeight = geometry.size.height
                    }
                }
            )
        }
        .sheet(isPresented: $isShowQrSheet) {
            CustomSheet (xToggleBinding: $isShowQrSheet) {
                VStack (alignment: .center, spacing: .spacingSmall) {
                    Text("Show QR Code")
                        .font(.tabiTitle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    VStack (alignment: .center, spacing: .spacingMedium) {
                        Image(uiImage: generateQRCode(from: "tabisplit://join-event?event-id=\(eventViewModel.selectedEvent?.eventId ?? "")"))
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                                .frame(width: 200, height: 200)
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
    
    private func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        
        
        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 1, y: 1) // Adjust scaling factor as needed
            let scaledImage = outputImage.transformed(by: transform)
  
            if let cgImage = context.createCGImage(outputImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }

        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
    
}

#Preview {
    EventInviteView()
        .environment(Routes())
        .environment(EventViewModel())
        .environment(EventInviteViewModel())
}
