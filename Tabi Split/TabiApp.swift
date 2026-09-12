//
//  TabiApp.swift
//  Tabi
//
//  Created by Elian Richard on 19/09/24.
//

import SwiftUI
import SwiftData

@main
struct TabiApp: App {
    @UIApplicationDelegateAdaptor(PushAppDelegate.self) private var pushDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // One container for the whole app. SwiftDataService owns it and opens it
        // through TabiSchema.loadOrRecover(), which never fatalErrors on a store
        // that failed to migrate (it is moved aside and rebuilt from the server).
        .modelContainer(SwiftDataService.shared.modelContainer)
    }
}
