// Purpose: Third and final onboarding page. Asks for the child's home language
// so Tello can include a translated sentence in each story.
// Calls onComplete when the user taps the final button.

import SwiftUI

struct OnboardingLanguagePage: View {

    let onComplete: () -> Void
    @EnvironmentObject var fontManager: FontManager

    @AppStorage("childName") private var childName = ""
    @AppStorage("homeLanguage") private var homeLanguage = "English"
    @State private var contentOpacity: CGFloat = 0

    let languages: [(name: String, flag: String)] = [
        ("English", "🇬🇧"),
        ("Spanish", "🇪🇸"),
        ("French", "🇫🇷"),
        ("Mandarin", "🇨🇳"),
        ("Arabic", "🇸🇦"),
        ("Hindi", "🇮🇳")
    ]

    var body: some View {
        VStack(spacing: 0) {

            Color.clear.frame(height: 88)

            Spacer()

            VStack(spacing: 40) {

                // MARK: - Heading
                VStack(spacing: 20) {
                    Text("🌍")
                        .font(.system(size: 72))

                    Text("What language do you\nspeak at home\(childName.isEmpty ? "?" : ", \(childName)?")")
                        .font(fontManager.storyFontBold(size: 36))
                        .foregroundColor(Color("AppText"))
                        .multilineTextAlignment(.center)

                    Text("We'll add a special sentence in your language to every story!")
                        .font(fontManager.storyFont(size: 22))
                        .foregroundColor(Color("AppSecondaryText"))
                        .multilineTextAlignment(.center)
                }

                // MARK: - Language Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 18) {
                    ForEach(languages, id: \.name) { language in
                        LanguageButton(
                            name: language.name,
                            flag: language.flag,
                            isSelected: homeLanguage == language.name,
                            fontManager: fontManager
                        ) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                homeLanguage = language.name
                            }
                        }
                    }
                }
                .frame(maxWidth: 620)

                // MARK: - Complete Button
                PrimaryButton(label: "Start Reading! 🚀", icon: nil) {
                    onComplete()
                }
                .frame(maxWidth: 420)

                Text("Don't worry, you can always change this later")
                    .font(fontManager.uiFont(size: 16))
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
}

// MARK: - Language Button Component
struct LanguageButton: View {

    let name: String
    let flag: String
    let isSelected: Bool
    let fontManager: FontManager
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Text(flag)
                    .font(.system(size: 40))
                Text(name)
                    .font(fontManager.uiFont(size: 17, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? Color("AppPrimary") : Color("AppText"))
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 96)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(isSelected ? Color("AppPrimary").opacity(0.14) : Color("AppCardBackground"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(isSelected ? Color("AppPrimary") : Color("AppSecondaryText").opacity(0.15), lineWidth: isSelected ? 2.5 : 1)
            )
            .shadow(color: Color.black.opacity(isSelected ? 0.06 : 0.04), radius: isSelected ? 12 : 8, x: 0, y: 4)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(name) \(isSelected ? "selected" : "")")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview {
    OnboardingLanguagePage(onComplete: {})
        .environmentObject(FontManager())
        .background(Color("AppBackground"))
}
