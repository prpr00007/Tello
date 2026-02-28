// Purpose: Persistent accessibility controls shown across all onboarding pages.
// Allows toggling dyslexia font and adjusting text size at any point.

import SwiftUI

struct AccessibilityToolbar: View {

    @EnvironmentObject var fontManager: FontManager

    var body: some View {
        HStack(spacing: 16) {

            Spacer()

            // MARK: - Dyslexia Font Toggle
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    fontManager.isDyslexicFont.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "textformat.size")
                        .font(.system(size: 18, weight: .semibold))
                    Text(fontManager.isDyslexicFont ? "Standard Font" : "Dyslexia Font")
                        .font(fontManager.uiFont(size: 15, weight: .medium))
                }
                .foregroundColor(fontManager.isDyslexicFont ? Color("AppPrimary") : Color("AppSecondaryText"))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(fontManager.isDyslexicFont ? Color("AppPrimary").opacity(0.12) : Color("AppCardBackground"))
                )
            }
            .accessibilityLabel(fontManager.isDyslexicFont ? "Switch to standard font" : "Switch to dyslexia friendly font")
            .accessibilityHint("Changes the font style used throughout the app")

            // MARK: - Text Size Control
            HStack(spacing: 4) {
                Button {
                    if fontManager.textSizePreference > 1 {
                        withAnimation { fontManager.textSizePreference -= 1 }
                    }
                } label: {
                    Image(systemName: "textformat.size.smaller")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(fontManager.textSizePreference == 1 ? Color("AppSecondaryText") : Color("AppPrimary"))
                        .frame(width: 44, height: 44)
                }
                .disabled(fontManager.textSizePreference == 1)
                .accessibilityLabel("Decrease text size")

                Text(["S", "M", "L"][fontManager.textSizePreference - 1])
                    .font(fontManager.uiFont(size: 15, weight: .bold))
                    .foregroundColor(Color("AppText"))
                    .frame(width: 24)

                Button {
                    if fontManager.textSizePreference < 3 {
                        withAnimation { fontManager.textSizePreference += 1 }
                    }
                } label: {
                    Image(systemName: "textformat.size.larger")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(fontManager.textSizePreference == 3 ? Color("AppSecondaryText") : Color("AppPrimary"))
                        .frame(width: 44, height: 44)
                }
                .disabled(fontManager.textSizePreference == 3)
                .accessibilityLabel("Increase text size")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("AppCardBackground"))
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
}

#Preview {
    AccessibilityToolbar()
        .environmentObject(FontManager())
        .background(Color("AppBackground"))
}
