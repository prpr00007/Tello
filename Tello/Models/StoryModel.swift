// Purpose: Represents a generated story with its sentences and key words.

import Foundation

// MARK: - Story Model
struct StoryModel: Codable, Identifiable, Hashable {

    let id: UUID
    let title: String
    let sentences: [String]
    let keyWords: [String]
    let detectedObject: String
    let generatedAt: Date

    // MARK: - Init
    init(title: String, sentences: [String], keyWords: [String], detectedObject: String) {
        self.id = UUID()
        self.title = title
        self.sentences = sentences
        self.keyWords = keyWords
        self.detectedObject = detectedObject
        self.generatedAt = Date()
    }

    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: StoryModel, rhs: StoryModel) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Validation
    var isValid: Bool {
        !title.isEmpty && sentences.count == 6 && !keyWords.isEmpty
    }
}

// MARK: - Gemini Story Response (for JSON parsing)
struct GeminiStoryResponse: Codable {
    let title: String
    let sentences: [String]
    let keyWords: [String]
}
