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

    // Per-share signed invite token (1h TTL). Fetched once when the view appears
    // and reused by Copy / Share / QR; refetched only if the window lapses while
    // the view is open. nil until the first fetch resolves.
    @State private var inviteToken: String?
    @State private var inviteTokenExpiresAt: Date?

    // Email-invite flow: when the typed text is an email, present this payload.
    // Driving the sheet with `.sheet(item:)` (rather than a bool + separate
    // @State) avoids a stale-state race where the sheet body would snapshot the
    // old `alreadyAddedName` because it was set in the same tick the sheet opened.
    @State private var inviteByEmailPayload: InviteByEmailPayload?
    @State private var inviteNameText = ""
    @FocusState private var focusedField: FocusField?

    // Custom-participant sheet: Name (required) + Email (optional).
    @State private var isShowCustomParticipantSheet = false
    @State private var customNameText = ""
    @State private var customEmailText = ""

    // Payload for the invite-by-email sheet. `existingName` is non-nil when the
    // email is already a selected participant, switching the sheet to an info
    // message instead of the add form.
    private struct InviteByEmailPayload: Identifiable {
        let email: String
        let existingName: String?
        var id: String { email }
    }

    private let deeplinkHost = "tabisplit.my.id"

    // The full Universal Link for the current token, or nil until a token is
    // fetched. All three share actions (Copy / Share / QR) use this one shape.
    private var inviteURLString: String? {
        guard let token = inviteToken else { return nil }
        return "https://\(deeplinkHost)/join?token=\(token)"
    }

    // Friendly invite blurb wrapped around the link, used for Copy and Share so
    // the recipient gets context ("what is this link?") instead of a bare URL.
    // Falls back gracefully when the event has no name yet.
    private var inviteMessage: String? {
        guard let urlString = inviteURLString else { return nil }
        let eventName = eventViewModel.selectedEvent?.eventName ?? ""
        let intro = eventName.isEmpty
            ? "Join my event on Tabi so we can split the bills easily 💸"
            : "Join “\(eventName)” on Tabi so we can split the bills easily 💸"
        return "\(intro)\n\nTap to join: \(urlString)"
    }
    
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
                        guard let message = inviteMessage, !isLinkCopied else { return }
                        withAnimation (nil) {
                            isLinkCopied = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(nil)  {
                                isLinkCopied = false
                            }
                        }
                        UIPasteboard.general.setValue(message, forPasteboardType: UTType.plainText.identifier)
                    })
                    if let urlString = inviteURLString, let url = URL(string: urlString),
                       let message = inviteMessage {
                        // Share the URL (so apps render a rich preview) with the
                        // friendly blurb as the accompanying message.
                        ShareLink(item: url, message: Text(message)) {
                            EventInviteShareButtonView(text: "Share Link", icon: .shareIcon)
                        }
                    } else {
                        EventInviteShareButtonView(text: "Share Link", icon: .shareIcon)
                    }
                    EventInviteShareButtonView(text: "QR Code",
                                               icon: .qrIcon,
                                               action: {
                        isShowQrSheet = true
                    })
                }
                SearchInput(text: Bindable(eventInviteViewModel).searchUserText, placeholder: "Search")
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
                    
                    CustomButton(text: "Add Custom Participant", type: .secondary, icon: "plus") {
                        customNameText = ""
                        customEmailText = ""
                        isShowCustomParticipantSheet = true
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
            Task { await fetchInviteTokenIfNeeded() }
        }
        .sheet(isPresented: $isShowQrSheet) {
            CustomSheet (xToggleBinding: $isShowQrSheet) {
                VStack (alignment: .center, spacing: .spacingSmall) {
                    Text("Show QR Code")
                        .font(.tabiTitle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    VStack (alignment: .center, spacing: .spacingMedium) {
                        Image(uiImage: generateQRCode(from: inviteURLString ?? ""))
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
        .sheet(isPresented: $isShowCustomParticipantSheet) {
            CustomSheet(xToggleBinding: $isShowCustomParticipantSheet) {
                VStack(alignment: .leading, spacing: .spacingMedium) {
                    Text("Add Custom Participant")
                        .font(.tabiTitle)
                    VStack(alignment: .leading, spacing: .spacingRegular) {
                        InputWithLabel(
                            label: "Name",
                            placeholder: "Participant's Name",
                            text: $customNameText,
                            focusedField: $focusedField,
                            focusCase: .field1)
                        InputWithLabel(
                            label: "Email",
                            isOptional: true,
                            placeholder: "Participant's Email",
                            text: $customEmailText,
                            errorMessage: customEmailErrorMessage,
                            focusedField: $focusedField,
                            focusCase: .field2)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                CustomButton(text: "Add Participant",
                             isEnabled: isCustomParticipantValid) {
                    addCustomParticipant()
                }
            }
            .presentationDetents([.height(customEmailErrorMessage == nil ? 360 : 390)])
            .presentationDragIndicator(.visible)
        }
    }

    // When the typed email is a valid address already held by a selected
    // participant (or the current user), returns that participant's name so the
    // sheet can show an "already added" message and block the add — mirroring the
    // inline invite-by-email flow.
    private var customEmailExistingName: String? {
        let email = customEmailText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !email.isEmpty, email.isValidEmail else { return nil }
        if profileViewModel.user.email.lowercased() == email {
            return profileViewModel.user.name
        }
        return eventInviteViewModel.selectedUser(withEmail: email)?.name
    }

    // Inline error under the Email field: bad format, or already-added.
    private var customEmailErrorMessage: String? {
        let email = customEmailText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !email.isEmpty && !email.isValidEmail {
            return "Please enter a valid email."
        }
        if let existingName = customEmailExistingName {
            return "This email is already added as \(existingName) in the list."
        }
        return nil
    }

    // Name is required; email is optional but, when provided, must be valid and
    // not already added.
    private var isCustomParticipantValid: Bool {
        let name = customNameText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return false }
        return customEmailErrorMessage == nil
    }

    private func addCustomParticipant() {
        let name = customNameText.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = customEmailText.trimmingCharacters(in: .whitespacesAndNewlines)
        if email.isEmpty {
            // Name-only: add as a dummy participant, mirroring the inline
            // "Add ... as a participant" button.
            let newUser = UserData(name: name, email: "")
            eventInviteViewModel.allContacts.append(newUser)
            eventInviteViewModel.selectedContacts.append(newUser)
        } else {
            // Name + email: reuse the invite-by-email path (dedups by email).
            eventInviteViewModel.addInvitedUser(name: name, email: email)
        }
        eventInviteViewModel.searchUserText = ""
        focusedField = nil
        isShowCustomParticipantSheet = false
    }

    // Fetch a fresh invite token unless a still-valid one is already cached. A
    // 60s guard band avoids handing out a token that expires mid-share. Errors
    // surface via the global dialog (APIService.notifyError); the buttons stay
    // disabled while inviteToken is nil.
    private func fetchInviteTokenIfNeeded() async {
        if let expiresAt = inviteTokenExpiresAt, inviteToken != nil,
           expiresAt.timeIntervalSinceNow > 60 {
            return
        }
        guard let eventId = eventViewModel.selectedEvent?.eventId else { return }
        do {
            let response = try await EventService.shared.createInviteToken(eventId: eventId)
            inviteToken = response.token
            inviteTokenExpiresAt = Date(timeIntervalSince1970: TimeInterval(response.expires_at))
        } catch {
            print("Fetch invite token failed: \(error)")
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
