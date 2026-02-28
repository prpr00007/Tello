// Purpose: Temporary debug view to verify the Stage 1 design system on iPad landscape.
// This file will be replaced in Stage 2 with the real app navigation.

import SwiftUI

struct ContentView: View {

    @EnvironmentObject var fontManager: FontManager

    var body: some View {
        GeometryReader { geo in
            if geo.size.width > 700 {
                // MARK: - iPad Landscape Layout (content capped at 900pt, centred)
                let contentWidth = min(geo.size.width, 900)
                HStack(alignment: .top, spacing: 0) {
                    // Left Column (40%)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            colourSwatches
                            typographyDemo
                        }
                        .padding(24)
                    }
                    .frame(width: contentWidth * 0.4)

                    Divider()

                    // Right Column (60%)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            controlsDemo
                            cardDemo
                            buttonDemo
                            persistenceDemo
                        }
                        .padding(24)
                    }
                    .frame(width: contentWidth * 0.6)
                }
                .frame(width: contentWidth)
                .frame(maxWidth: .infinity)
                .background(Color("AppBackground").ignoresSafeArea())

            } else {
                // MARK: - iPhone Fallback Layout (single column)
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        colourSwatches
                        typographyDemo
                        controlsDemo
                        cardDemo
                        buttonDemo
                        persistenceDemo
                    }
                    .padding(20)
                }
                .background(Color("AppBackground").ignoresSafeArea())
            }
        }
    }

    // MARK: - Colour Swatches
    var colourSwatches: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stage 1.5 — iPad Layout Check")
                .font(fontManager.storyFontBold(size: 22))
                .foregroundColor(Color("AppText"))

            Text("Colour Palette")
                .font(fontManager.uiFont(size: 14, weight: .semibold))
                .foregroundColor(Color("AppSecondaryText"))

            let colours: [(String, String)] = [
                ("AppBackground", "Background"),
                ("AppPrimary", "Primary"),
                ("AppAccent", "Accent"),
                ("AppSuccess", "Success"),
                ("AppText", "Text"),
                ("AppSecondaryText", "Secondary"),
                ("AppCardBackground", "Card BG")
            ]

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(colours, id: \.0) { (assetName, label) in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(assetName))
                            .frame(height: 50)
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
        }
    }

    // MARK: - Typography Demo
    var typographyDemo: some View {
        VStack(alignment: .leading, spacing: 12) {
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
        }
    }

    // MARK: - Controls Demo
    var controlsDemo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Controls")
                .font(fontManager.uiFont(size: 14, weight: .semibold))
                .foregroundColor(Color("AppSecondaryText"))

            Toggle("Dyslexia-friendly font", isOn: $fontManager.isDyslexicFont)
                .font(fontManager.uiFont(size: 16))
                .foregroundColor(Color("AppText"))
                .roundedCard()

            Stepper(
                "Text Size: \(["Small", "Medium", "Large"][fontManager.textSizePreference - 1])",
                value: $fontManager.textSizePreference,
                in: 1...3
            )
            .font(fontManager.uiFont(size: 16))
            .foregroundColor(Color("AppText"))
            .roundedCard()
        }
    }

    // MARK: - Card Demo
    var cardDemo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RoundedCard Component")
                .font(fontManager.uiFont(size: 14, weight: .semibold))
                .foregroundColor(Color("AppSecondaryText"))

            Text("This is content inside a RoundedCard. White background, rounded corners, soft shadow.")
                .font(fontManager.storyFont(size: 16))
                .foregroundColor(Color("AppText"))
                .roundedCard()
        }
    }

    // MARK: - Button Demo
    var buttonDemo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PrimaryButton Component")
                .font(fontManager.uiFont(size: 14, weight: .semibold))
                .foregroundColor(Color("AppSecondaryText"))

            PrimaryButton(label: "Let's Go!", icon: "arrow.right") {
                print("✅ PrimaryButton tapped")
            }

            PrimaryButton(label: "Start Reading") {
                print("✅ PrimaryButton (no icon) tapped")
            }
        }
    }

    // MARK: - Persistence Demo
    var persistenceDemo: some View {
        VStack(alignment: .leading, spacing: 12) {
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
    }
}

#Preview {
    ContentView()
        .environmentObject(FontManager())
}
