// Purpose: Represents a word with its definition, symbol, and collection status.

import Foundation

// MARK: - Word Model
struct WordModel: Codable, Identifiable {

    let id: UUID
    let word: String
    let definition: String
    let sfSymbol: String
    var isCollected: Bool
    var collectedAt: Date?

    // MARK: - Init
    init(word: String, definition: String, sfSymbol: String) {
        self.id = UUID()
        self.word = word
        self.definition = definition
        self.sfSymbol = sfSymbol
        self.isCollected = false
        self.collectedAt = nil
    }
}

// MARK: - Gemini Word Response (for JSON parsing)
struct GeminiWordResponse: Codable {
    let definition: String
    let sfSymbol: String
}
