// Purpose: Placeholder for the camera view. Full implementation in Stage 3.

import SwiftUI

struct CameraView: View {

    @EnvironmentObject var fontManager: FontManager
    @AppStorage("childName") private var childName = ""

    var body: some View {
        ZStack {
            Color("AppBackground").ignoresSafeArea()

            VStack(spacing: 24) {
                Text("👋 Welcome, \(childName)!")
                    .font(fontManager.storyFontBold(size: 36))
                    .foregroundColor(Color("AppText"))

                Text("Camera coming in Stage 3!")
                    .font(fontManager.storyFont(size: 22))
                    .foregroundColor(Color("AppSecondaryText"))

                // Reset onboarding button (for testing only — remove in Stage 3)
                Button("Reset Onboarding (Test)") {
                    UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                    UserDefaults.standard.set("", forKey: "childName")
                    UserDefaults.standard.set("English", forKey: "homeLanguage")
                }
                .font(fontManager.uiFont(size: 16))
                .foregroundColor(Color("AppSecondaryText"))
                .padding(.top, 40)
            }
        }
    }
}

#Preview {
    CameraView()
        .environmentObject(FontManager())
}
