// Purpose: App settings — name, home language, accessibility (dyslexia font, text size).
// Presented from HomeView or CameraView; back button pops to root.

import SwiftUI

struct SettingsView: View {

    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var fontManager: FontManager
    @AppStorage("childName") private var childName = ""
    @AppStorage("homeLanguage") private var homeLanguage = "English"

    private let languages: [(name: String, flag: String)] = [
        ("English", "🇬🇧"),
        ("Spanish", "🇪🇸"),
        ("French", "🇫🇷"),
        ("Mandarin", "🇨🇳"),
        ("Arabic", "🇸🇦"),
        ("Hindi", "🇮🇳")
    ]

    var body: some View {
        ZStack {
            Color("AppBackground").ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Back button
                    Button {
                        navigationPath = NavigationPath()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(fontManager.uiFont(size: 17, weight: .semibold))
                        .foregroundColor(Color("AppPrimary"))
                    }
                    .frame(minHeight: 44)
                    .padding(.bottom, 8)

                    Text("Settings ⚙️")
                        .font(fontManager.storyFontBold(size: 36))
                        .foregroundColor(Color("AppText"))
                        .padding(.bottom, 8)

                    // Dyslexia font row
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Reading font")
                            .font(fontManager.uiFont(size: 15, weight: .semibold))
                            .foregroundColor(Color("AppSecondaryText"))
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
                            .frame(maxWidth: .infinity, alignment: .leading)
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
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel(fontManager.isDyslexicFont ? "Switch to standard font" : "Switch to dyslexia friendly font")
                    }
                    .roundedCard(padding: 16)

                    // Text size row
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Text size")
                            .font(fontManager.uiFont(size: 15, weight: .semibold))
                            .foregroundColor(Color("AppSecondaryText"))
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
                        .background(Capsule().fill(Color("AppCardBackground")))
                    }
                    .roundedCard(padding: 16)

                    // Your Name row
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Name")
                            .font(fontManager.uiFont(size: 15, weight: .semibold))
                            .foregroundColor(Color("AppSecondaryText"))
                        TextField("Your name", text: $childName)
                            .font(fontManager.uiFont(size: 17))
                            .foregroundColor(Color("AppText"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color("AppCardBackground"))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                                    )
                            )
                            .autocapitalization(.words)
                    }
                    .roundedCard(padding: 16)

                    // Home Language row
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Home Language")
                            .font(fontManager.uiFont(size: 15, weight: .semibold))
                            .foregroundColor(Color("AppSecondaryText"))
                        Picker("Home Language", selection: $homeLanguage) {
                            ForEach(languages, id: \.name) { language in
                                Text("\(language.flag) \(language.name)")
                                    .font(fontManager.uiFont(size: 17))
                                    .tag(language.name)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Color("AppText"))
                    }
                    .roundedCard(padding: 16)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 48)
            }
        }
    }
}
