// Purpose: Stores a record of past generated stories for history view.

import Foundation

struct StoryHistoryEntry: Codable, Identifiable {
    let id: UUID
    let story: StoryModel
    let savedAt: Date

    init(story: StoryModel) {
        self.id = UUID()
        self.story = story
        self.savedAt = Date()
    }
}
