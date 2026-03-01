// Purpose: Maps child age to difficulty level and story parameters.

import Foundation

enum DifficultyLevel: String {
    case beginner = "beginner"
    case explorer = "explorer"

    static func from(age: Int) -> DifficultyLevel {
        return age <= 6 ? .beginner : .explorer
    }

    var sentenceCount: Int {
        switch self {
        case .beginner: return 4
        case .explorer: return 6
        }
    }

    var maxWordsPerSentence: Int {
        switch self {
        case .beginner: return 6
        case .explorer: return 12
        }
    }

    var vocabularyInstruction: String {
        switch self {
        case .beginner:
            return "Use ONLY very simple words a 4 year old knows. Maximum one syllable per word where possible. Very short sentences."
        case .explorer:
            return "Use simple words a 7-10 year old knows. Keep sentences clear and fun."
        }
    }

    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .explorer: return "Explorer"
        }
    }

    var ageRange: String {
        switch self {
        case .beginner: return "Ages 4-6"
        case .explorer: return "Ages 7-11"
        }
    }
}
