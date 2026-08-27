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
}
