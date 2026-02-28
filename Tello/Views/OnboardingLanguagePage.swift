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

    // Supported languages with flag emoji
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

            Color.clear.frame(height: 80)

            Spacer()

            VStack(spacing: 36) {

                // MARK: - Heading
                VStack(spacing: 16) {
                    Text("🌍")
                        .font(.system(size: 64))

                    Text("What language do you\nspeak at home\(childName.isEmpty ? "?" : ", \(childName)?")")
                        .font(fontManager.storyFontBold(size: 34))
                        .foregroundColor(Color("AppText"))
                        .multilineTextAlignment(.center)

                    Text("We'll add a special sentence in your language to every story!")
                        .font(fontManager.storyFont(size: 20))
                        .foregroundColor(Color("AppSecondaryText"))
                        .multilineTextAlignment(.center)
                }

                // MARK: - Language Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(languages, id: \.name) { language in
                        LanguageButton(
                            name: language.name,
                            flag: language.flag,
                            isSelected: homeLanguage == language.name,
                            fontManager: fontManager
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                homeLanguage = language.name
                            }
                        }
                    }
                }
                .frame(maxWidth: 600)

                // MARK: - Complete Button
                PrimaryButton(
                    label: "Start Reading! 🚀",
                    icon: nil
                ) {
                    onComplete()
                }
                .frame(maxWidth: 400)

                // Reassurance note
                Text("Don't worry, you can always change this later")
                    .font(fontManager.uiFont(size: 15))
                    .foregroundColor(Color("AppSecondaryText"))
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

// MARK: - Language Button Component
struct LanguageButton: View {

    let name: String
    let flag: String
    let isSelected: Bool
    let fontManager: FontManager
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(flag)
                    .font(.system(size: 36))
                Text(name)
                    .font(fontManager.uiFont(size: 16, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? Color("AppPrimary") : Color("AppText"))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 90)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color("AppPrimary").opacity(0.12) : Color("AppCardBackground"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color("AppPrimary") : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(isSelected ? 0.0 : 0.05), radius: 6, x: 0, y: 2)
            .scaleEffect(isSelected ? 1.03 : 1.0)
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
