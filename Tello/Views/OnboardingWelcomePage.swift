// Purpose: First onboarding page. Welcomes the child with an animated logo
// and introduces the app concept in simple, friendly language.

import SwiftUI

struct OnboardingWelcomePage: View {

    @Binding var currentPage: Int
    @EnvironmentObject var fontManager: FontManager

    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: CGFloat = 0
    @State private var titleOpacity: CGFloat = 0
    @State private var taglineOpacity: CGFloat = 0
    @State private var buttonOpacity: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {

            Spacer()

            // MARK: - Content (centred, max width 700pt)
            VStack(spacing: 32) {

                // Logo / Icon
                ZStack {
                    Circle()
                        .fill(Color("AppPrimary").opacity(0.12))
                        .frame(width: 160, height: 160)

                    Text("📖")
                        .font(.system(size: 80))
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                // App Name + Tagline
                VStack(spacing: 12) {
                    Text("Tello")
                        .font(fontManager.storyFontBold(size: 52))
                        .foregroundColor(Color("AppText"))
                        .opacity(titleOpacity)

                    Text("Point at anything.\nWatch it become a story just for you! ✨")
                        .font(fontManager.storyFont(size: 22))
                        .foregroundColor(Color("AppSecondaryText"))
                        .multilineTextAlignment(.center)
                        .opacity(taglineOpacity)
                }

                // CTA Button
                PrimaryButton(label: "Let's Get Started!", icon: "arrow.right") {
                    withAnimation {
                        currentPage = 1
                    }
                }
                .frame(maxWidth: 400)
                .opacity(buttonOpacity)
            }
            .frame(maxWidth: 700)
            .padding(.horizontal, 40)

            Spacer()
            // Space for page indicator at bottom
            Color.clear.frame(height: 60)
        }
        .onAppear {
            // Staggered entrance animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                titleOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
                taglineOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
                buttonOpacity = 1.0
            }
        }
    }
}

#Preview {
    OnboardingWelcomePage(currentPage: .constant(0))
        .environmentObject(FontManager())
        .background(Color("AppBackground"))
}
