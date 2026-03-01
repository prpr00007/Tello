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

            VStack(spacing: 40) {

                // Logo — minimal icon
                ZStack {
                    Circle()
                        .fill(Color("AppPrimary").opacity(0.12))
                        .frame(width: 120, height: 120)

                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(Color("AppPrimary"))
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                VStack(spacing: 16) {
                    Text("Tello")
                        .font(fontManager.storyFontBold(size: 52))
                        .foregroundColor(Color("AppText"))
                        .opacity(titleOpacity)

                    Text("Point at anything.\nWatch it become a story just for you.")
                        .font(fontManager.storyFont(size: 22))
                        .foregroundColor(Color("AppSecondaryText"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .opacity(taglineOpacity)
                }

                PrimaryButton(label: "Get Started", icon: "arrow.right") {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        currentPage = 1
                    }
                }
                .frame(maxWidth: 400)
                .opacity(buttonOpacity)
            }
            .frame(maxWidth: 700)
            .padding(.horizontal, 48)

            Spacer()
            Color.clear.frame(height: 72)
        }
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.72).delay(0.1)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.55).delay(0.4)) {
                titleOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.55).delay(0.65)) {
                taglineOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.55).delay(0.9)) {
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
