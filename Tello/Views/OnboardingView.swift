// Purpose: Container for the 3-page onboarding flow.
// Manages page state and handles navigation to the main app on completion.

import SwiftUI

struct OnboardingView: View {

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @EnvironmentObject var fontManager: FontManager
    @State private var currentPage = 0

    var body: some View {
        ZStack(alignment: .top) {

            // MARK: - Background
            Color("AppBackground").ignoresSafeArea()

            // MARK: - Page Content
            TabView(selection: $currentPage) {
                OnboardingWelcomePage(currentPage: $currentPage)
                    .tag(0)
                OnboardingNamePage(currentPage: $currentPage)
                    .tag(1)
                OnboardingLanguagePage {
                    // Called when user completes onboarding
                    withAnimation(.easeInOut(duration: 0.4)) {
                        hasCompletedOnboarding = true
                    }
                }
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.35), value: currentPage)

            // MARK: - Accessibility Toolbar (always on top)
            VStack {
                AccessibilityToolbar()
                Spacer()
            }

            // MARK: - Page Indicator Dots (bottom)
            VStack {
                Spacer()
                PageIndicatorView(totalPages: 3, currentPage: currentPage)
                    .padding(.bottom, 32)
            }
        }
    }
}

// MARK: - Page Indicator
struct PageIndicatorView: View {

    let totalPages: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color("AppPrimary") : Color("AppSecondaryText").opacity(0.4))
                    .frame(width: index == currentPage ? 12 : 8,
                           height: index == currentPage ? 12 : 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(FontManager())
}
