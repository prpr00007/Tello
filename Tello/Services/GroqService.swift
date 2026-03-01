// Purpose: Handles all communication with the Groq API.
// Generates personalised stories and word definitions for children.
// Uses llama-3.3-70b-versatile model for fast, high quality generation.

import Foundation

// MARK: - Groq Error
enum GroqError: LocalizedError {
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
            return "Received an empty response."
        }
    }
}

// MARK: - Groq Service
class GroqService {

    // MARK: - Properties
    private let apiKey: String
    private let baseURL = "https://api.groq.com/openai/v1/chat/completions"
    private let model = "llama-3.3-70b-versatile"
    private let session: URLSession

    // Word definition cache — avoids repeated API calls for same word
    private var wordCache: [String: WordModel] = [:]

    // MARK: - Init
    init(apiKey: String = Config.groqAPIKey) {
        self.apiKey = apiKey
        self.session = URLSession.shared
    }

    // MARK: - Generate Story
    /// Generates a short personalised story for a child based on a detected object
    func generateStory(
        object: String,
        childName: String,
        homeLanguage: String
    ) async throws -> StoryModel {

        guard !apiKey.isEmpty && apiKey != "YOUR_GROQ_API_KEY_HERE" else {
            throw GroqError.invalidAPIKey
        }

        let rawLevel = UserDefaults.standard.string(forKey: "difficultyLevel") ?? "explorer"
        let level = DifficultyLevel(rawValue: rawLevel) ?? .explorer

        let languageInstruction = homeLanguage != "English"
            ? "End the story with one sentence translated into \(homeLanguage), labelled '(In \(homeLanguage):)'."
            : ""

        let sentenceList = (1...level.sentenceCount).map { "Sentence \($0)." }.joined(separator: ", ")

        let prompt = """
        You are a friendly storyteller for children aged 5-10.

        Write a short story with EXACTLY \(level.sentenceCount) sentences about a \(object) for a child named \(childName).

        Rules:
        - \(level.vocabularyInstruction)
        - Make it fun, warm, and imaginative
        - Include \(childName)'s name naturally in the story
        - The \(object) must be the main character or central theme
        - Each sentence should be short (maximum \(level.maxWordsPerSentence) words)
        - Return valid JSON only. No trailing commas. No markdown. No backticks. No extra text.
        \(languageInstruction)

        Also provide exactly 5 interesting or important words from the story as keyWords.

        You MUST respond with ONLY valid JSON in this exact format:
        {
          "title": "A short fun story title here",
          "sentences": [\(sentenceList)],
          "keyWords": ["word1", "word2", "word3", "word4", "word5"]
        }
        """

        let responseText = try await callGroq(prompt: prompt)
        let cleaned = cleanJSON(responseText)

        print("📖 Cleaned story JSON: \(cleaned)")

        guard let data = cleaned.data(using: .utf8) else {
            throw GroqError.parsingError("Could not convert response to data")
        }

        do {
            let decoded = try JSONDecoder().decode(GeminiStoryResponse.self, from: data)

            guard decoded.sentences.count == level.sentenceCount else {
                throw GroqError.parsingError("Expected \(level.sentenceCount) sentences, got \(decoded.sentences.count)")
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
            throw GroqError.parsingError(decodingError.localizedDescription)
        }
    }

    // MARK: - Generate Word Definition
    /// Generates a simple definition and SF Symbol for a given word
    func generateWordDefinition(word: String) async throws -> WordModel {

        let cacheKey = word.lowercased()
        if let cached = wordCache[cacheKey] {
            print("📦 Cache hit for word: \(word)")
            return cached
        }

        guard !apiKey.isEmpty && apiKey != "YOUR_GROQ_API_KEY_HERE" else {
            throw GroqError.invalidAPIKey
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

        let responseText = try await callGroq(prompt: prompt)
        let cleaned = cleanJSON(responseText)

        guard let data = cleaned.data(using: .utf8) else {
            throw GroqError.parsingError("Could not convert word response to data")
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
            throw GroqError.parsingError(decodingError.localizedDescription)
        }
    }

    // MARK: - Core API Call
    private func callGroq(prompt: String) async throws -> String {

        guard let url = URL(string: baseURL) else {
            throw GroqError.invalidResponse
        }

        // Build OpenAI-compatible request body
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "temperature": 0.8,
            "max_tokens": 1000
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw GroqError.parsingError("Could not serialize request body")
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw GroqError.networkError(error)
        }

        print("📡 HTTP status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        print("📡 Raw response: \(String(data: data, encoding: .utf8) ?? "nil")")

        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200: break
            case 429: throw GroqError.rateLimited
            case 401, 403: throw GroqError.invalidAPIKey
            default:
                print("❌ HTTP \(httpResponse.statusCode)")
                throw GroqError.invalidResponse
            }
        }

        // Parse OpenAI-compatible response envelope
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let text = message["content"] as? String else {
            print("❌ Could not parse Groq envelope: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw GroqError.emptyResponse
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
        cleaned = cleaned.replacingOccurrences(of: ",\n]", with: "\n]")
        cleaned = cleaned.replacingOccurrences(of: ", ]", with: "]")
        cleaned = cleaned.replacingOccurrences(of: ",]", with: "]")
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
