// Purpose: Manages story generation state and loading stage progression
// for the LoadingView.

import SwiftUI

// MARK: - Loading Stage (shared with LoadingView)
enum LoadingStage: Int, CaseIterable, Comparable {

    case reading = 0
    case writing = 1
    case magic = 2

    var label: String {
        switch self {
        case .reading: return "Reading the picture..."
        case .writing: return "Writing your story..."
        case .magic: return "Adding the magic..."
        }
    }

    var icon: String {
        switch self {
        case .reading: return "magnifyingglass"
        case .writing: return "pencil"
        case .magic: return "paintbrush.fill"
        }
    }

    static func < (lhs: LoadingStage, rhs: LoadingStage) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Loading View Model
@MainActor
class LoadingViewModel: ObservableObject {

    // MARK: - Published
    @Published var currentStage: LoadingStage = .reading
    @Published var generatedStory: StoryModel?
    @Published var errorMessage: String?
    @Published var showSlowMessage = false

    // MARK: - Properties
    let detectedObject: String
    let childName: String

    @AppStorage("homeLanguage") private var homeLanguage = "English"

    private let geminiService = GeminiService()
    private var stageTimer: Task<Void, Never>?
    private var slowTimer: Task<Void, Never>?

    // MARK: - Init
    init(detectedObject: String, childName: String) {
        self.detectedObject = detectedObject
        self.childName = childName
    }

    // MARK: - Generate Story
    func generateStory() async {
        errorMessage = nil
        generatedStory = nil
        currentStage = .reading
        showSlowMessage = false

        startStageTimer()

        slowTimer = Task {
            try? await Task.sleep(nanoseconds: 8_000_000_000)
            if !Task.isCancelled {
                withAnimation { showSlowMessage = true }
            }
        }

        do {
            let story = try await geminiService.generateStory(
                object: detectedObject,
                childName: childName,
                homeLanguage: homeLanguage
            )

            stageTimer?.cancel()
            slowTimer?.cancel()

            withAnimation { currentStage = .magic }
            try? await Task.sleep(nanoseconds: 800_000_000)

            generatedStory = story

        } catch {
            stageTimer?.cancel()
            slowTimer?.cancel()

            print("❌ Full error: \(error)")
            print("❌ Error type: \(type(of: error))")
            print("❌ Localized: \(error.localizedDescription)")

            let message: String
            if let geminiError = error as? GeminiError {
                switch geminiError {
                case .invalidAPIKey:
                    message = "API key not set up yet. Add your Gemini API key to Config.swift."
                case .rateLimited:
                    message = "Too many requests! Wait a moment and try again."
                case .networkError:
                    message = "No internet connection. Check your Wi-Fi and try again!"
                default:
                    message = "Something went wrong making your story. Try again!"
                }
            } else {
                message = "Something went wrong. Try again!"
            }

            withAnimation { errorMessage = message }
            print("❌ Story generation error: \(error)")
        }
    }

    // MARK: - Stage Timer
    private func startStageTimer() {
        stageTimer = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if !Task.isCancelled {
                withAnimation { currentStage = .writing }
            }

            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if !Task.isCancelled {
                withAnimation { currentStage = .magic }
            }
        }
    }
}
