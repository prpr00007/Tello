// Purpose: Word detail sheet overlay shown when the user taps a word.
// Displays the word, definition, SF Symbol, and collect/hear actions.

import SwiftUI

// MARK: - Word Card View
struct WordCardView: View {

    let word: String
    @ObservedObject var viewModel: StoryViewModel
    let fontManager: FontManager

    @State private var wordModel: WordModel?
    @State private var isLoading = true
    @State private var showCollectedConfirmation = false

    var isCollected: Bool {
        viewModel.isWordCollected(word)
    }

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.showWordCard = false
                }

            // Card
            VStack(spacing: 24) {

                // Word
                Text(word.capitalized)
                    .font(fontManager.storyFontBold(size: 42))
                    .foregroundColor(Color("AppText"))

                // SF Symbol illustration
                if let model = wordModel {
                    Image(systemName: model.sfSymbol)
                        .font(.system(size: 60))
                        .foregroundColor(Color("AppPrimary"))
                        .frame(width: 100, height: 100)
                        .background(Color("AppPrimary").opacity(0.1))
                        .cornerRadius(20)
                } else if isLoading {
                    ProgressView()
                        .frame(width: 100, height: 100)
                } else {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 60))
                        .foregroundColor(Color("AppSecondaryText"))
                        .frame(width: 100, height: 100)
                }

                // Definition
                if let model = wordModel {
                    Text(model.definition)
                        .font(fontManager.storyFont(size: 20))
                        .foregroundColor(Color("AppSecondaryText"))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Buttons
                HStack(spacing: 16) {
                    // Pronounce button
                    Button {
                        viewModel.speechService.speak(word: word)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "speaker.wave.2.fill")
                            Text("Hear it")
                        }
                        .font(fontManager.uiFont(size: 17, weight: .medium))
                        .foregroundColor(Color("AppPrimary"))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color("AppPrimary").opacity(0.1))
                        .cornerRadius(14)
                    }

                    // Collect button
                    Button {
                        if !isCollected {
                            viewModel.collectWord(word)
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                showCollectedConfirmation = true
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: isCollected ? "star.fill" : "star")
                            Text(isCollected ? "In your jar" : "Add to jar")
                        }
                        .font(fontManager.uiFont(size: 17, weight: .medium))
                        .foregroundColor(isCollected ? Color("AppSuccess") : .white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(isCollected ? Color("AppSuccess").opacity(0.15) : Color("AppPrimary"))
                        .cornerRadius(14)
                    }
                    .disabled(isCollected)
                }

                // Close button
                Button {
                    viewModel.showWordCard = false
                } label: {
                    Text("Close")
                        .font(fontManager.uiFont(size: 16))
                        .foregroundColor(Color("AppSecondaryText"))
                }
            }
            .padding(36)
            .frame(maxWidth: 480)
            .background(Color("AppCardBackground"))
            .cornerRadius(28)
            .shadow(color: .black.opacity(0.2), radius: 30)
            .overlay(
                // Collected confirmation burst
                showCollectedConfirmation ?
                Text("Added!")
                    .font(fontManager.storyFontBold(size: 22))
                    .foregroundColor(Color("AppAccent"))
                    .transition(.scale.combined(with: .opacity))
                    .offset(y: -160)
                : nil
            )
        }
        .task {
            isLoading = true
            wordModel = await viewModel.fetchWordDefinition(for: word)
            isLoading = false
        }
        .onChange(of: showCollectedConfirmation) { _, showing in
            if showing {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation { showCollectedConfirmation = false }
                }
            }
        }
    }
}
