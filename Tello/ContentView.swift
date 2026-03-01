// Purpose: Root navigation controller. Routes to onboarding or main app.

import SwiftUI

struct ContentView: View {

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("childName") private var childName = ""
    @EnvironmentObject var fontManager: FontManager
    @State private var navigationPath = NavigationPath()

    var body: some View {
        if hasCompletedOnboarding {
            NavigationStack(path: $navigationPath) {
                CameraView(navigationPath: $navigationPath)
                    .navigationDestination(for: String.self) { object in
                        LoadingView(detectedObject: object, childName: childName, navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                    }
                    .navigationDestination(for: StoryModel.self) { story in
                        StoryView(story: story, navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                    }
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
