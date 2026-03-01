// Purpose: Third onboarding page. Asks for the child's home language
// so Tello can include a translated sentence in each story.
// Advances to the accessibility page (page 4) when the user taps Continue.

import SwiftUI

struct OnboardingLanguagePage: View {

    @Binding var currentPage: Int
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

                VStack(spacing: 20) {
                    Text("What language do you\nspeak at home\(childName.isEmpty ? "?" : ", \(childName)?")")
                        .font(fontManager.storyFontBold(size: 34))
                        .foregroundColor(Color("AppText"))
                        .multilineTextAlignment(.center)

                    Text("We'll add a sentence in your language to every story.")
                        .font(fontManager.storyFont(size: 22))
                        .foregroundColor(Color("AppSecondaryText"))
                        .multilineTextAlignment(.center)
                }

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 18) {
                    ForEach(languages, id: \.name) { language in
                        LanguageButton(
                            name: language.name,
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

                PrimaryButton(label: "Continue", icon: nil) {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        currentPage = 4
                    }
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
}

// MARK: - Language Button Component
struct LanguageButton: View {

    let name: String
    let isSelected: Bool
    let fontManager: FontManager
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color("AppPrimary"))
                }
                Text(name)
                    .font(fontManager.uiFont(size: 17, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? Color("AppPrimary") : Color("AppText"))
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 60)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color("AppPrimary").opacity(0.12) : Color("AppCardBackground"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color("AppPrimary") : Color("AppSecondaryText").opacity(0.12), lineWidth: isSelected ? 2 : 1)
            )
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(name) \(isSelected ? "selected" : "")")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview {
    OnboardingLanguagePage(currentPage: .constant(2))
        .environmentObject(FontManager())
        .background(Color("AppBackground"))
}
