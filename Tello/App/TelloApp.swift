// Purpose: App entry point. Injects shared FontManager as an environment object.

import SwiftUI

@main
struct TelloApp: App {

    @StateObject private var fontManager = FontManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(fontManager)
        }
    }
}
