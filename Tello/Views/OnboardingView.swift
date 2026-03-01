// Purpose: Container for the 4-page onboarding flow.
// Manages page state and handles navigation to the main app on completion.

import SwiftUI

struct OnboardingView: View {

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @EnvironmentObject var fontManager: FontManager
    @State private var currentPage = 0

    var body: some View {
        ZStack(alignment: .top) {

            // MARK: - Background (light green to mint cream)
            LinearGradient(
                colors: [
                    Color(hex: "#C8E6C9"),
                    Color(hex: "#F4F9F0")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // MARK: - Page Content
            TabView(selection: $currentPage) {
                OnboardingWelcomePage(currentPage: $currentPage)
                    .tag(0)
                OnboardingNamePage(currentPage: $currentPage)
                    .tag(1)
                OnboardingLanguagePage(currentPage: $currentPage)
                    .tag(2)
                OnboardingAccessibilityPage {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        hasCompletedOnboarding = true
                    }
                }
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.35), value: currentPage)

            // MARK: - Page Indicator Dots (bottom)
            VStack {
                Spacer()
                PageIndicatorView(totalPages: 4, currentPage: currentPage)
                    .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Page Indicator
struct PageIndicatorView: View {

    let totalPages: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: 14) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Color("AppPrimary") : Color("AppSecondaryText").opacity(0.4))
                    .frame(
                        width: index == currentPage ? 28 : 10,
                        height: 10
                    )
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(FontManager())
}
