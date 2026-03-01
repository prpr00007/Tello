// Purpose: Fourth onboarding page. Lets the child/parent choose text style
// (dyslexia font) and text size via large tappable cards. Calls onComplete when done.

import SwiftUI

struct OnboardingAccessibilityPage: View {

    let onComplete: () -> Void
    @EnvironmentObject var fontManager: FontManager

    @State private var contentOpacity: CGFloat = 0

    private let sampleSentence = "The quick brown fox jumps over the lazy dog."

    var body: some View {
        VStack(spacing: 0) {

            Color.clear.frame(height: 88)

            Spacer()

            VStack(spacing: 32) {

                Text("How would you like your text?")
                    .font(fontManager.storyFontBold(size: 34))
                    .foregroundColor(Color("AppText"))
                    .multilineTextAlignment(.center)

                // Dyslexia font: two large cards (standard vs dyslexia)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Reading style")
                        .font(fontManager.uiFont(size: 15, weight: .semibold))
                        .foregroundColor(Color("AppSecondaryText"))

                    HStack(spacing: 16) {
                        dyslexiaOptionCard(
                            title: "Standard",
                            useDyslexic: false
                        )
                        dyslexiaOptionCard(
                            title: "Dyslexia-friendly",
                            useDyslexic: true
                        )
                    }
                }

                // Text size: three large cards (Small, Medium, Large)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Text size")
                        .font(fontManager.uiFont(size: 15, weight: .semibold))
                        .foregroundColor(Color("AppSecondaryText"))

                    HStack(spacing: 16) {
                        textSizeCard(label: "Small", size: 1)
                        textSizeCard(label: "Medium", size: 2)
                        textSizeCard(label: "Large", size: 3)
                    }
                }

                PrimaryButton(label: "Looks good!", icon: nil) {
                    onComplete()
                }
                .frame(maxWidth: 400)

                Text("You can change this later in settings.")
                    .font(fontManager.uiFont(size: 15))
                    .foregroundColor(Color("AppSecondaryText"))
            }
            .frame(maxWidth: 700)
            .padding(.horizontal, 48)
            .opacity(contentOpacity)

            Spacer()
            Color.clear.frame(height: 72)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                contentOpacity = 1.0
            }
        }
    }

    private func dyslexiaOptionCard(title: String, useDyslexic: Bool) -> some View {
        let isSelected = fontManager.isDyslexicFont == useDyslexic
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                fontManager.isDyslexicFont = useDyslexic
            }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(fontManager.uiFont(size: 17, weight: .semibold))
                    .foregroundColor(isSelected ? Color("AppPrimary") : Color("AppText"))

                Text(sampleSentence)
                    .font(useDyslexic
                        ? .system(size: 18, weight: .regular, design: .rounded)
                        : .system(size: 18, weight: .regular, design: .default))
                    .foregroundColor(Color("AppSecondaryText"))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color("AppPrimary").opacity(0.12) : Color("AppCardBackground"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color("AppPrimary") : Color("AppSecondaryText").opacity(0.12), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(title), \(isSelected ? "selected" : "")")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private func textSizeCard(label: String, size: Int) -> some View {
        let isSelected = fontManager.textSizePreference == size
        let multiplier: CGFloat = size == 1 ? 0.85 : size == 3 ? 1.2 : 1.0
        let sampleSize: CGFloat = 18 * multiplier
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                fontManager.textSizePreference = size
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Text(label)
                    .font(fontManager.uiFont(size: 17, weight: .semibold))
                    .foregroundColor(isSelected ? Color("AppPrimary") : Color("AppText"))

                Text(sampleSentence)
                    .font(.system(size: sampleSize, weight: .regular, design: fontManager.isDyslexicFont ? .rounded : .default))
                    .foregroundColor(Color("AppSecondaryText"))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color("AppPrimary").opacity(0.12) : Color("AppCardBackground"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color("AppPrimary") : Color("AppSecondaryText").opacity(0.12), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(label), \(isSelected ? "selected" : "")")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview {
    OnboardingAccessibilityPage(onComplete: {})
        .environmentObject(FontManager())
        .background(Color("AppBackground"))
}
