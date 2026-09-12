//
//  ENV.swift
//  Tabi Split
//
//  Created by ahmad naufal alfakhar on 29/10/24.
//

import Foundation
import os

enum ENV {
    /// Base API URL, injected per build configuration via the xcconfig
    /// BASE_URL -> Info.plist key. The Staging and Production schemes supply
    /// different values; see Config/Staging.xcconfig and Config/Production.xcconfig.
    static let BASE_API_URL: String = requiredInfoPlistValue("BASE_URL")

    /// X-Api-Secret sent on every request, injected per build configuration via
    /// the xcconfig API_SECRET_KEY -> Info.plist key. Production reads it from the
    /// gitignored Config/Secrets.xcconfig (see Secrets.xcconfig.example).
    static let API_SECRET_KEY: String = requiredInfoPlistValue("API_SECRET_KEY")

    /// HTTP header field name that carries API_SECRET_KEY, injected per build
    /// configuration via the xcconfig API_SECRET_HEADER -> Info.plist key.
    static let API_SECRET_HEADER: String = requiredInfoPlistValue("API_SECRET_HEADER")

    /// App bundle identifier. Fixed per app; used for the OSLog subsystem and as
    /// the Keychain service name. Falls back to the running bundle's id.
    static let APP_BUNDLE_ID = Bundle.main.bundleIdentifier ?? "com.tabisplit.TabiSplit"

    /// Universal Link host for invite/join deeplinks (https://<host>/join?token=...).
    /// Fixed across build configurations — it must match the app's associated-domains
    /// entitlement and the parser in ContentView — so it is a plain constant rather
    /// than an xcconfig-injected value.
    static let DEEPLINK_HOST = "tabisplit.my.id"

    /// Custom URL scheme for deeplinks (tabisplit://join?token=...). Fixed across
    /// build configurations — must match the app's CFBundleURLSchemes and the parser
    /// in ContentView.
    static let DEEPLINK_SCHEME = "tabisplit"

    /// Feature flag: refine the on-device receipt OCR with the backend AI parser
    /// (custom split + attached image, on Next). When false, the heuristic OCR
    /// result is used as-is and no /receipt/parse call is made. Toggle here to
    /// enable/disable without touching the flow.
    static let RECEIPT_AI_REFINE_ENABLED = true

    /// A missing build setting is a packaging mistake, and the "Check required build
    /// settings" phase in project.yml fails the build for it. If one still slips
    /// through, degrade to an empty value (requests fail → "session expired") rather
    /// than crashing every user at launch; Debug builds still stop immediately.
    private static func requiredInfoPlistValue(_ key: String) -> String {
        let value = Bundle.main.object(forInfoDictionaryKey: key) as? String ?? ""
        if value.isEmpty {
            Logger(subsystem: APP_BUNDLE_ID, category: "config")
                .fault("\(key, privacy: .public) missing from Info.plist — check the active scheme's xcconfig")
            assertionFailure("\(key) missing from Info.plist — check the active scheme's xcconfig")
        }
        return value
    }
}
