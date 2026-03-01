// Purpose: Displays the child's collected word collection in a visual barn.
// Shows milestones, word definitions, and allows replaying word pronunciations.

import SwiftUI

// MARK: - Milestone
enum WordMilestone {
    case none
    case explorer     // 5 words
    case star         // 10 words
    case champion     // 20 words

    static func current(for count: Int) -> WordMilestone {
        if count >= 20 { return .champion }
        if count >= 10 { return .star }
        if count >= 5 { return .explorer }
        return .none
    }

    var title: String {
        switch self {
        case .none: return ""
        case .explorer: return "Word Explorer!"
        case .star: return "Reading Star!"
        case .champion: return "Word Champion!"
        }
    }

    var emoji: String {
        switch self {
        case .none: return ""
        case .explorer: return "🗺️"
        case .star: return "⭐"
        case .champion: return "🏆"
        }
    }

    var color: String {
        switch self {
        case .none: return "AppSecondaryText"
        case .explorer: return "AppSuccess"
        case .star: return "AppAccent"
        case .champion: return "AppPrimary"
        }
    }
}

// MARK: - Word Barn View
struct WordBarnView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var fontManager: FontManager
    @AppStorage("wordCount") private var wordCount = 0
    @AppStorage("collectedWordsData") private var collectedWordsData = ""

    @StateObject private var speechService = SpeechService()
    @State private var speakingWord: String? = nil
    @State private var newlyEarnedMilestone: WordMilestone? = nil
    @State private var showMilestoneAnimation = false

    // Parse collected words from AppStorage
    private var collectedWords: [String] {
        guard !collectedWordsData.isEmpty else { return [] }
        return collectedWordsData
            .components(separatedBy: ",")
            .filter { !$0.isEmpty }
            .sorted()
    }

    private var milestone: WordMilestone {
        WordMilestone.current(for: wordCount)
    }

    var body: some View {
        ZStack {
            Color("AppBackground").ignoresSafeArea()

            VStack(spacing: 0) {
                // Back button
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(fontManager.uiFont(size: 17, weight: .semibold))
                        .foregroundColor(Color("AppPrimary"))
                    }
                    .frame(minHeight: 44)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)

                // Accessibility Toolbar
                AccessibilityToolbar()

                if collectedWords.isEmpty {
                    emptyState
                } else {
                    GeometryReader { geo in
                        HStack(alignment: .top, spacing: 0) {
                            // Left Column — Word count + Stats
                            leftColumn
                                .frame(width: geo.size.width * 0.32)

                            // Divider
                            Rectangle()
                                .fill(Color("AppSecondaryText").opacity(0.15))
                                .frame(width: 1)
                                .padding(.vertical, 24)

                            // Right Column — Word Grid
                            rightColumn
                                .frame(width: geo.size.width * 0.68)
                        }
                        .frame(maxWidth: 1000)
                        .frame(maxWidth: .infinity)
                    }
                }
            }

            // Milestone animation overlay
            if showMilestoneAnimation, let earned = newlyEarnedMilestone {
                milestoneOverlay(milestone: earned)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            checkForNewMilestone()
        }
    }

    // MARK: - Left Column
    var leftColumn: some View {
        ScrollView {
            VStack(spacing: 28) {

                // Header
                VStack(spacing: 8) {
                    Text("My Word Barn")
                        .font(fontManager.storyFontBold(size: 28))
                        .foregroundColor(Color("AppText"))

                    Text("\(wordCount) word\(wordCount == 1 ? "" : "s") collected")
                        .font(fontManager.uiFont(size: 18))
                        .foregroundColor(Color("AppSecondaryText"))
                }

                // Word count display
                VStack(spacing: 8) {
                    Text("\(wordCount)")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundColor(Color("AppPrimary"))
                    Text("words collected")
                        .font(fontManager.uiFont(size: 18))
                        .foregroundColor(Color("AppSecondaryText"))
                }

                // Milestone Badge
                if milestone != .none {
                    VStack(spacing: 8) {
                        Text(milestone.emoji)
                            .font(.system(size: 40))
                        Text(milestone.title)
                            .font(fontManager.storyFontBold(size: 20))
                            .foregroundColor(Color("AppSuccess"))
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(Color("AppSuccess").opacity(0.15))
                    .cornerRadius(20)
                }

                // Next milestone progress
                nextMilestoneProgress

            }
            .padding(28)
        }
        .background(Color(hex: "#E8F5E3"))
    }

    // MARK: - Next Milestone Progress
    var nextMilestoneProgress: some View {
        VStack(alignment: .leading, spacing: 12) {
            let nextTarget = wordCount < 5 ? 5 : wordCount < 10 ? 10 : wordCount < 20 ? 20 : 20
            let nextName = wordCount < 5 ? "Word Explorer" : wordCount < 10 ? "Reading Star" : "Word Champion"
            let progress = wordCount < 20 ? Double(wordCount) / Double(nextTarget) : 1.0
            let remaining = max(nextTarget - wordCount, 0)

            if wordCount < 20 {
                Text("Next: \(nextName)")
                    .font(fontManager.uiFont(size: 15, weight: .semibold))
                    .foregroundColor(Color("AppSecondaryText"))

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color("AppSecondaryText").opacity(0.2))
                            .frame(height: 12)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color("AppPrimary"))
                            .frame(width: geo.size.width * progress, height: 12)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
                    }
                }
                .frame(height: 12)

                Text("\(remaining) more word\(remaining == 1 ? "" : "s") to go!")
                    .font(fontManager.uiFont(size: 14))
                    .foregroundColor(Color("AppSecondaryText"))
            } else {
                Text("You've reached the top!")
                    .font(fontManager.uiFont(size: 15, weight: .semibold))
                    .foregroundColor(Color("AppSuccess"))
            }
        }
        .roundedCard(padding: 16)
    }

    // MARK: - Right Column
    var rightColumn: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Your Words")
                    .font(fontManager.storyFontBold(size: 24))
                    .foregroundColor(Color("AppText"))
                    .padding(.top, 4)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(collectedWords, id: \.self) { word in
                        WordBarnCard(
                            word: word,
                            isSpeaking: speakingWord == word,
                            fontManager: fontManager
                        ) {
                            speakingWord = word
                            speechService.speak(word: word)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                if speakingWord == word { speakingWord = nil }
                            }
                        }
                    }
                }
            }
            .padding(28)
        }
    }

    // MARK: - Empty State
    var emptyState: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 8) {
                Text("\(wordCount)")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundColor(Color("AppPrimary"))
                Text("words collected")
                    .font(fontManager.uiFont(size: 18))
                    .foregroundColor(Color("AppSecondaryText"))
            }

            VStack(spacing: 12) {
                Text("Your barn is empty!")
                    .font(fontManager.storyFontBold(size: 28))
                    .foregroundColor(Color("AppText"))

                Text("Read a story and tap words\nto collect them here!")
                    .font(fontManager.storyFont(size: 20))
                    .foregroundColor(Color("AppSecondaryText"))
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Milestone Overlay
    func milestoneOverlay(milestone: WordMilestone) -> some View {
        ZStack {
            Color(hex: "#2C1810").opacity(0.5).ignoresSafeArea()

            VStack(spacing: 20) {
                Text(milestone.emoji)
                    .font(.system(size: 70))
                    .scaleEffect(showMilestoneAnimation ? 1.0 : 0.3)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showMilestoneAnimation)

                Text("You earned:")
                    .font(fontManager.storyFont(size: 22))
                    .foregroundColor(Color("AppSecondaryText"))

                Text(milestone.title)
                    .font(fontManager.storyFontBold(size: 36))
                    .foregroundColor(Color(milestone.color))

                PrimaryButton(label: "Awesome!", icon: nil) {
                    withAnimation { showMilestoneAnimation = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        newlyEarnedMilestone = nil
                    }
                }
                .frame(maxWidth: 300)
            }
            .padding(40)
            .background(Color("AppCardBackground"))
            .cornerRadius(28)
            .shadow(color: Color(hex: "#2C1810").opacity(0.08), radius: 12)
            .opacity(showMilestoneAnimation ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.3), value: showMilestoneAnimation)
        }
    }

    // MARK: - Check For New Milestone
    private func checkForNewMilestone() {
        let current = WordMilestone.current(for: wordCount)
        let previousCount = wordCount - 1
        let previous = WordMilestone.current(for: previousCount)

        if current != previous && current != .none {
            newlyEarnedMilestone = current
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation { showMilestoneAnimation = true }
            }
        }
    }
}

// MARK: - Word Barn Card
struct WordBarnCard: View {

    let word: String
    let isSpeaking: Bool
    let fontManager: FontManager
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                Image(systemName: isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.1")
                    .font(.system(size: 20))
                    .foregroundColor(isSpeaking ? Color("AppPrimary") : Color("AppSecondaryText"))
                    .animation(.easeInOut(duration: 0.2), value: isSpeaking)

                Text(word.capitalized)
                    .font(fontManager.storyFontBold(size: 20))
                    .foregroundColor(isSpeaking ? Color("AppPrimary") : Color("AppText"))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 90)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSpeaking ? Color("AppPrimary").opacity(0.1) : Color("AppCardBackground"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSpeaking ? Color("AppPrimary") : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color(hex: "#2C1810").opacity(0.08), radius: 12)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
            .animation(.easeInOut(duration: 0.2), value: isSpeaking)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel("Word: \(word)\(isSpeaking ? ", speaking" : "")")
        .accessibilityHint("Tap to hear this word spoken aloud")
    }
}
