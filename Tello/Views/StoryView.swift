// Purpose: The main interactive story reading experience.
// Displays story one sentence at a time with tappable words,
// speech synthesis, and word collection.

import SwiftUI
import AVFoundation

struct StoryView: View {

    // MARK: - Properties
    let story: StoryModel
    @Binding var navigationPath: NavigationPath

    @EnvironmentObject var fontManager: FontManager
    @StateObject private var speechService = SpeechService()
    @StateObject private var viewModel: StoryViewModel
    @State private var navigateToWordJar = false

    @AppStorage("hasSeenWordTapTip") private var hasSeenWordTapTip = false
    @State private var showWordTip = false

    init(story: StoryModel, navigationPath: Binding<NavigationPath>) {
        self.story = story
        _navigationPath = navigationPath
        let speech = SpeechService()
        _speechService = StateObject(wrappedValue: speech)
        _viewModel = StateObject(wrappedValue: StoryViewModel(story: story, speechService: speech))
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            Color("AppBackground").ignoresSafeArea()

            VStack(spacing: 0) {
                // Home button
                HStack(spacing: 16) {
                    Button {
                        speechService.stop()
                        navigationPath = NavigationPath()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "house.fill")
                            Text("Home")
                        }
                        .font(fontManager.uiFont(size: 17, weight: .semibold))
                        .foregroundColor(Color("AppPrimary"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color("AppPrimary").opacity(0.1))
                        .cornerRadius(20)
                    }
                    .frame(minHeight: 44)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)

                // Story Content
                VStack(spacing: 0) {
                    // Story Title
                    storyTitle

                    Spacer()

                    // Current Sentence
                    sentenceCard

                    Spacer()

                    // Navigation
                    navigationBar
                }
                .frame(maxWidth: 800)
                .padding(.horizontal, 32)
            }

            // Word Card Sheet
            if viewModel.showWordCard, let word = viewModel.selectedWord {
                WordCardView(
                    word: word,
                    viewModel: viewModel,
                    fontManager: fontManager
                )
            }

            // Celebration Overlay
            if viewModel.showCelebration {
                CelebrationView(fontManager: fontManager, onDismiss: {
                    viewModel.showCelebration = false
                }, onViewWordJar: {
                    navigateToWordJar = true
                }, onReadAnotherStory: {
                    viewModel.showCelebration = false
                    navigationPath = NavigationPath()
                })
            }

            // One-time word tap tip overlay
            if showWordTip {
                ZStack {
                    // Dim background
                    Color(hex: "#2E3D2F").opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture { dismissTip() }

                    // Tip card
                    VStack(alignment: .leading, spacing: 20) {

                        Text("Here is how it works")
                            .font(fontManager.storyFontBold(size: 26))
                            .foregroundColor(Color("AppText"))

                        // Row 1
                        HStack(spacing: 16) {
                            Image(systemName: "hand.tap.fill")
                                .font(.system(size: 28))
                                .foregroundColor(Color("AppPrimary"))
                                .frame(width: 48)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Tap any word")
                                    .font(fontManager.storyFontBold(size: 20))
                                    .foregroundColor(Color("AppText"))
                                Text("Hear it spoken and see what it means")
                                    .font(fontManager.storyFont(size: 17))
                                    .foregroundColor(Color("AppSecondaryText"))
                            }
                        }

                        // Row 2
                        HStack(spacing: 16) {
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 28))
                                .foregroundColor(Color("AppPrimary"))
                                .frame(width: 48)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Add to your Word Barn")
                                    .font(fontManager.storyFontBold(size: 20))
                                    .foregroundColor(Color("AppText"))
                                Text("Build your collection word by word")
                                    .font(fontManager.storyFont(size: 17))
                                    .foregroundColor(Color("AppSecondaryText"))
                            }
                        }

                        // Row 3
                        HStack(spacing: 16) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(Color("AppPrimary"))
                                .frame(width: 48)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Read it aloud")
                                    .font(fontManager.storyFontBold(size: 20))
                                    .foregroundColor(Color("AppText"))
                                Text("Press the read button to hear the full sentence")
                                    .font(fontManager.storyFont(size: 17))
                                    .foregroundColor(Color("AppSecondaryText"))
                            }
                        }

                        PrimaryButton(label: "Got it, let me read!", icon: nil) {
                            dismissTip()
                        }
                        .padding(.top, 8)
                    }
                    .padding(36)
                    .frame(maxWidth: 520)
                    .background(Color("AppCardBackground"))
                    .cornerRadius(28)
                    .shadow(color: Color(hex: "#2E3D2F").opacity(0.15), radius: 20)
                    .scaleEffect(showWordTip ? 1.0 : 0.85)
                    .opacity(showWordTip ? 1.0 : 0.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showWordTip)
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToWordJar) {
            WordBarnView()
                .navigationBarHidden(true)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if !hasSeenWordTapTip {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        showWordTip = true
                    }
                }
            }
        }
        .onDisappear {
            speechService.stop()
        }
    }

    private func dismissTip() {
        withAnimation(.easeOut(duration: 0.2)) {
            showWordTip = false
        }
        hasSeenWordTapTip = true
    }

    // MARK: - Story Title
    var storyTitle: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(story.title)
                    .font(fontManager.storyFontBold(size: 28))
                    .foregroundColor(Color("AppText"))
                    .dyslexiaStyle(enabled: fontManager.isDyslexicFont)

                Text("About: \(story.detectedObject.capitalized)")
                    .font(fontManager.uiFont(size: 16))
                    .foregroundColor(Color("AppSecondaryText"))
            }

            Spacer()

            // Auto-read button
            Button {
                if speechService.isSpeaking {
                    speechService.stop()
                    viewModel.highlightedWordIndex = nil
                } else {
                    viewModel.autoReadCurrentSentence()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: speechService.isSpeaking ? "stop.circle.fill" : "play.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Color("AppPrimary"))
                    Text(speechService.isSpeaking ? "Stop" : "Read aloud")
                        .font(fontManager.uiFont(size: 16, weight: .medium))
                        .foregroundColor(Color("AppPrimary"))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color("AppPrimary").opacity(0.1))
                .cornerRadius(20)
            }
            .accessibilityLabel(speechService.isSpeaking ? "Stop reading" : "Read sentence aloud")
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color(hex: "#2E3D2F").opacity(0.06), radius: 10)
        .padding(.top, 16)
        .padding(.bottom, 24)
    }

    // MARK: - Sentence Card
    var sentenceCard: some View {
        VStack(spacing: 32) {
            // Interactive word-by-word sentence
            InteractiveSentenceView(
                sentence: viewModel.currentSentence,
                highlightedWordIndex: viewModel.highlightedWordIndex,
                collectedWords: viewModel.collectedWords,
                fontManager: fontManager
            ) { word in
                viewModel.wordTapped(word)
            }

            // Sentence number indicator
            Text("Sentence \(viewModel.currentSentenceIndex + 1) of \(story.sentences.count)")
                .font(fontManager.uiFont(size: 15))
                .foregroundColor(Color("AppSecondaryText"))
        }
        .roundedCard(padding: 32)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color("AppPrimary"))
                .frame(width: 4)
        }
    }

    // MARK: - Navigation Bar
    var navigationBar: some View {
        HStack(spacing: 32) {
            // Previous button
            Button {
                viewModel.previousSentence()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Back")
                        .font(fontManager.uiFont(size: 18, weight: .medium))
                }
                .foregroundColor(viewModel.currentSentenceIndex == 0 ? Color("AppSecondaryText") : Color("AppPrimary"))
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .frame(minHeight: 60)
                .background(Color("AppCardBackground"))
                .cornerRadius(20)
            }
            .disabled(viewModel.currentSentenceIndex == 0)

            // Progress dots
            HStack(spacing: 10) {
                ForEach(0..<story.sentences.count, id: \.self) { index in
                    Circle()
                        .fill(index == viewModel.currentSentenceIndex ? Color("AppPrimary") : Color("AppSecondaryText").opacity(0.3))
                        .frame(
                            width: index == viewModel.currentSentenceIndex ? 12 : 8,
                            height: index == viewModel.currentSentenceIndex ? 12 : 8
                        )
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.currentSentenceIndex)
                }
            }

            // Next button
            PrimaryButton(
                label: viewModel.isLastSentence ? "Finish!" : "Next →",
                icon: nil
            ) {
                viewModel.nextSentence()
            }
            .frame(maxWidth: 180)
        }
        .padding(.vertical, 24)
    }
}

// MARK: - Interactive Sentence View
struct InteractiveSentenceView: View {

    let sentence: String
    let highlightedWordIndex: Int?
    let collectedWords: Set<String>
    let fontManager: FontManager
    let onWordTap: (String) -> Void

    private var words: [String] {
        sentence.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
    }

    var body: some View {
        // Use a flow layout for words that wraps naturally
        FlowLayout(spacing: 8) {
            ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                WordButton(
                    word: word,
                    index: index,
                    isHighlighted: highlightedWordIndex == index,
                    isCollected: collectedWords.contains(
                        word.trimmingCharacters(in: .punctuationCharacters).lowercased()
                    ),
                    fontManager: fontManager,
                    onTap: { onWordTap(word) }
                )
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Word Button
struct WordButton: View {

    let word: String
    let index: Int
    let isHighlighted: Bool
    let isCollected: Bool
    let fontManager: FontManager
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            Text(word)
                .font(fontManager.storyFont(size: 26))
                .foregroundColor(isHighlighted ? Color("AppPrimary") : Color("AppText"))
                .dyslexiaStyle(enabled: fontManager.isDyslexicFont)
                .underline(isHighlighted)
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isHighlighted ? Color("AppPrimary").opacity(0.12) : Color.clear)
                )
                .overlay(
                    // Small star if word is collected
                    isCollected ?
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "star.fill")
                                .font(.system(size: 8))
                                .foregroundColor(Color("AppAccent"))
                                .offset(x: 2, y: -2)
                        }
                        Spacer()
                    } : nil
                )
                .scaleEffect(isPressed ? 0.92 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
                .animation(.easeInOut(duration: 0.2), value: isHighlighted)
        }
        .buttonStyle(PlainButtonStyle())
        .frame(minHeight: 44)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel("Word: \(word)\(isCollected ? ", collected" : "")")
        .accessibilityHint("Tap to hear this word and see its meaning")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {

    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width,
                                subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX,
                                               y: bounds.minY + frame.minY),
                                   proposal: ProposedViewSize(frame.size))
        }
    }

    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            var maxX: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
                x += size.width + spacing
                maxX = max(maxX, x)
                lineHeight = max(lineHeight, size.height)
            }
            self.size = CGSize(width: maxX, height: y + lineHeight)
        }
    }
}

// MARK: - Celebration View
struct CelebrationView: View {

    let fontManager: FontManager
    let onDismiss: () -> Void
    let onViewWordJar: () -> Void
    let onReadAnotherStory: () -> Void

    @AppStorage("childName") private var childName = ""
    @AppStorage("wordCount") private var wordCount = 0
    @State private var scale: CGFloat = 0.5
    @State private var opacity: CGFloat = 0

    var body: some View {
        ZStack {
            Color(hex: "#2E3D2F").opacity(0.5).ignoresSafeArea()

            VStack(spacing: 28) {
                Image(systemName: "star.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color("AppAccent"))

                Text("Amazing reading,\n\(childName)!")
                    .font(fontManager.storyFontBold(size: 36))
                    .foregroundColor(Color("AppText"))
                    .multilineTextAlignment(.center)

                Text("You've collected \(wordCount) words so far!")
                    .font(fontManager.storyFont(size: 22))
                    .foregroundColor(Color("AppSecondaryText"))

                VStack(spacing: 12) {
                    PrimaryButton(label: "Visit my Word Barn", icon: nil) {
                        onDismiss()
                        onViewWordJar()
                    }

                    Button {
                        onReadAnotherStory()
                    } label: {
                        Text("Read another story")
                            .font(fontManager.uiFont(size: 18))
                            .foregroundColor(Color("AppSecondaryText"))
                    }
                }
                .frame(maxWidth: 360)
            }
            .padding(40)
            .frame(maxWidth: 560)
            .background(Color("AppCardBackground"))
            .cornerRadius(28)
            .shadow(color: Color(hex: "#2E3D2F").opacity(0.06), radius: 10)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}
