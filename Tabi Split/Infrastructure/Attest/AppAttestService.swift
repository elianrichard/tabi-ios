//
//  AppAttestService.swift
//  Tabi Split
//
//  Wraps Apple App Attest (DCAppAttestService): one-time device enrollment plus
//  a per-request assertion the backend verifies. Assertion generation is
//  serialized on an actor so the device never emits two assertions with a
//  racing sign counter (the server enforces a strictly-increasing counter).
//
//  App Attest is unavailable on the Simulator; there `isSupported` is false and
//  the header/enroll calls no-op, so debug builds fall back to the server's
//  X-Api-Secret dev bypass / kill-switch.
//

import Foundation
import CryptoKit
import DeviceCheck
import os.log

/// Header names the backend's App Attest middleware reads.
enum AppAttestHeader {
    static let keyID = "X-App-Attest-KeyId"
    static let assertion = "X-App-Attest-Assertion"
    static let challenge = "X-App-Attest-Challenge"
}

actor AppAttestService {
    static let shared = AppAttestService()

    private let service = DCAppAttestService.shared
    private let keychain: KeychainStoring
    private let baseURL: String
    private let session: URLSession

    /// Keychain account under which the attested keyId (base64) is stored.
    private static let keyIDStorageKey = "appAttestKeyId"

    private init(
        keychain: KeychainStoring = KeychainService.shared,
        baseURL: String = ENV.BASE_API_URL
    ) {
        self.keychain = keychain
        self.baseURL = baseURL
        // A plain session for the open /attest/* routes — deliberately NOT the
        // shared APIService, to avoid recursing into assertion injection.
        self.session = URLSession(configuration: .default)
    }

    /// True on real hardware that supports App Attest. False on Simulator.
    nonisolated var isSupported: Bool {
        DCAppAttestService.shared.isSupported
    }

    // MARK: - Enrollment

    /// Ensures this device has an attested key registered with the backend.
    /// Idempotent and safe to call at launch: it no-ops if unsupported or if a
    /// keyId is already stored.
    func enrollIfNeeded() async {
        guard isSupported else { return }
        if (try? storedKeyID()) != nil { return }
        do {
            try await enroll()
        } catch {
            os_log(.error, log: .attest, "App Attest enrollment failed: %{public}@", String(describing: error))
        }
    }

    private func enroll() async throws {
        let keyID = try await service.generateKey()

        let challenge = try await fetchChallenge()
        guard let challengeData = Data(base64Encoded: challenge) else {
            throw AppAttestError.invalidChallenge
        }

        // Attestation clientDataHash = SHA256(challengeBytes).
        let clientDataHash = Data(SHA256.hash(data: challengeData))
        let attestation = try await service.attestKey(keyID, clientDataHash: clientDataHash)

        try await postAttestation(keyID: keyID, attestation: attestation, challenge: challenge)
        try keychain.save(Data(keyID.utf8), forKey: Self.keyIDStorageKey)
    }

    // MARK: - Per-request assertion

    /// Builds the App Attest headers for a request with the given raw body bytes.
    /// Returns an empty dictionary when App Attest is unavailable (Simulator) or
    /// the device is not yet enrolled — callers then rely on the server's bypass.
    ///
    /// clientDataHash = SHA256(challengeBytes || SHA256(bodyData)), matching the
    /// server's `SHA256(challengeBytes || SHA256(requestBody))`.
    func assertionHeaders(for bodyData: Data) async -> [String: String] {
        guard isSupported else { return [:] }
        guard let keyID = try? storedKeyID() else { return [:] }
        do {
            let challenge = try await fetchChallenge()
            guard let challengeData = Data(base64Encoded: challenge) else {
                throw AppAttestError.invalidChallenge
            }

            let bodyHash = Data(SHA256.hash(data: bodyData))
            let clientDataHash = Data(SHA256.hash(data: challengeData + bodyHash))

            let assertion = try await service.generateAssertion(keyID, clientDataHash: clientDataHash)
            return [
                AppAttestHeader.keyID: keyID,
                AppAttestHeader.assertion: assertion.base64EncodedString(),
                AppAttestHeader.challenge: challenge,
            ]
        } catch {
            os_log(.error, log: .attest, "App Attest assertion failed: %{public}@", String(describing: error))
            return [:]
        }
    }

    // MARK: - Storage

    private func storedKeyID() throws -> String {
        let data = try keychain.load(forKey: Self.keyIDStorageKey)
        guard let keyID = String(data: data, encoding: .utf8) else {
            throw AppAttestError.invalidStoredKey
        }
        return keyID
    }

    // MARK: - /attest/* transport (open routes)

    private func fetchChallenge() async throws -> String {
        var request = URLRequest(url: URL(string: baseURL + "/attest/challenge")!)
        request.httpMethod = "POST"
        let (data, response) = try await session.data(for: request)
        try Self.ensureOK(response)
        let decoded = try JSONDecoder().decode(ChallengeResponse.self, from: data)
        return decoded.challenge
    }

    private func postAttestation(keyID: String, attestation: Data, challenge: String) async throws {
        var request = URLRequest(url: URL(string: baseURL + "/attest/verify")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = VerifyRequest(
            keyId: keyID,
            attestation: attestation.base64EncodedString(),
            challenge: challenge
        )
        request.httpBody = try JSONEncoder().encode(body)
        let (_, response) = try await session.data(for: request)
        try Self.ensureOK(response)
    }

    private static func ensureOK(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw AppAttestError.serverRejected
        }
    }

    private struct ChallengeResponse: Decodable {
        let challenge: String
    }

    private struct VerifyRequest: Encodable {
        let keyId: String
        let attestation: String
        let challenge: String

        enum CodingKeys: String, CodingKey {
            case keyId = "key_id"
            case attestation
            case challenge
        }
    }
}

enum AppAttestError: Error {
    case invalidChallenge
    case invalidStoredKey
    case serverRejected
}

private extension OSLog {
    static let attest = OSLog(subsystem: "com.tabisplit.TabiSplit", category: "AppAttest")
}
