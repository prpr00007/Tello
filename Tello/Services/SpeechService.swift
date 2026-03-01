// Purpose: Wraps AVSpeechSynthesizer to provide text-to-speech functionality.
// Supports single word speaking and full sentence reading with word highlighting.

import AVFoundation
import SwiftUI

// MARK: - Speech Service
@MainActor
class SpeechService: NSObject, ObservableObject {

    // MARK: - Published
    @Published var isSpeaking = false
    @Published var highlightedWordIndex: Int? = nil

    // MARK: - Private
    private let synthesizer = AVSpeechSynthesizer()
    private var onWordHighlight: ((Int) -> Void)?
    private var words: [String] = []

    // MARK: - Init
    override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Speak Single Word
    func speak(word: String, language: String = "en-US") {
        synthesizer.stopSpeaking(at: .immediate)
        highlightedWordIndex = nil

        let utterance = AVSpeechUtterance(string: word)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.4
        utterance.pitchMultiplier = 1.1
        utterance.volume = 1.0

        isSpeaking = true
        synthesizer.speak(utterance)
    }

    // MARK: - Speak Full Sentence
    func speakSentence(_ sentence: String, onWordHighlight: @escaping (Int) -> Void) {
        synthesizer.stopSpeaking(at: .immediate)

        self.words = sentence.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        self.onWordHighlight = onWordHighlight
        self.highlightedWordIndex = nil

        let utterance = AVSpeechUtterance(string: sentence)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.38
        utterance.pitchMultiplier = 1.05
        utterance.volume = 1.0

        isSpeaking = true
        synthesizer.speak(utterance)
    }

    // MARK: - Stop
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        highlightedWordIndex = nil
        onWordHighlight = nil
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension SpeechService: AVSpeechSynthesizerDelegate {

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                        willSpeakRangeOfSpeechString characterRange: NSRange,
                                        utterance: AVSpeechUtterance) {
        // Find which word index corresponds to this character range
        let text = utterance.speechString
        let spokenSoFar = (text as NSString).substring(to: characterRange.location)
        let wordIndex = spokenSoFar.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }.count

        Task { @MainActor in
            self.highlightedWordIndex = wordIndex
            self.onWordHighlight?(wordIndex)
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                        didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.highlightedWordIndex = nil
            self.onWordHighlight = nil
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                        didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.highlightedWordIndex = nil
        }
    }
}
