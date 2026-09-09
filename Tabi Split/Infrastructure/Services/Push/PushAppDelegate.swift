//
//  PushAppDelegate.swift
//  Tabi Split
//
//  The only reason an AppDelegate exists: APNs registration callbacks and
//  notification-center delegation are UIKit-only. Installed from TabiApp via
//  @UIApplicationDelegateAdaptor; everything else stays in SwiftUI.
//

import UIKit
import UserNotifications
import os

final class PushAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    private let log = Logger(subsystem: "com.sora.TabiSplit", category: "push")

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
        Task { await PushService.shared.uploadToken(hex) }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        log.error("APNs registration failed: \(error.localizedDescription)")
    }

    // Foreground: still show the banner; the tap handler below does the routing.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let target = PushTarget(userInfo: response.notification.request.content.userInfo) else {
            return
        }
        await MainActor.run {
            NotificationCenter.default.post(name: .pushTapped, object: target)
        }
    }
}
