//
//  RatingPromptUserDefaults.swift
//  Tabi Split
//
//  Cadence state for the App Store rating prompt. Device-lifetime: unlike the
//  receipt-scan disclaimer, these keys are intentionally NOT reset on login — a
//  user who was already prompted shouldn't restart after re-login or a
//  guest→account upgrade. (No reset method here on purpose.)
//

import Foundation

extension UserDefaultsService {
    // Cumulative successful expense *creates* (edits are not counted).
    func getRatingSuccessCount() -> Int {
        (getBasicValue(forKey: .ratingSuccessfulExpenseCount) as? Int) ?? 0
    }

    func incrementRatingSuccessCount() {
        setBasicValue(getRatingSuccessCount() + 1, forKey: .ratingSuccessfulExpenseCount)
    }

    // When we last called the native requestReview.
    func getRatingLastRequestedAt() -> Date? {
        getBasicValue(forKey: .ratingLastRequestedAt) as? Date
    }

    func setRatingLastRequestedAt(_ date: Date) {
        setBasicValue(date, forKey: .ratingLastRequestedAt)
    }

    // How many times we've called requestReview (lifetime).
    func getRatingRequestCount() -> Int {
        (getBasicValue(forKey: .ratingRequestCount) as? Int) ?? 0
    }

    func incrementRatingRequestCount() {
        setBasicValue(getRatingRequestCount() + 1, forKey: .ratingRequestCount)
    }
}
