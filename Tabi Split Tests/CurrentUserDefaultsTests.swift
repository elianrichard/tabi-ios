//
//  CurrentUserDefaultsTests.swift
//  Tabi Split Tests
//
//  Created by Elian Richard on 10/09/26.
//

import XCTest
@testable import Tabi_Split

/// `isSameAccount` decides whether a login is a switch to a different account
/// (whose predecessor's local cache must be wiped) or a return to the same one.
final class CurrentUserDefaultsTests: XCTestCase {

    private func user(id: String, email: String, kind: String = "real") -> CurrentUserDefaults {
        CurrentUserDefaults(userName: "Name", userEmail: email, userImage: "owl", userId: id, kind: kind)
    }

    func testSameUserIdIsSameAccountEvenIfEmailDiffers() {
        XCTAssertTrue(CurrentUserDefaults.isSameAccount(
            user(id: "u1", email: "old@example.com"),
            user(id: "u1", email: "new@example.com")))
    }

    func testDifferentUserIdIsDifferentAccountEvenIfEmailMatches() {
        XCTAssertFalse(CurrentUserDefaults.isSameAccount(
            user(id: "u1", email: "a@example.com"),
            user(id: "u2", email: "a@example.com")))
    }

    func testTwoGuestsWithEmptyEmailsAreDifferentAccounts() {
        // Guests have a real userId but no email; a fresh guest is a new identity.
        XCTAssertFalse(CurrentUserDefaults.isSameAccount(
            user(id: "g1", email: "", kind: "guest"),
            user(id: "g2", email: "", kind: "guest")))
    }

    func testLegacyRecordWithoutUserIdFallsBackToEmail() {
        XCTAssertTrue(CurrentUserDefaults.isSameAccount(
            user(id: "", email: "a@example.com"),
            user(id: "u1", email: "a@example.com")))
        XCTAssertFalse(CurrentUserDefaults.isSameAccount(
            user(id: "", email: "a@example.com"),
            user(id: "u1", email: "b@example.com")))
    }

    func testNothingComparableIsDifferentAccount() {
        XCTAssertFalse(CurrentUserDefaults.isSameAccount(
            user(id: "", email: ""),
            user(id: "", email: "")))
    }
}
