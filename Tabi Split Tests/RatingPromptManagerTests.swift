//
//  RatingPromptManagerTests.swift
//  Tabi Split Tests
//
//  Covers the App Store rating cadence: MIN_SUCCESSES = 3, COOLDOWN = 60 days,
//  MAX_LIFETIME_REQUESTS = 3. State lives in UserDefaults.standard, so each test
//  wipes the rating keys first; the clock is injected via the manager's `now`
//  seam so cooldown windows are deterministic.
//

import XCTest
@testable import Tabi_Split

@MainActor
final class RatingPromptManagerTests: XCTestCase {
    private let defaults = UserDefaultsService.shared
    private let epoch = Date(timeIntervalSince1970: 1_700_000_000)

    override func setUpWithError() throws {
        clearRatingKeys()
    }

    override func tearDownWithError() throws {
        clearRatingKeys()
    }

    private func clearRatingKeys() {
        defaults.deleteKeyValue(forKey: .ratingSuccessfulExpenseCount)
        defaults.deleteKeyValue(forKey: .ratingLastRequestedAt)
        defaults.deleteKeyValue(forKey: .ratingRequestCount)
    }

    private func makeManager(now: @escaping () -> Date) -> RatingPromptManager {
        RatingPromptManager(defaults: defaults, now: now)
    }

    // MARK: shouldRequestReview matrix

    func testDoesNotPromptBelowMinSuccesses() {
        let sut = makeManager(now: { self.epoch })
        defaults.setBasicValue(2, forKey: .ratingSuccessfulExpenseCount)
        XCTAssertFalse(sut.shouldRequestReview())
    }

    func testPromptsExactlyAtMinSuccesses() {
        let sut = makeManager(now: { self.epoch })
        defaults.setBasicValue(3, forKey: .ratingSuccessfulExpenseCount)
        XCTAssertTrue(sut.shouldRequestReview())
    }

    func testDoesNotPromptWithinCooldown() {
        let sut = makeManager(now: { self.epoch.addingTimeInterval(30 * 86_400) })
        defaults.setBasicValue(5, forKey: .ratingSuccessfulExpenseCount)
        defaults.setRatingLastRequestedAt(epoch) // 30 days ago < 60-day cooldown
        XCTAssertFalse(sut.shouldRequestReview())
    }

    func testPromptsAfterCooldown() {
        let sut = makeManager(now: { self.epoch.addingTimeInterval(61 * 86_400) })
        defaults.setBasicValue(5, forKey: .ratingSuccessfulExpenseCount)
        defaults.setRatingLastRequestedAt(epoch) // 61 days ago > 60-day cooldown
        XCTAssertTrue(sut.shouldRequestReview())
    }

    func testDoesNotPromptAtLifetimeCap() {
        let sut = makeManager(now: { self.epoch.addingTimeInterval(1000 * 86_400) })
        defaults.setBasicValue(50, forKey: .ratingSuccessfulExpenseCount)
        defaults.setBasicValue(3, forKey: .ratingRequestCount) // == MAX_LIFETIME_REQUESTS
        XCTAssertFalse(sut.shouldRequestReview())
    }

    // MARK: registerSuccessfulExpense side effects

    func testRegisterAlwaysCountsSuccessButDoesNotPromptEarly() {
        let sut = makeManager(now: { self.epoch })
        sut.registerSuccessfulExpense() // 1st success
        XCTAssertEqual(defaults.getRatingSuccessCount(), 1)
        XCTAssertFalse(sut.pendingReview)
        XCTAssertEqual(defaults.getRatingRequestCount(), 0)
    }

    func testRegisterFiresPromptAndRecordsAttemptAtThreshold() {
        let sut = makeManager(now: { self.epoch })
        defaults.setBasicValue(2, forKey: .ratingSuccessfulExpenseCount) // next one hits 3
        sut.registerSuccessfulExpense()

        XCTAssertEqual(defaults.getRatingSuccessCount(), 3)
        XCTAssertTrue(sut.pendingReview)
        XCTAssertEqual(defaults.getRatingRequestCount(), 1)
        XCTAssertEqual(defaults.getRatingLastRequestedAt(), epoch)
    }
}
