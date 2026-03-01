// Purpose: Persistent accessibility controls shown across all onboarding pages.
// Allows toggling dyslexia font and adjusting text size at any point.

import SwiftUI

struct AccessibilityToolbar: View {

    @EnvironmentObject var fontManager: FontManager

    var body: some View {
        HStack(spacing: 14) {

            Spacer()

            // MARK: - Dyslexia Font Toggle
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    fontManager.isDyslexicFont.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "textformat.size")
                        .font(.system(size: 18, weight: .semibold))
                    Text(fontManager.isDyslexicFont ? "Standard Font" : "Dyslexia Font")
                        .font(fontManager.uiFont(size: 16, weight: .medium))
                }
                .foregroundColor(fontManager.isDyslexicFont ? Color("AppPrimary") : Color("AppSecondaryText"))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(fontManager.isDyslexicFont ? Color("AppPrimary").opacity(0.14) : Color("AppCardBackground"))
                )
                .overlay(
                    Capsule()
                        .stroke(Color("AppPrimary").opacity(fontManager.isDyslexicFont ? 0.3 : 0), lineWidth: 1.5)
                )
            }
            .accessibilityLabel(fontManager.isDyslexicFont ? "Switch to standard font" : "Switch to dyslexia friendly font")
            .accessibilityHint("Changes the font style used throughout the app")

            // MARK: - Text Size Control
            HStack(spacing: 2) {
                Button {
                    if fontManager.textSizePreference > 1 {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            fontManager.textSizePreference -= 1
                        }
                    }
                } label: {
                    Image(systemName: "textformat.size.smaller")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(fontManager.textSizePreference == 1 ? Color("AppSecondaryText") : Color("AppPrimary"))
                        .frame(width: 48, height: 48)
                }
                .disabled(fontManager.textSizePreference == 1)
                .accessibilityLabel("Decrease text size")

                Text(["S", "M", "L"][fontManager.textSizePreference - 1])
                    .font(fontManager.uiFont(size: 16, weight: .bold))
                    .foregroundColor(Color("AppText"))
                    .frame(width: 28)

                Button {
                    if fontManager.textSizePreference < 3 {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            fontManager.textSizePreference += 1
                        }
                    }
                } label: {
                    Image(systemName: "textformat.size.larger")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(fontManager.textSizePreference == 3 ? Color("AppSecondaryText") : Color("AppPrimary"))
                        .frame(width: 48, height: 48)
                }
                .disabled(fontManager.textSizePreference == 3)
                .accessibilityLabel("Increase text size")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color("AppCardBackground"))
            )
        }
        .padding(.horizontal, 28)
        .padding(.top, 20)
    }
}

#Preview {
    AccessibilityToolbar()
        .environmentObject(FontManager())
        .background(Color("AppBackground"))
}
