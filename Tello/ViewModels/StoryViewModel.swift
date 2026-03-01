// Purpose: Manages story reading state including current sentence,
// word collection, and speech coordination.

import SwiftUI

@MainActor
class StoryViewModel: ObservableObject {

    // MARK: - Published
    @Published var currentSentenceIndex = 0
    @Published var highlightedWordIndex: Int? = nil
    @Published var selectedWord: String? = nil
    @Published var showWordCard = false
    @Published var isStoryComplete = false
    @Published var showCelebration = false
    @Published var collectedWords: Set<String> = []

    // MARK: - Properties
    let story: StoryModel
    let speechService: SpeechService
    let groqService = GroqService()

    // Word definition cache
    var wordDefinitionCache: [String: WordModel] = [:]

    @AppStorage("wordCount") var wordCount = 0
    @AppStorage("collectedWordsData") private var collectedWordsData = ""

    // MARK: - Computed
    var currentSentence: String {
        guard currentSentenceIndex < story.sentences.count else { return "" }
        return story.sentences[currentSentenceIndex]
    }

    var currentWords: [String] {
        currentSentence.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
    }

    var isLastSentence: Bool {
        currentSentenceIndex == story.sentences.count - 1
    }

    var progress: Double {
        Double(currentSentenceIndex + 1) / Double(story.sentences.count)
    }

    // MARK: - Init
    init(story: StoryModel, speechService: SpeechService) {
        self.story = story
        self.speechService = speechService
        loadCollectedWords()
    }

    // MARK: - Navigation
    func nextSentence() {
        speechService.stop()
        highlightedWordIndex = nil

        if isLastSentence {
            isStoryComplete = true
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showCelebration = true
            }
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentSentenceIndex += 1
            }
        }
    }

    func previousSentence() {
        guard currentSentenceIndex > 0 else { return }
        speechService.stop()
        highlightedWordIndex = nil
        withAnimation(.easeInOut(duration: 0.3)) {
            currentSentenceIndex -= 1
        }
    }

    // MARK: - Word Tap
    func wordTapped(_ word: String) {
        // Clean the word (remove punctuation for speech/definition)
        let cleaned = word.trimmingCharacters(in: .punctuationCharacters).lowercased()
        guard !cleaned.isEmpty else { return }

        selectedWord = cleaned
        speechService.speak(word: cleaned)
        showWordCard = true
    }

    // MARK: - Auto Read Sentence
    func autoReadCurrentSentence() {
        speechService.speakSentence(currentSentence) { [weak self] wordIndex in
            Task { @MainActor in
                self?.highlightedWordIndex = wordIndex
            }
        }
    }

    // MARK: - Collect Word
    func collectWord(_ word: String) {
        let cleaned = word.trimmingCharacters(in: .punctuationCharacters).lowercased()
        guard !collectedWords.contains(cleaned) else { return }

        collectedWords.insert(cleaned)
        wordCount += 1
        saveCollectedWords()

        print("⭐ Word collected: \(cleaned) — total: \(wordCount)")
    }

    func isWordCollected(_ word: String) -> Bool {
        collectedWords.contains(word.trimmingCharacters(in: .punctuationCharacters).lowercased())
    }

    // MARK: - Persistence
    private func saveCollectedWords() {
        collectedWordsData = collectedWords.joined(separator: ",")
    }

    private func loadCollectedWords() {
        if !collectedWordsData.isEmpty {
            collectedWords = Set(collectedWordsData.components(separatedBy: ","))
        }
    }

    // MARK: - Fetch Word Definition
    func fetchWordDefinition(for word: String) async -> WordModel? {
        let key = word.lowercased()
        if let cached = wordDefinitionCache[key] {
            return cached
        }
        do {
            let model = try await groqService.generateWordDefinition(word: word)
            wordDefinitionCache[key] = model
            return model
        } catch {
            print("❌ Word definition error: \(error)")
            return nil
        }
    }
}
