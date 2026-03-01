// Purpose: App entry point. Injects shared FontManager as an environment object.

import SwiftUI

@main
struct TelloApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var fontManager = FontManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(fontManager)
        }
    }
}
