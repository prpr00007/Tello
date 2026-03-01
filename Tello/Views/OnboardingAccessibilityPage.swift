// Purpose: Fourth and final onboarding page. Lets the child or
// parent choose their preferred font style and text size before
// entering the app.

import SwiftUI

struct OnboardingAccessibilityPage: View {

    let onComplete: () -> Void
    @EnvironmentObject var fontManager: FontManager
    @State private var contentOpacity: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {

            Color.clear.frame(height: 80)

            Spacer()

            VStack(spacing: 36) {

                // Heading
                VStack(spacing: 12) {
                    Text("How would you like your text?")
                        .font(fontManager.storyFontBold(size: 34))
                        .foregroundColor(Color("AppText"))
                        .multilineTextAlignment(.center)

                    Text("You can always change this in Settings later.")
                        .font(fontManager.storyFont(size: 18))
                        .foregroundColor(Color("AppSecondaryText"))
                        .multilineTextAlignment(.center)
                }

                // Font style selector
                VStack(alignment: .leading, spacing: 12) {
                    Text("Font Style")
                        .font(fontManager.uiFont(size: 16, weight: .semibold))
                        .foregroundColor(Color("AppSecondaryText"))

                    HStack(spacing: 16) {
                        // Standard font option
                        FontOptionCard(
                            title: "Standard",
                            sample: "The big dog ran fast.",
                            isSelected: !fontManager.isDyslexicFont,
                            useRounded: false,
                            fontManager: fontManager
                        ) {
                            fontManager.isDyslexicFont = false
                        }

                        // Dyslexia friendly option
                        FontOptionCard(
                            title: "Dyslexia Friendly",
                            sample: "The big dog ran fast.",
                            isSelected: fontManager.isDyslexicFont,
                            useRounded: true,
                            fontManager: fontManager
                        ) {
                            fontManager.isDyslexicFont = true
                        }
                    }
                }
                .frame(maxWidth: 600)

                // Text size selector
                VStack(alignment: .leading, spacing: 12) {
                    Text("Text Size")
                        .font(fontManager.uiFont(size: 16, weight: .semibold))
                        .foregroundColor(Color("AppSecondaryText"))

                    HStack(spacing: 16) {
                        TextSizeCard(
                            label: "Small",
                            size: 16,
                            isSelected: fontManager.textSizePreference == 1,
                            fontManager: fontManager
                        ) {
                            fontManager.textSizePreference = 1
                        }

                        TextSizeCard(
                            label: "Medium",
                            size: 20,
                            isSelected: fontManager.textSizePreference == 2,
                            fontManager: fontManager
                        ) {
                            fontManager.textSizePreference = 2
                        }

                        TextSizeCard(
                            label: "Large",
                            size: 26,
                            isSelected: fontManager.textSizePreference == 3,
                            fontManager: fontManager
                        ) {
                            fontManager.textSizePreference = 3
                        }
                    }
                }
                .frame(maxWidth: 600)

                // Complete button
                PrimaryButton(label: "Looks good!", icon: nil) {
                    onComplete()
                }
                .frame(maxWidth: 400)
            }
            .frame(maxWidth: 700)
            .padding(.horizontal, 40)
            .opacity(contentOpacity)

            Spacer()
            Color.clear.frame(height: 60)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                contentOpacity = 1.0
            }
        }
    }
}

// MARK: - Font Option Card
struct FontOptionCard: View {
    let title: String
    let sample: String
    let isSelected: Bool
    let useRounded: Bool
    let fontManager: FontManager
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(title)
                    .font(fontManager.uiFont(size: 15, weight: .semibold))
                    .foregroundColor(isSelected ? Color("AppPrimary") : Color("AppSecondaryText"))

                Text(sample)
                    .font(useRounded
                        ? Font.system(size: 18, weight: .regular, design: .rounded)
                        : Font.system(size: 18, weight: .regular, design: .default))
                    .tracking(useRounded ? 1.5 : 0)
                    .lineSpacing(useRounded ? 4 : 0)
                    .foregroundColor(Color("AppText"))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .padding(16)
            .background(Color("AppCardBackground"))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color("AppPrimary") : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color(hex: "#2E3D2F").opacity(0.06), radius: 10)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Text Size Card
struct TextSizeCard: View {
    let label: String
    let size: CGFloat
    let isSelected: Bool
    let fontManager: FontManager
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text("Aa")
                    .font(.system(size: size, weight: .semibold, design: .rounded))
                    .foregroundColor(isSelected ? Color("AppPrimary") : Color("AppText"))

                Text(label)
                    .font(fontManager.uiFont(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? Color("AppPrimary") : Color("AppSecondaryText"))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .padding(16)
            .background(Color("AppCardBackground"))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color("AppPrimary") : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color(hex: "#2E3D2F").opacity(0.06), radius: 10)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    OnboardingAccessibilityPage(onComplete: {})
        .environmentObject(FontManager())
        .background(Color("AppBackground"))
}
