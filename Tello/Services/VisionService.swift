// Purpose: Wraps Apple's Vision framework to classify objects in a captured image.
// Returns child-friendly labels mapped from Vision's technical classifications.

import Vision
import UIKit

// MARK: - Vision Result Model
struct VisionResult {
    let label: String           // Child-friendly label e.g. "dog"
    let rawLabel: String        // Original Vision label e.g. "Golden Retriever"
    let confidence: Float       // 0.0 to 1.0
}

// MARK: - Vision Service
class VisionService {

    // MARK: - Child-Friendly Label Mapping
    // Maps Vision's technical/scientific labels to simple child-friendly words
    private let labelMap: [String: String] = [
        // Animals
        "dog": "dog", "cat": "cat", "bird": "bird", "fish": "fish",
        "horse": "horse", "cow": "cow", "sheep": "sheep", "elephant": "elephant",
        "lion": "lion", "tiger": "tiger", "bear": "bear", "rabbit": "rabbit",
        "duck": "duck", "chicken": "chicken", "frog": "frog", "butterfly": "butterfly",
        "golden retriever": "dog", "labrador retriever": "dog", "german shepherd": "dog",
        "domestic cat": "cat", "tabby cat": "cat", "siamese cat": "cat",
        "african elephant": "elephant", "polar bear": "bear", "brown bear": "bear",

        // Food & Drink
        "apple": "apple", "banana": "banana", "orange": "orange", "strawberry": "strawberry",
        "pizza": "pizza", "hamburger": "burger", "hot dog": "hot dog", "sandwich": "sandwich",
        "cake": "cake", "ice cream": "ice cream", "cookie": "cookie", "bread": "bread",
        "coffee": "coffee", "milk": "milk", "juice": "juice", "water bottle": "water bottle",
        "malus domestica": "apple", "musa": "banana", "citrus sinensis": "orange",

        // Vehicles
        "car": "car", "truck": "truck", "bus": "bus", "bicycle": "bicycle",
        "motorcycle": "motorbike", "airplane": "aeroplane", "boat": "boat",
        "train": "train", "ambulance": "ambulance", "fire engine": "fire truck",

        // Nature
        "tree": "tree", "flower": "flower", "grass": "grass", "sun": "sun",
        "cloud": "cloud", "mountain": "mountain", "beach": "beach", "river": "river",
        "rock": "rock", "leaf": "leaf", "rose": "flower", "daisy": "flower",
        "sunflower": "sunflower", "oak tree": "tree", "palm tree": "palm tree",

        // Objects & Household
        "book": "book", "chair": "chair", "table": "table", "lamp": "lamp",
        "phone": "phone", "laptop": "laptop", "television": "television",
        "ball": "ball", "toy": "toy", "cup": "cup", "bottle": "bottle",
        "bag": "bag", "shoe": "shoe", "hat": "hat", "clock": "clock",
        "pencil": "pencil", "pen": "pen", "scissors": "scissors",

        // Sports & Activities
        "football": "football", "basketball": "basketball", "tennis ball": "tennis ball",
        "skateboard": "skateboard", "guitar": "guitar", "piano": "piano",

        // Places & Buildings
        "house": "house", "school": "school", "park": "park", "playground": "playground",
        "bridge": "bridge", "castle": "castle"
    ]

    // MARK: - Normalise orientation (rotate to .up before cropping)
    private func normaliseOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalised = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalised ?? image
    }

    // MARK: - Crop to Center
    private func cropToCenter(image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }

        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)

        // Crop to centre square
        let size = min(width, height)
        let x = (width - size) / 2
        let y = (height - size) / 2

        let cropRect = CGRect(x: x, y: y, width: size, height: size)

        guard let cropped = cgImage.cropping(to: cropRect) else { return image }
        return UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
    }

    // MARK: - Classify Image
    /// Classifies a UIImage and returns up to 3 results sorted by confidence
    func classify(image: UIImage) async throws -> [VisionResult] {
        let normalised = normaliseOrientation(image)
        let croppedImage = cropToCenter(image: normalised)
        guard let cgImage = croppedImage.cgImage else {
            throw VisionError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                // Filter to confidence > 0.05 and take top 8
                let filtered = observations
                    .filter { $0.confidence > 0.05 }
                    .prefix(8)

                // Map to VisionResult with child-friendly labels
                let results = filtered.compactMap { observation -> VisionResult? in
                    let raw = observation.identifier.lowercased()
                    // Try to find a friendly label - check if any key is contained in the raw label
                    let friendlyLabel = self.labelMap[raw]
                        ?? self.labelMap.first(where: { raw.contains($0.key) })?.value
                        ?? self.cleanLabel(raw)

                    return VisionResult(
                        label: friendlyLabel,
                        rawLabel: observation.identifier,
                        confidence: observation.confidence
                    )
                }

                // Deduplicate by friendly label (keep highest confidence)
                var seen = Set<String>()
                let deduped = results.filter { result in
                    if seen.contains(result.label) { return false }
                    seen.insert(result.label)
                    return true
                }

                continuation.resume(returning: Array(deduped.prefix(3)))
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Clean Label Helper
    /// Converts a raw Vision label into a readable string as fallback
    private func cleanLabel(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .components(separatedBy: ",")
            .first?
            .trimmingCharacters(in: .whitespaces)
            .capitalized ?? raw
    }
}

// MARK: - Vision Error
enum VisionError: LocalizedError {
    case invalidImage
    case noResults

    var errorDescription: String? {
        switch self {
        case .invalidImage: return "Could not process the image."
        case .noResults: return "No objects were recognised."
        }
    }
}
