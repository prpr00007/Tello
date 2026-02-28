// Purpose: Placeholder for the loading/story generation view.
// Full implementation in Stage 5.

import SwiftUI

struct LoadingView: View {

    let detectedObject: String
    let childName: String

    @EnvironmentObject var fontManager: FontManager

    var body: some View {
        ZStack {
            Color("AppBackground").ignoresSafeArea()

            VStack(spacing: 24) {
                Text("✨ Got it!")
                    .font(fontManager.storyFontBold(size: 36))
                    .foregroundColor(Color("AppText"))

                Text("I spotted a \(detectedObject)!")
                    .font(fontManager.storyFont(size: 24))
                    .foregroundColor(Color("AppSecondaryText"))

                Text("Story generation coming in Stage 5!")
                    .font(fontManager.uiFont(size: 16))
                    .foregroundColor(Color("AppSecondaryText"))
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    LoadingView(detectedObject: "dog", childName: "Jake")
        .environmentObject(FontManager())
}
