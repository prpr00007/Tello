// Purpose: Root navigation controller. Routes to onboarding or main app.

import SwiftUI

struct ContentView: View {

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @EnvironmentObject var fontManager: FontManager

    var body: some View {
        if hasCompletedOnboarding {
            NavigationStack {
                CameraView()
            }
        } else {
            OnboardingView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(FontManager())
}
