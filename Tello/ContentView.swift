// Purpose: Temporary debug view to verify the Stage 1 design system.
// This file will be replaced in Stage 2 with the real app navigation.

import SwiftUI

struct ContentView: View {

    @EnvironmentObject var fontManager: FontManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // MARK: - Header
                Text("Stage 1 Design System Check")
                    .font(fontManager.storyFontBold(size: 22))
                    .foregroundColor(Color("AppText"))

                // MARK: - Colour Swatches
                Text("Colour Palette")
                    .font(fontManager.uiFont(size: 14, weight: .semibold))
                    .foregroundColor(Color("AppSecondaryText"))

                let colours: [(String, String)] = [
                    ("AppBackground", "Background"),
                    ("AppPrimary", "Primary"),
                    ("AppAccent", "Accent"),
                    ("AppSuccess", "Success"),
                    ("AppText", "Text"),
                    ("AppSecondaryText", "Secondary Text"),
                    ("AppCardBackground", "Card Background")
                ]

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(colours, id: \.0) { (assetName, label) in
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(assetName))
                                .frame(height: 60)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            Text(label)
                                .font(fontManager.uiFont(size: 11))
                                .foregroundColor(Color("AppSecondaryText"))
                        }
                    }
                }

                // MARK: - Font Demo
                Text("Typography")
                    .font(fontManager.uiFont(size: 14, weight: .semibold))
                    .foregroundColor(Color("AppSecondaryText"))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Story font — size 20")
                        .font(fontManager.storyFont(size: 20))
                        .foregroundColor(Color("AppText"))
                    Text("Story font bold — size 20")
                        .font(fontManager.storyFontBold(size: 20))
                        .foregroundColor(Color("AppText"))
                    Text("The quick brown fox jumps over the lazy dog")
                        .font(fontManager.storyFont(size: 16))
                        .foregroundColor(Color("AppText"))
                }
                .roundedCard()

                // MARK: - Font Toggle
                Toggle("Dyslexia-friendly font", isOn: $fontManager.isDyslexicFont)
                    .font(fontManager.uiFont(size: 16))
                    .foregroundColor(Color("AppText"))
                    .roundedCard()

                // MARK: - Text Size Stepper
                Stepper(
                    "Text Size: \(["Small", "Medium", "Large"][fontManager.textSizePreference - 1])",
                    value: $fontManager.textSizePreference,
                    in: 1...3
                )
                .font(fontManager.uiFont(size: 16))
                .foregroundColor(Color("AppText"))
                .roundedCard()

                // MARK: - Card Demo
                Text("RoundedCard Component")
                    .font(fontManager.uiFont(size: 14, weight: .semibold))
                    .foregroundColor(Color("AppSecondaryText"))

                Text("This is content inside a RoundedCard. It should have white background, rounded corners, and a soft shadow.")
                    .font(fontManager.storyFont(size: 16))
                    .foregroundColor(Color("AppText"))
                    .roundedCard()

                // MARK: - Button Demo
                Text("PrimaryButton Component")
                    .font(fontManager.uiFont(size: 14, weight: .semibold))
                    .foregroundColor(Color("AppSecondaryText"))

                PrimaryButton(label: "Let's Go!", icon: "arrow.right") {
                    print("✅ PrimaryButton tapped")
                }

                PrimaryButton(label: "Start Reading") {
                    print("✅ PrimaryButton (no icon) tapped")
                }

                // MARK: - AppStorage Persistence Check
                Text("AppStorage Persistence")
                    .font(fontManager.uiFont(size: 14, weight: .semibold))
                    .foregroundColor(Color("AppSecondaryText"))

                VStack(alignment: .leading, spacing: 4) {
                    Text("isDyslexicFont: \(fontManager.isDyslexicFont ? "true" : "false")")
                    Text("textSizePreference: \(fontManager.textSizePreference)")
                    Text("sizeMultiplier: \(String(format: "%.2f", fontManager.sizeMultiplier))")
                }
                .font(fontManager.uiFont(size: 14))
                .foregroundColor(Color("AppText"))
                .roundedCard()

            }
            .padding(20)
        }
        .background(Color("AppBackground").ignoresSafeArea())
    }
}

#Preview {
    ContentView()
        .environmentObject(FontManager())
}
