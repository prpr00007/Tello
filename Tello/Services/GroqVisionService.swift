// Purpose: Uses Groq Vision API to identify objects in captured
// images. Far more accurate than Apple Vision for real world objects.

import UIKit
import Foundation

// MARK: - Groq Vision Response Item (for JSON decoding)
private struct GroqVisionItem: Codable {
    let label: String
    let confidence: Double
}

class GroqVisionService {

    private let apiKey: String
    private let baseURL = "https://api.groq.com/openai/v1/chat/completions"
    private let model = "meta-llama/llama-4-scout-17b-16e-instruct"
    private let session = URLSession.shared

    init(apiKey: String = Config.groqAPIKey) {
        self.apiKey = apiKey
    }

    private func prepareImage(_ image: UIImage) -> Data? {
        // Fix orientation first
        UIGraphicsBeginImageContextWithOptions(image.size, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalised = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let normalisedImage = normalised else { return nil }

        // Resize to max 512px
        let maxDimension: CGFloat = 512
        let scale = min(maxDimension / normalisedImage.size.width,
                        maxDimension / normalisedImage.size.height)
        let newSize = scale < 1 ? CGSize(
            width: normalisedImage.size.width * scale,
            height: normalisedImage.size.height * scale
        ) : normalisedImage.size

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        normalisedImage.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resized?.jpegData(compressionQuality: 0.6)
    }

    // MARK: - Identify Object
    /// Takes a UIImage and returns the top 3 child-friendly
    /// object labels with confidence descriptions
    func identifyObject(image: UIImage) async throws -> [VisionResult] {
        print("👁️ STEP 1 - identifyObject called")

        guard !apiKey.isEmpty && apiKey != "YOUR_GROQ_API_KEY_HERE" else {
            print("👁️ STEP 2 FAILED - invalid API key")
            throw GroqError.invalidAPIKey
        }
        print("👁️ STEP 2 - API key valid")

        guard let imageData = prepareImage(image) else {
            print("👁️ STEP 3 FAILED - could not prepare image")
            throw GroqError.invalidResponse
        }
        print("👁️ STEP 3 - image prepared, \(imageData.count) bytes")

        let base64Image = imageData.base64EncodedString()
        print("👁️ STEP 4 - base64 length: \(base64Image.count)")

        // Build request
        print("👁️ STEP 5 - building request")

        let prompt = """
        Look at this image and identify the most prominent object or subject.

        Return ONLY a JSON array with up to 3 possible objects you can see,
        ordered from most to least prominent.

        Rules:
        - Use simple child-friendly words (dog, cat, apple, book, car)
        - Each label must be 1-3 words maximum
        - First result must be the most obvious/prominent object
        - Confidence must be a number between 0.0 and 1.0
        - No markdown, no backticks, just valid JSON

        Format:
        [
          {"label": "dog", "confidence": 0.95},
          {"label": "grass", "confidence": 0.70},
          {"label": "ball", "confidence": 0.45}
        ]
        """

        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ],
                        [
                            "type": "text",
                            "text": prompt
                        ]
                    ]
                ]
            ],
            "temperature": 0.1,
            "max_tokens": 200
        ]

        guard let url = URL(string: baseURL) else {
            print("👁️ STEP 5 FAILED - invalid URL: \(baseURL)")
            throw GroqError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 20
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("👁️ STEP 5 FAILED - request body serialization: \(error)")
            throw error
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
            print("👁️ STEP 6 - got response")
            print("👁️ STEP 6 - HTTP status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            print("👁️ STEP 6 - raw: \(String(data: data, encoding: .utf8) ?? "nil")")
        } catch {
            print("👁️ STEP 6 FAILED - network error: \(error)")
            throw GroqError.networkError(error)
        }

        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200: break
            case 429:
                print("👁️ STEP 7 FAILED - rate limited")
                throw GroqError.rateLimited
            case 401, 403:
                print("👁️ STEP 7 FAILED - invalid API key (HTTP \(httpResponse.statusCode))")
                throw GroqError.invalidAPIKey
            default:
                print("👁️ STEP 7 FAILED - invalid response HTTP \(httpResponse.statusCode)")
                throw GroqError.invalidResponse
            }
        }

        do {
            // Parse response envelope
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let text = message["content"] as? String else {
                print("👁️ PARSE FAILED - empty or invalid response envelope")
                throw GroqError.emptyResponse
            }

            print("👁️ Vision raw response: \(text)")

            // Clean and parse the JSON array
            let cleaned = cleanJSON(text)
            guard let arrayData = cleaned.data(using: .utf8) else {
                return try parseManually(cleaned)
            }

            do {
                let items = try JSONDecoder().decode([GroqVisionItem].self, from: arrayData)
                let visionResults = items.prefix(3).map { item in
                    VisionResult(
                        label: item.label.lowercased(),
                        rawLabel: item.label,
                        confidence: Float(item.confidence)
                    )
                }
                print("👁️ Vision results: \(visionResults.map { "\($0.label) \($0.confidence)" })")
                return Array(visionResults)
            } catch {
                return try parseManually(cleaned)
            }
        } catch {
            print("👁️ PARSE ERROR: \(error)")
            print("👁️ PARSE ERROR TYPE: \(type(of: error))")
            throw error
        }
    }

    // MARK: - Manual Parser fallback
    private func parseManually(_ text: String) throws -> [VisionResult] {
        var results: [VisionResult] = []
        // Try to find "label":"...", "confidence":0.xx patterns
        let labelPattern = #""label"\s*:\s*"([^"]+)""#
        let confidencePattern = #""confidence"\s*:\s*([0-9.]+)"#
        guard let labelRegex = try? NSRegularExpression(pattern: labelPattern),
              let confidenceRegex = try? NSRegularExpression(pattern: confidencePattern) else {
            throw GroqError.parsingError("Could not parse vision response")
        }
        let labelMatches = labelRegex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        let confidenceMatches = confidenceRegex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        let minCount = min(labelMatches.count, confidenceMatches.count)
        for i in 0..<minCount {
            guard i < labelMatches.count, i < confidenceMatches.count,
                  let labelRange = Range(labelMatches[i].range(at: 1), in: text),
                  let confRange = Range(confidenceMatches[i].range(at: 1), in: text),
                  let conf = Float(String(text[confRange])) else { continue }
            let label = String(text[labelRange]).trimmingCharacters(in: .whitespaces)
            results.append(VisionResult(
                label: label.lowercased(),
                rawLabel: label,
                confidence: conf
            ))
        }
        if results.isEmpty {
            throw GroqError.parsingError("Could not parse vision response")
        }
        return Array(results.prefix(3))
    }

    // MARK: - JSON Cleaner
    private func cleanJSON(_ raw: String) -> String {
        var cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```json") { cleaned = String(cleaned.dropFirst(7)) }
        else if cleaned.hasPrefix("```") { cleaned = String(cleaned.dropFirst(3)) }
        if cleaned.hasSuffix("```") { cleaned = String(cleaned.dropLast(3)) }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
