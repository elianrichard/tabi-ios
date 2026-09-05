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
                            if !isLinkingByEmail {
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
                            guard !isLinkingByEmail else { return }
                            editParticipantViewModel.toggleImagePick = true
                        }

                    VStack(spacing: .spacingRegular) {
                        InputWithLabel(label: "Full Name",
                                       placeholder: "Full Name",
                                       text: $editParticipantViewModel.nameText,
                                       isDisabled: isLinkingByEmail,
                                       focusedField: $focusedField,
                                       focusCase: .field1)
                        InputWithLabel(label: "Email",
                                       isOptional: true,
                                       placeholder: "Link to a registered account",
                                       text: $editParticipantViewModel.emailText,
                                       errorMessage: isEmailInvalid ? "Enter a valid email address" : nil,
                                       showClearButton: true,
                                       focusedField: $focusedField,
                                       focusCase: .field2)
                        DialogBox(image: .dialogIcon,
                                  iconSize: 36,
                                  text: "Add an email to link this participant to a registered account.",
                                  isClosable: false)
                    }
                }
            }

            Spacer()

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
            CustomButton(text: "Remove Participant", type: .tertiary, customTextColor: .buttonRed) {
                isShowDeleteSheet = true
            }
        }
        .onAppear {
            if let participant = eventInviteViewModel.editingParticipant {
                editParticipantViewModel.populate(from: participant)
            }
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
