//
//  EditParticipantView.swift
//  Tabi Split
//
//  Created by Elian Richard on 31/08/26.
//

import SwiftUI
import Lottie

struct EditParticipantView: View {
    @Environment(Router.self) private var router
    @Environment(EventViewModel.self) private var eventViewModel
    @Environment(EventInviteViewModel.self) private var eventInviteViewModel
    @Environment(ProfileViewModel.self) private var profileViewModel

    @State private var editParticipantViewModel = EditParticipantViewModel()
    @State private var isShowDeleteSheet = false
    @FocusState private var focusedField: FocusField?

    // Single-use participant-claim invite token (1h TTL). Fetched when the view
    // appears for a claimable (email-less dummy) participant; reused by the
    // Copy / Share / QR buttons. nil until the first fetch resolves.
    @State private var inviteToken: String?
    @State private var inviteTokenExpiresAt: Date?

    // Claim watch: after the owner shares the link, poll every few seconds for
    // someone claiming this participant, then update in place and toast.
    @State private var claimPollTask: Task<Void, Never>?
    @State private var isWatchingForClaim = false
    @State private var claimToastMessage: String?
    private let claimPollInterval: UInt64 = 5_000_000_000 // 5s in nanoseconds

    // A linked participant already owns an account (real or guest). Its name/email
    // are controlled by that account, so both fields are disabled and the creator
    // must Unlink before editing or inviting.
    private var isLinked: Bool {
        eventInviteViewModel.editingParticipant?.isLinked == true
    }

    // Only an unlinked (dummy) participant with no locally-typed email can be
    // invited to claim. Linking-by-email (typing an email) is the manual path, so
    // the invite row hides then too.
    private var isParticipantClaimable: Bool {
        !isLinked && !isLinkingByEmail
    }

    private var inviteURLString: String? {
        guard let token = inviteToken else { return nil }
        return "https://\(ENV.DEEPLINK_HOST)/join?token=\(token)"
    }

    private var inviteIntro: String {
        let eventName = eventViewModel.selectedEvent?.eventName ?? ""
        return eventName.isEmpty
            ? "Join my event on Tabi so we can split the bills easily 💸"
            : "Join “\(eventName)” on Tabi so we can split the bills easily 💸"
    }

    private var inviteMessage: String? {
        guard let urlString = inviteURLString else { return nil }
        return "\(inviteIntro)\n\nTap to join: \(urlString)"
    }

    // When an email is entered the participant will be linked to that registered
    // account, whose own name/avatar take over — so editing name/image here is
    // irrelevant and gets disabled.
    private var isLinkingByEmail: Bool {
        !editParticipantViewModel.emailText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // A non-empty email that isn't a valid address blocks saving and shows an error.
    private var isEmailInvalid: Bool {
        isLinkingByEmail && !editParticipantViewModel.emailText.isValidEmail
    }

    var body: some View {
        VStack {
            TopNavigation(title: "Edit Participant")

            VStack(spacing: .spacingLarge) {
                VStack(spacing: .spacingTight) {
                    Image(uiImage: editParticipantViewModel.profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 90, height: 90)
                        .clipShape(Circle())
                        .overlay {
                            if !isLinkingByEmail && !isLinked {
                                VStack {
                                    Circle()
                                        .stroke(.bgWhite, lineWidth: 4)
                                        .fill(.buttonBlue)
                                        .frame(width: 28, height: 28)
                                        .overlay {
                                            Icon(systemName: "pencil", color: .bgWhite, size: 14)
                                        }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                            }
                        }
                        .onTapGesture {
                            guard !isLinkingByEmail && !isLinked else { return }
                            editParticipantViewModel.toggleImagePick = true
                        }

                    VStack(spacing: .spacingRegular) {
                        InputWithLabel(label: "Full Name",
                                       placeholder: "Full Name",
                                       text: $editParticipantViewModel.nameText,
                                       isDisabled: isLinkingByEmail || isLinked,
                                       focusedField: $focusedField,
                                       focusCase: .field1)
                        InputWithLabel(label: "Email",
                                       isOptional: true,
                                       placeholder: "Link to a registered account",
                                       text: $editParticipantViewModel.emailText,
                                       errorMessage: isEmailInvalid ? "Enter a valid email address" : nil,
                                       isDisabled: isLinked,
                                       showClearButton: !isLinked,
                                       focusedField: $focusedField,
                                       focusCase: .field2)
                        DialogBox(image: .dialogIcon,
                                  iconSize: 36,
                                  text: isLinked
                                      ? "This participant is linked to an account. Unlink it first to edit their details or invite someone else."
                                      : "Add an email to link this participant to a registered account.",
                                  isClosable: false)
                    }

                    // Invite the person to claim this participant themselves. Only
                    // shown for an unlinked (dummy) participant that isn't being
                    // manually linked by email.
                    if isParticipantClaimable {
                        VStack(spacing: .spacingTight) {
                            Text("Or invite them to claim this participant")
                                .font(.tabiBody)
                                .foregroundStyle(.textGrey)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            InviteShareButtons(urlString: inviteURLString,
                                               copyMessage: inviteMessage,
                                               shareIntro: inviteIntro,
                                               onShareAction: { startWatchingForClaim() })
                            if isWatchingForClaim {
                                HStack(spacing: .spacingXSmall) {
                                    ProgressView().scaleEffect(0.8)
                                    Text("Waiting for someone to open the link…")
                                        .font(.tabiBody2)
                                        .foregroundStyle(.textGrey)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
            }

            Spacer()

            if isLinked {
                // Linked: the account controls its own details — the only edit
                // action is to unlink, which converts it back to a placeholder.
                // Stay on this screen afterward so the creator can then edit or
                // invite, and fetch a fresh claim token now that it's claimable.
                CustomButton(text: editParticipantViewModel.isApiCallLoading ? "Loading..." : "Unlink Account") {
                    guard let participant = eventInviteViewModel.editingParticipant else { return }
                    Task {
                        if await editParticipantViewModel.unlink(participant: participant,
                                                                 event: eventViewModel.selectedEvent) {
                            await fetchInviteTokenIfNeeded()
                        }
                    }
                }
            } else {
                CustomButton(text: editParticipantViewModel.isApiCallLoading ? "Loading..." : "Save",
                             isEnabled: !editParticipantViewModel.isApiCallLoading && !editParticipantViewModel.nameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isEmailInvalid) {
                    guard let participant = eventInviteViewModel.editingParticipant else { return }
                    Task {
                        if await editParticipantViewModel.save(participant: participant,
                                                               event: eventViewModel.selectedEvent) {
                            router.pop()
                        }
                    }
                }
            }
            CustomButton(text: "Remove Participant", type: .tertiary, customTextColor: .buttonRed) {
                isShowDeleteSheet = true
            }
        }
        .onAppear {
            if let participant = eventInviteViewModel.editingParticipant {
                editParticipantViewModel.populate(from: participant)
            }
            Task { await fetchInviteTokenIfNeeded() }
        }
        .sheet(isPresented: $editParticipantViewModel.toggleImagePick) {
            ParticipantImageSheet(chosenImage: $editParticipantViewModel.chosenImage,
                                  isPresented: $editParticipantViewModel.toggleImagePick,
                                  contentHeight: $editParticipantViewModel.contentHeight)
                .presentationDetents([.height(editParticipantViewModel.contentHeight)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowDeleteSheet) {
            CustomSheet(xToggleBinding: $isShowDeleteSheet) {
                VStack(spacing: 0) {
                    LottieView(animation: .named("DeleteEvent"))
                        .looping()
                        .scaleEffect(1.4)
                        .frame(width: 300, height: 200)
                    VStack(spacing: .spacingSmall) {
                        Text("Remove this participant?")
                            .font(.tabiSubtitle)
                            .multilineTextAlignment(.center)
                        Text("They will be removed from this event. This can't be undone.")
                            .font(.tabiBody)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxHeight: .infinity)
                HStack {
                    CustomButton(text: "Cancel", type: .secondary) {
                        isShowDeleteSheet = false
                    }
                    CustomButton(text: editParticipantViewModel.isApiCallLoading ? "Loading..." : "Remove", customBackgroundColor: .buttonRed) {
                        guard let participant = eventInviteViewModel.editingParticipant else { return }
                        // Dismiss the confirm sheet first so a failure (e.g. the
                        // participant is still linked to an expense) surfaces its
                        // error dialog cleanly instead of behind this sheet.
                        isShowDeleteSheet = false
                        Task {
                            if await editParticipantViewModel.remove(participant: participant,
                                                                     event: eventViewModel.selectedEvent) {
                                eventInviteViewModel.selectedContacts.removeAll { $0 === participant }
                                router.pop()
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .addBackgroundColor(.bgWhite) {
            focusedField = nil
        }
        .onDisappear {
            claimPollTask?.cancel()
            claimPollTask = nil
        }
        .overlay(alignment: .bottom) {
            if let message = claimToastMessage {
                Text(message)
                    .font(.tabiBody)
                    .foregroundStyle(.textWhite)
                    .padding(.horizontal, .spacingRegular)
                    .padding(.vertical, .spacingSmall)
                    .background(.buttonBlue)
                    .clipShape(RoundedRectangle(cornerRadius: .radiusMedium))
                    .padding(.bottom, .spacingLarge)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // Begin watching for a claim once the owner has shared the link. Idempotent —
    // repeated share taps don't spawn extra pollers. Only meaningful while the
    // participant is still a claimable (unlinked) dummy.
    private func startWatchingForClaim() {
        guard isParticipantClaimable, claimPollTask == nil else { return }
        guard let eventId = eventViewModel.selectedEvent?.eventId,
              let participant = eventInviteViewModel.editingParticipant else { return }
        let participantId = participant.userId
        isWatchingForClaim = true
        claimPollTask = Task {
            await pollForClaim(eventId: eventId, participantId: participantId)
        }
    }

    // Polls the claim-status endpoint every few seconds until the participant is
    // claimed, the task is cancelled (leaving the screen), or an error occurs.
    private func pollForClaim(eventId: String, participantId: String) async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: claimPollInterval)
            if Task.isCancelled { return }
            do {
                let status = try await EventService.shared.participantClaimStatus(
                    eventId: eventId, participantId: participantId)
                if status.claimed {
                    await handleClaimDetected(newParticipant: status.participant)
                    return
                }
            } catch {
                // Transient/permission error — stop watching quietly; the owner can
                // reopen or re-share to try again.
                print("Claim poll failed: \(error)")
                await MainActor.run { stopWatchingForClaim() }
                return
            }
        }
    }

    @MainActor
    private func handleClaimDetected(newParticipant: UserBase?) async {
        stopWatchingForClaim()

        // Apply the claimer onto the local participant row so the view flips to the
        // linked/disabled state without re-fetching.
        if let newParticipant, let participant = eventInviteViewModel.editingParticipant {
            participant.userId = newParticipant.user_id
            participant.name = newParticipant.name
            participant.email = newParticipant.email ?? ""
            participant.kind = newParticipant.kind ?? "real"
            if let image = ProfileImageEnum(rawValue: newParticipant.avatar_url) {
                participant.image = image.id
                participant.imageUrl = nil
            } else {
                participant.imageUrl = newParticipant.avatar_url
            }
            editParticipantViewModel.populate(from: participant)
        }

        // Refresh the whole event list (same as Home on appear) so the participant
        // list everywhere reflects the swap, avoiding a stale-list surprise.
        _ = await HomeViewModel().refreshEventData(
            currentUser: profileViewModel.user,
            isShowLoading: .constant(false))
        SwiftDataService.shared.saveModelContext()

        let claimerName = newParticipant?.name ?? "Someone"
        showClaimToast("\(claimerName) joined and claimed this participant")
    }

    private func stopWatchingForClaim() {
        claimPollTask?.cancel()
        claimPollTask = nil
        isWatchingForClaim = false
    }

    @MainActor
    private func showClaimToast(_ message: String) {
        withAnimation { claimToastMessage = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { claimToastMessage = nil }
        }
    }

    // Fetch a fresh participant-claim token unless a still-valid one is cached. A
    // 60s guard band avoids handing out a token that expires mid-share. Only runs
    // for a claimable participant; errors surface via the global dialog, and the
    // share buttons stay inert while inviteToken is nil.
    private func fetchInviteTokenIfNeeded() async {
        guard isParticipantClaimable else { return }
        if let expiresAt = inviteTokenExpiresAt, inviteToken != nil,
           expiresAt.timeIntervalSinceNow > 60 {
            return
        }
        guard let eventId = eventViewModel.selectedEvent?.eventId,
              let participant = eventInviteViewModel.editingParticipant else { return }
        do {
            let response = try await EventService.shared.createParticipantInviteToken(
                eventId: eventId, participantId: participant.userId)
            inviteToken = response.token
            inviteTokenExpiresAt = Date(timeIntervalSince1970: TimeInterval(response.expires_at))
        } catch {
            print("Fetch participant invite token failed: \(error)")
        }
    }
}

// Template-avatar picker for a participant. Mirrors ProfileImageSheet's grid but is
// self-contained (binds a ProfileImageEnum) so it isn't coupled to the profile flow.
private struct ParticipantImageSheet: View {
    @Binding var chosenImage: ProfileImageEnum
    @Binding var isPresented: Bool
    @Binding var contentHeight: CGFloat
    @State private var pendingImage: ProfileImageEnum = .owl

    var body: some View {
        CustomSheet(xToggleBinding: $isPresented) {
            VStack(alignment: .leading, spacing: .spacingMedium) {
                Text("Select Image")
                    .font(.tabiTitle)
                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 4), spacing: .spacingTight) {
                    ForEach(ProfileImageEnum.allCases) { image in
                        Button {
                            pendingImage = image
                        } label: {
                            Circle()
                                .fill(.uiGray)
                                .overlay {
                                    Image(image.resource)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .clipShape(Circle())
                                }
                                .padding(6)
                                .frame(width: 84, height: 84)
                                .background {
                                    if pendingImage == image {
                                        Circle()
                                            .stroke(.buttonBlue, lineWidth: 4)
                                    }
                                }
                        }
                    }
                }
                CustomButton(text: "Done") {
                    chosenImage = pendingImage
                    isPresented = false
                }
            }
        }
        .onAppear {
            pendingImage = chosenImage
        }
        // Fit the sheet detent to its content height, matching ProfileImageSheet.
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        contentHeight = geometry.size.height
                    }
            }
        )
    }
}

#Preview {
    EditParticipantView()
        .environment(Router())
        .environment(EventViewModel())
        .environment(EventInviteViewModel())
        .environment(ProfileViewModel())
}
