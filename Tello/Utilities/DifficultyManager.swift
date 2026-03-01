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
        case .explorer: return 14
        }
    }

    var vocabularyInstruction: String {
        switch self {
        case .beginner:
            return """
            This story is for a 4-6 year old just learning to read.
            STRICT RULES:
            - Use ONLY words a 4 year old already knows (cat, dog,
              big, run, jump, red, blue, happy, sad, fun)
            - Maximum ONE syllable per word wherever possible
            - Each sentence must be 4-6 words maximum
            - No adjectives longer than one syllable
            - No complex sentence structures - subject verb object only
            - Example good sentence: "The dog ran to Jake."
            - Example bad sentence: "The excited puppy bounded over."
            """
        case .explorer:
            return """
            This story is for a 7-11 year old confident reader.
            RULES:
            - Use interesting and descriptive vocabulary
            - Include at least 3 adjectives or adverbs across the story
            - Use varied sentence structures (not just subject verb object)
            - Include at least one complex sentence with 'because',
              'although', 'while', or 'suddenly'
            - Words can be 2-3 syllables (excited, mysterious,
              adventure, discovered, glimmering)
            - Each sentence can be 10-14 words
            - Make the story feel like a real mini adventure with
              a beginning, middle and end
            - Example good sentence: "Suddenly, the mysterious dog
              discovered a glimmering treasure hidden beneath the old oak."
            - Example bad sentence: "The dog found a thing."
            """
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
