// Purpose: Root navigation controller. Routes to onboarding or main app
// depending on whether the user has completed onboarding before.

import SwiftUI

struct ContentView: View {

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @EnvironmentObject var fontManager: FontManager

    var body: some View {
        if hasCompletedOnboarding {
            CameraView()
        } else {
            OnboardingView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(FontManager())
}
