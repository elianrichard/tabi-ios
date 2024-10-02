//
//  ContentView.swift
//  Tabi
//
//  Created by Elian Richard on 19/09/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
//        VStack {
//            Text("ContentView")
//        }
        SwiftDataTestingView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: EventData.self, inMemory: true)
}
