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
}
