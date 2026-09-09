//
//  PushService.swift
//  Tabi Split
//
//  Registers this device for APNs and binds its token to the signed-in account
//  (PUT /device-token). The backend does the actual sending; the client only
//  needs to keep the token bound to the right user and route taps.
//

import Foundation
import UIKit
import UserNotifications

/// Where a tapped push lands. Mirrors the backend `notification.type` keys:
/// `event_completed` → optimization summary, `expense_*` → expense result,
/// everything else (invite/link/join/claim) → event detail.
enum PushTarget {
    case eventDetail(eventId: String)
    case expenseResult(eventId: String, expenseId: String)
    case settlementOptimization(eventId: String)

    init?(userInfo: [AnyHashable: Any]) {
        guard let eventId = userInfo["event_id"] as? String, !eventId.isEmpty else { return nil }
        let type = userInfo["type"] as? String ?? ""
        switch type {
        case "event_completed":
            self = .settlementOptimization(eventId: eventId)
        case "expense_assigned", "expense_payer":
            guard let expenseId = userInfo["expense_id"] as? String, !expenseId.isEmpty else {
                self = .eventDetail(eventId: eventId)
                return
            }
            self = .expenseResult(eventId: eventId, expenseId: expenseId)
        default:
            self = .eventDetail(eventId: eventId)
        }
    }
}

extension Notification.Name {
    /// Posted by PushAppDelegate when the user taps a push; object is a PushTarget.
    static let pushTapped = Notification.Name("TabiPushTapped")
}

final class PushService {
    static let shared = PushService()
    private let apiClient: APIClient = APIService.shared
    private static let tokenKey = "pushDeviceToken"

    private struct RegisterRequest: Encodable { let token: String }
    private struct MessageResponse: Codable { let message: String }

    /// Shows the system prompt once; on later calls iOS just re-issues the token,
    /// which re-uploads it bound to whoever is signed in now.
    func requestAuthorizationAndRegister() async {
        let granted = (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        guard granted else { return }
        await MainActor.run { UIApplication.shared.registerForRemoteNotifications() }
    }

    func uploadToken(_ hex: String) async {
        UserDefaults.standard.set(hex, forKey: Self.tokenKey)
        do {
            let _: MessageResponse = try await apiClient.put(
                endpoint: "/device-token", body: RegisterRequest(token: hex))
        } catch {
            print("Device token upload failed: \(error)")
        }
    }

    /// Best-effort; must run while the access token is still valid.
    func unregister() async {
        guard let hex = UserDefaults.standard.string(forKey: Self.tokenKey) else { return }
        do {
            let _: MessageResponse = try await apiClient.delete(endpoint: "/device-token/\(hex)")
        } catch {
            print("Device token unregister failed: \(error)")
        }
    }
}
