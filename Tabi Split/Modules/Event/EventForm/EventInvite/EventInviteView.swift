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
    @Environment(Router.self) private var router
    @Environment(EventViewModel.self) private var eventViewModel
    @Environment(EventInviteViewModel.self) private var eventInviteViewModel
    @Environment(ProfileViewModel.self) private var profileViewModel
    
    @State private var isLinkCopied = false
    @State private var isShowQrSheet = false

    // Email-invite flow: when the typed text is an email, present this payload.
    // Driving the sheet with `.sheet(item:)` (rather than a bool + separate
    // @State) avoids a stale-state race where the sheet body would snapshot the
    // old `alreadyAddedName` because it was set in the same tick the sheet opened.
    @State private var inviteByEmailPayload: InviteByEmailPayload?
    @State private var inviteNameText = ""
    @FocusState private var focusedField: FocusField?

    // Payload for the invite-by-email sheet. `existingName` is non-nil when the
    // email is already a selected participant, switching the sheet to an info
    // message instead of the add form.
    private struct InviteByEmailPayload: Identifiable {
        let email: String
        let existingName: String?
        var id: String { email }
    }

    private var deeplinkHost = "tabi-web.vercel.app"
    
    var body: some View {
        VStack (spacing: 0) {
            TopNavigation(title: "Add Participants", additionalBackFunction: {
                eventInviteViewModel.searchUserText = ""
            })
            VStack(spacing: .spacingMedium){
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
                    if let url = URL(string: "https://\(deeplinkHost)/join?eventId=\(eventViewModel.selectedEvent?.eventId ?? "")") {
                        ShareLink(item: url) {
                            EventInviteShareButtonView(text: "Share Link", icon: .shareIcon)
                        }
                    }
                    EventInviteShareButtonView(text: "QR Code",
                                               icon: .qrIcon,
                                               action: {
                        isShowQrSheet = true
                    })
                }
                SearchInput(text: Bindable(eventInviteViewModel).searchUserText, placeholder: "Search / Add New Participants by Name / Email")
                VStack (spacing: .spacingTight) {
                    ScrollView (showsIndicators: false) {
                        LazyVStack (spacing: 0) {
                            Divided {
                                if (eventInviteViewModel.searchUserText == "") {
                                    EventInviteCardView(userData: profileViewModel.user, isCurrentUser: true)
                                }
                                ForEach(eventInviteViewModel.selectedContactsList.filter{ !profileViewModel.isCurrentUser($0) }) { contact in
                                    EventInviteCardView(userData: contact, isSelected: true)
                                }
                                ForEach(eventInviteViewModel.unselectedContactsList) { contact in
                                    EventInviteCardView(userData: contact)
                                }
                                if (eventInviteViewModel.searchUserText != "") {
                                    Button {
                                        let searchText = eventInviteViewModel.searchUserText
                                        if searchText.isValidEmail {
                                            // Email typed: prompt for a name before
                                            // adding, so it enters the list as a real
                                            // participant rather than a name-only dummy.
                                            let email = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                                            inviteNameText = ""
                                            // If this email is already selected (including
                                            // the current user), show an info message
                                            // instead of the add form.
                                            let existingName: String?
                                            if profileViewModel.user.email.lowercased() == email {
                                                existingName = profileViewModel.user.name
                                            } else {
                                                existingName = eventInviteViewModel.selectedUser(withEmail: email)?.name
                                            }
                                            inviteByEmailPayload = InviteByEmailPayload(email: email, existingName: existingName)
                                        } else {
                                            let newUser = UserData(name: searchText, email: "")
                                            eventInviteViewModel.allContacts.append(newUser)
                                            eventInviteViewModel.selectedContacts.append(newUser)
                                            eventInviteViewModel.searchUserText = ""
                                        }
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
                    
                    CustomButton(text: eventInviteViewModel.isLoadContactLoading ? "Loading Contacts..." : "Save",
                                 isEnabled: !eventInviteViewModel.isLoadContactLoading && eventInviteViewModel.selectedContacts.count > 1) {
                        eventInviteViewModel.searchUserText = ""
                        if (eventViewModel.isDirectInvite) {
                            Task {
                                if await eventViewModel.handleEditEvent(selectedContacts: eventInviteViewModel.selectedContacts,
                                                                        currentUser: profileViewModel.user) {
                                    router.pop()
                                }
                            }
                        } else {
                            router.pop()
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
        .sheet(item: $inviteByEmailPayload) { payload in
            CustomSheet(xToggleBinding: Binding(
                get: { inviteByEmailPayload != nil },
                set: { if !$0 { inviteByEmailPayload = nil } }
            )) {
                VStack(alignment: .leading, spacing: .spacingMedium) {
                    VStack(alignment: .leading, spacing: .spacingXSmall) {
                        Text("Invite by Email")
                            .font(.tabiTitle)
                        Text(payload.email)
                            .font(.tabiBody)
                            .foregroundStyle(.textGrey)
                    }
                    if let existingName = payload.existingName {
                        // This email is already a participant: just inform, no add.
                        Text("This email is already added as \(existingName) in the list.")
                            .font(.tabiBody)
                            .foregroundStyle(.textGrey)
                    } else {
                        Input(
                            placeholder: "Participant's Name",
                            text: $inviteNameText,
                            focusedField: $focusedField,
                            focusCase: .field1)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                if payload.existingName != nil {
                    CustomButton(text: "OK") {
                        eventInviteViewModel.searchUserText = ""
                        focusedField = nil
                        inviteByEmailPayload = nil
                    }
                } else {
                    CustomButton(text: "Add Participant",
                                 isEnabled: !inviteNameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                        eventInviteViewModel.addInvitedUser(name: inviteNameText, email: payload.email)
                        eventInviteViewModel.searchUserText = ""
                        focusedField = nil
                        inviteByEmailPayload = nil
                    }
                }
            }
            .presentationDetents([.height(payload.existingName == nil ? 280 : 240)])
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
        .environment(Router())
        .environment(EventViewModel())
        .environment(EventInviteViewModel())
}
