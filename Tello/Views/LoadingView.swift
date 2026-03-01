// Purpose: Placeholder for the loading/story generation view.
// Full implementation in Stage 5.

import SwiftUI

struct LoadingView: View {

    let detectedObject: String
    let childName: String

    @EnvironmentObject var fontManager: FontManager

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color("AppBackground"),
                    Color("AppBackground").opacity(0.98)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Text("✨")
                    .font(.system(size: 64))

                Text("Got it!")
                    .font(fontManager.storyFontBold(size: 40))
                    .foregroundColor(Color("AppText"))

                Text("I spotted a \(detectedObject)!")
                    .font(fontManager.storyFont(size: 26))
                    .foregroundColor(Color("AppSecondaryText"))

                Text("Story generation coming in Stage 5!")
                    .font(fontManager.uiFont(size: 17))
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
