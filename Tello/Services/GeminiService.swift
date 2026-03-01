// Purpose: Handles all communication with the Google Gemini API.
// Generates personalised stories and word definitions for children.

import Foundation

// MARK: - Gemini Error
enum GeminiError: LocalizedError {
    case invalidAPIKey
    case networkError(Error)
    case invalidResponse
    case parsingError(String)
    case rateLimited
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "API key is missing or invalid."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Received an unexpected response."
        case .parsingError(let detail):
            return "Could not parse response: \(detail)"
        case .rateLimited:
            return "Too many requests. Please try again in a moment."
        case .emptyResponse:
            return "Received an empty response from Gemini."
        }
    }
}

// MARK: - Gemini Service
class GeminiService {

    // MARK: - Properties
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"
    private let session: URLSession

    private var wordCache: [String: WordModel] = [:]

    // MARK: - Init
    init(apiKey: String = Config.geminiAPIKey) {
        self.apiKey = apiKey
        self.session = URLSession.shared
    }

    // MARK: - Generate Story
    func generateStory(
        object: String,
        childName: String,
        homeLanguage: String
    ) async throws -> StoryModel {

        guard !apiKey.isEmpty && apiKey != "YOUR_GEMINI_API_KEY_HERE" else {
            throw GeminiError.invalidAPIKey
        }

        let languageInstruction = homeLanguage != "English"
            ? "End the story with one sentence translated into \(homeLanguage), labelled '(In \(homeLanguage):)'."
            : ""

        let prompt = """
        You are a friendly storyteller for children aged 5-10.
        
        Write a short story with EXACTLY 6 sentences about a \(object) for a child named \(childName).
        
        Rules:
        - Use simple words (maximum 2 syllables where possible)
        - Make it fun, warm, and imaginative
        - Include \(childName)'s name naturally in the story
        - The \(object) must be the main character or central theme
        - Each sentence should be short (maximum 12 words)
        \(languageInstruction)
        
        Also provide exactly 5 interesting or important words from the story as keyWords.
        
        You MUST respond with ONLY valid JSON in this exact format, no other text, no markdown, no backticks:
        {
          "title": "A short fun story title here",
          "sentences": ["Sentence 1.", "Sentence 2.", "Sentence 3.", "Sentence 4.", "Sentence 5.", "Sentence 6."],
          "keyWords": ["word1", "word2", "word3", "word4", "word5"]
        }
        """

        let responseText = try await callGemini(prompt: prompt)
        let cleaned = cleanJSON(responseText)

        guard let data = cleaned.data(using: .utf8) else {
            throw GeminiError.parsingError("Could not convert response to data")
        }

        do {
            let decoded = try JSONDecoder().decode(GeminiStoryResponse.self, from: data)

            guard decoded.sentences.count == 6 else {
                throw GeminiError.parsingError("Expected 6 sentences, got \(decoded.sentences.count)")
            }

            let story = StoryModel(
                title: decoded.title,
                sentences: decoded.sentences,
                keyWords: decoded.keyWords,
                detectedObject: object
            )

            print("✅ Story generated: \"\(story.title)\" with \(story.sentences.count) sentences")
            return story

        } catch let decodingError as DecodingError {
            print("❌ Parsing error: \(decodingError)")
            print("❌ Raw response: \(responseText)")
            throw GeminiError.parsingError(decodingError.localizedDescription)
        }
    }

    // MARK: - Generate Word Definition
    func generateWordDefinition(word: String) async throws -> WordModel {

        let cacheKey = word.lowercased()
        if let cached = wordCache[cacheKey] {
            print("📦 Cache hit for word: \(word)")
            return cached
        }

        guard !apiKey.isEmpty && apiKey != "YOUR_GEMINI_API_KEY_HERE" else {
            throw GeminiError.invalidAPIKey
        }

        let prompt = """
        You are helping a child aged 5-10 understand a word.
        
        Word: "\(word)"
        
        Provide:
        1. A simple one-sentence definition a 6-year-old can understand (maximum 15 words)
        2. The name of ONE Apple SF Symbol that best represents this word visually
        
        For the SF Symbol, use only common, widely available symbols like:
        sun.max.fill, moon.fill, star.fill, heart.fill, house.fill, car.fill,
        airplane, book.fill, music.note, camera.fill, tree.fill, leaf.fill,
        drop.fill, flame.fill, bolt.fill, cloud.fill, globe, pawprint.fill,
        figure.walk, bicycle, fork.knife, cup.and.saucer.fill, gift.fill,
        pencil, paintbrush.fill, scissors, magnifyingglass, bell.fill,
        flag.fill, map.fill, clock.fill, calendar, bag.fill, cart.fill
        
        You MUST respond with ONLY valid JSON, no other text, no markdown, no backticks:
        {
          "definition": "Simple definition here.",
          "sfSymbol": "symbol.name.here"
        }
        """

        let responseText = try await callGemini(prompt: prompt)
        let cleaned = cleanJSON(responseText)

        guard let data = cleaned.data(using: .utf8) else {
            throw GeminiError.parsingError("Could not convert word response to data")
        }

        do {
            let decoded = try JSONDecoder().decode(GeminiWordResponse.self, from: data)
            let wordModel = WordModel(
                word: word,
                definition: decoded.definition,
                sfSymbol: decoded.sfSymbol
            )

            wordCache[cacheKey] = wordModel
            print("✅ Word definition generated for: \(word) — \(decoded.sfSymbol)")
            return wordModel

        } catch let decodingError as DecodingError {
            print("❌ Word parsing error: \(decodingError)")
            throw GeminiError.parsingError(decodingError.localizedDescription)
        }
    }

    // MARK: - Core API Call
    private func callGemini(prompt: String) async throws -> String {
        let urlString = "\(baseURL)?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw GeminiError.invalidResponse
        }

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.8,
                "maxOutputTokens": 1000,
                "topP": 0.9
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw GeminiError.parsingError("Could not serialize request body")
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw GeminiError.networkError(error)
        }

        print("📡 Raw response: \(String(data: data, encoding: .utf8) ?? "nil")")
        print("📡 HTTP status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")

        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200: break
            case 429: throw GeminiError.rateLimited
            case 401, 403: throw GeminiError.invalidAPIKey
            default:
                print("❌ HTTP \(httpResponse.statusCode)")
                throw GeminiError.invalidResponse
            }
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            print("❌ Could not parse Gemini envelope: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw GeminiError.emptyResponse
        }

        return text
    }

    // MARK: - JSON Cleaner
    private func cleanJSON(_ raw: String) -> String {
        var cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
