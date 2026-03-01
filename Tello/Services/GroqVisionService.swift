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
    private let model = "llama-3.2-11b-vision-preview"
    private let session = URLSession.shared

    init(apiKey: String = Config.groqAPIKey) {
        self.apiKey = apiKey
    }

    private func resizeImage(_ image: UIImage, maxDimension: CGFloat = 640) -> UIImage {
        let size = image.size
        let ratio = min(maxDimension / size.width, maxDimension / size.height)

        // Only resize if image is larger than maxDimension
        guard ratio < 1 else { return image }

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // MARK: - Identify Object
    /// Takes a UIImage and returns the top 3 child-friendly
    /// object labels with confidence descriptions
    func identifyObject(image: UIImage) async throws -> [VisionResult] {

        print("👁️ VISION SERVICE CALLED")
        print("👁️ identifyObject called")
        print("👁️ API key valid: \(!apiKey.isEmpty && apiKey != "YOUR_GROQ_API_KEY_HERE")")

        guard !apiKey.isEmpty && apiKey != "YOUR_GROQ_API_KEY_HERE" else {
            throw GroqError.invalidAPIKey
        }
        print("👁️ API key check passed")

        let resized = resizeImage(image, maxDimension: 640)
        print("👁️ Original size: \(image.size), Resized: \(resized.size)")

        // Convert image to base64
        guard let imageData = resized.jpegData(compressionQuality: 0.5) else {
            throw GroqError.invalidResponse
        }
        let base64Image = imageData.base64EncodedString()
        print("👁️ JPEG size: \(imageData.count) bytes, Base64: \(base64Image.count) chars")

        print("👁️ Starting vision detection...")

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
        print("👁️ Request body built")

        guard let url = URL(string: baseURL) else {
            throw GroqError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 20
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        print("👁️ Sending request to: \(baseURL)")
        let (data, response) = try await session.data(for: request)
        print("👁️ Response received")

        print("👁️ Raw data length: \(data.count)")
        print("👁️ Raw response string: \(String(data: data, encoding: .utf8) ?? "nil")")
        print("👁️ Full response data: \(String(data: data, encoding: .utf8) ?? "nil")")
        print("👁️ Vision HTTP status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")

        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200: break
            case 429: throw GroqError.rateLimited
            case 401, 403: throw GroqError.invalidAPIKey
            default: throw GroqError.invalidResponse
            }
        }

        do {
            // Parse response envelope
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let text = message["content"] as? String else {
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
