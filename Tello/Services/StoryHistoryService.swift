// Purpose: Manages saving and loading story history using UserDefaults.

import Foundation

class StoryHistoryService: ObservableObject {

    @Published var entries: [StoryHistoryEntry] = []
    private let storageKey = "storyHistory"
    private let maxEntries = 20

    init() {
        load()
    }

    func save(story: StoryModel) {
        let entry = StoryHistoryEntry(story: story)
        entries.insert(entry, at: 0)
        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }
        persist()
        print("📚 Story saved to history: \(story.title)")
    }

    func delete(entry: StoryHistoryEntry) {
        entries.removeAll { $0.id == entry.id }
        persist()
    }

    func clearAll() {
        entries = []
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(
                [StoryHistoryEntry].self, from: data) else { return }
        entries = decoded
        print("📚 Loaded \(entries.count) stories from history")
    }
}
