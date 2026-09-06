//
//  EditParticipantViewModel.swift
//  Tabi Split
//
//  Created by Elian Richard on 31/08/26.
//

import Foundation
import SwiftUI

@Observable
final class EditParticipantViewModel {
    var nameText: String = ""
    var emailText: String = ""

    var chosenImage: ProfileImageEnum = .owl
    var toggleImagePick: Bool = false
    // Sane non-zero default so the fitted image sheet isn't collapsed on first open
    // before its GeometryReader measures the real height.
    var contentHeight: CGFloat = 320

    var isApiCallLoading: Bool = false

    var profileImage: UIImage {
        UIImage(resource: chosenImage.resource)
    }

    func populate(from participant: UserData) {
        nameText = participant.name
        emailText = participant.email
        chosenImage = ProfileImageEnum(rawValue: participant.image) ?? .owl
    }

    // Removes the participant from the event via the backend, which rejects
    // removal if the participant is tied to any expense item (surfaced as an
    // error dialog). On success the participant is detached from the event's
    // local participant list. Returns false on failure.
    @MainActor
    func remove(participant: UserData, event: EventData?) async -> Bool {
        isApiCallLoading = true
        defer { isApiCallLoading = false }

        guard let eventId = event?.eventId else { return false }
        do {
            _ = try await EventService.shared.removeParticipant(eventId: eventId, participantId: participant.userId)
        } catch {
            print("Remove participant failed: \(error)")
            return false
        }

        event?.participants.removeAll { $0 === participant }
        SwiftDataService.shared.saveModelContext()
        return true
    }

    // Saves the edit via the backend, which validates the email (must be an
    // existing registered account not already in the event) and may swap the
    // dummy for that account; the returned participant is then applied locally.
    // Returns false on failure (the error dialog is shown by APIService).
    @MainActor
    func save(participant: UserData, event: EventData?) async -> Bool {
        let trimmedName = nameText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = emailText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedName.isEmpty else { return false }

        isApiCallLoading = true
        defer { isApiCallLoading = false }

        guard let eventId = event?.eventId else { return false }

        do {
            let response = try await EventService.shared.editParticipant(
                eventId: eventId,
                participantId: participant.userId,
                name: trimmedName,
                avatar: chosenImage.rawValue,
                email: trimmedEmail.isEmpty ? nil : trimmedEmail
            )
            // Apply the backend's authoritative participant back onto the row so the
            // UI reflects a swap (new userId/email/avatar) or an in-place edit.
            applyUpdated(response.participant, to: participant)
            SwiftDataService.shared.saveModelContext()
        } catch {
            print("Edit participant failed: \(error)")
            return false
        }
        return true
    }

    // Unlinks a participant from its real/guest account: the backend converts the
    // linked account into a fresh placeholder (dummy) that keeps this event slot
    // but detaches the account, so the creator can then edit or invite it. Reuses
    // the edit-participant endpoint with no email (its "convert to placeholder"
    // path). Returns false on failure (error dialog shown by APIService).
    @MainActor
    func unlink(participant: UserData, event: EventData?) async -> Bool {
        isApiCallLoading = true
        defer { isApiCallLoading = false }

        guard let eventId = event?.eventId else { return false }
        let name = participant.name.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let response = try await EventService.shared.editParticipant(
                eventId: eventId,
                participantId: participant.userId,
                name: name.isEmpty ? participant.name : name,
                avatar: (ProfileImageEnum(rawValue: participant.image) ?? .owl).rawValue,
                email: nil
            )
            applyUpdated(response.participant, to: participant)
            SwiftDataService.shared.saveModelContext()
            // Reflect the now-unlinked state in the edit fields.
            populate(from: participant)
        } catch {
            print("Unlink participant failed: \(error)")
            return false
        }
        return true
    }

    // Applies the backend's authoritative participant back onto the local row so
    // the UI reflects a swap (new userId/email/avatar/kind) or an in-place edit.
    private func applyUpdated(_ updated: UserBase, to participant: UserData) {
        participant.userId = updated.user_id
        participant.name = updated.name
        participant.email = updated.email ?? ""
        participant.kind = updated.kind ?? "dummy"
        if let image = ProfileImageEnum(rawValue: updated.avatar_url) {
            participant.image = image.id
            participant.imageUrl = nil
        } else {
            participant.imageUrl = updated.avatar_url
        }
    }
}
