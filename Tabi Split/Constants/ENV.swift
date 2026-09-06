//
//  ENV.swift
//  Tabi Split
//
//  Created by ahmad naufal alfakhar on 29/10/24.
//

import Foundation

enum ENV {
    /// Base API URL, injected per build configuration via the xcconfig
    /// BASE_URL -> Info.plist key. The Staging and Production schemes supply
    /// different values; see Config/Staging.xcconfig and Config/Production.xcconfig.
    static let BASE_API_URL: String = {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String,
              !value.isEmpty else {
            fatalError("BASE_URL missing from Info.plist — check the active scheme's xcconfig")
        }
        return value
    }()

    /// X-Api-Secret sent on every request, injected per build configuration via
    /// the xcconfig API_SECRET_KEY -> Info.plist key. Staging and Production can
    /// carry different secrets; see Config/Staging.xcconfig / Production.xcconfig.
    static let API_SECRET_KEY: String = {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "API_SECRET_KEY") as? String,
              !value.isEmpty else {
            fatalError("API_SECRET_KEY missing from Info.plist — check the active scheme's xcconfig")
        }
        return value
    }()

    /// HTTP header field name that carries API_SECRET_KEY, injected per build
    /// configuration via the xcconfig API_SECRET_HEADER -> Info.plist key.
    static let API_SECRET_HEADER: String = {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "API_SECRET_HEADER") as? String,
              !value.isEmpty else {
            fatalError("API_SECRET_HEADER missing from Info.plist — check the active scheme's xcconfig")
        }
        return value
    }()

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
}
