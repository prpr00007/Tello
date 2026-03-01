// Purpose: Displays a grid of past generated stories the child
// can revisit and re-read.

import SwiftUI

struct PastStoriesView: View {

    @EnvironmentObject var fontManager: FontManager
    @StateObject private var historyService = StoryHistoryService()
    @State private var selectedStory: StoryModel? = nil
    @State private var showClearConfirm = false
    @Environment(\.dismiss) var dismiss

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ZStack {
            Color("AppBackground").ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .semibold))
                            Text("Home")
                                .font(fontManager.uiFont(size: 17, weight: .semibold))
                        }
                        .foregroundColor(Color("AppPrimary"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color("AppPrimary").opacity(0.1))
                        .cornerRadius(20)
                    }

                    Spacer()

                    Text("Past Stories")
                        .font(fontManager.storyFontBold(size: 26))
                        .foregroundColor(Color("AppText"))

                    Spacer()

                    if !historyService.entries.isEmpty {
                        Button {
                            showClearConfirm = true
                        } label: {
                            Text("Clear All")
                                .font(fontManager.uiFont(size: 15))
                                .foregroundColor(Color("AppSecondaryText"))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color("AppCardBackground"))
                                .cornerRadius(20)
                        }
                    } else {
                        Color.clear.frame(width: 100)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)
                .padding(.bottom, 16)

                if historyService.entries.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(historyService.entries) { entry in
                                StoryHistoryCard(
                                    entry: entry,
                                    fontManager: fontManager
                                ) {
                                    selectedStory = entry.story
                                } onDelete: {
                                    historyService.delete(entry: entry)
                                }
                            }
                        }
                        .padding(32)
                    }
                }
            }
            .frame(maxWidth: 1000)
            .frame(maxWidth: .infinity)
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: Binding(
            get: { selectedStory != nil },
            set: { if !$0 { selectedStory = nil } }
        )) {
            if let story = selectedStory {
                StoryView(story: story, navigationPath: .constant(NavigationPath()))
                    .navigationBarHidden(true)
            }
        }
        .confirmationDialog(
            "Clear all past stories?",
            isPresented: $showClearConfirm,
            titleVisibility: .visible
        ) {
            Button("Clear All", role: .destructive) {
                historyService.clearAll()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(Color("AppSecondaryText").opacity(0.4))
            Text("No stories yet!")
                .font(fontManager.storyFontBold(size: 28))
                .foregroundColor(Color("AppText"))
            Text("Go point your camera at something\nto create your first story.")
                .font(fontManager.storyFont(size: 18))
                .foregroundColor(Color("AppSecondaryText"))
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

// MARK: - Story History Card
struct StoryHistoryCard: View {

    let entry: StoryHistoryEntry
    let fontManager: FontManager
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var isPressed = false

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: entry.savedAt)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {

                // Object icon area
                HStack {
                    Text(entry.story.detectedObject.capitalized)
                        .font(fontManager.uiFont(size: 13, weight: .semibold))
                        .foregroundColor(Color("AppPrimary"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color("AppPrimary").opacity(0.1))
                        .cornerRadius(10)

                    Spacer()

                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color("AppSecondaryText").opacity(0.5))
                    }
                }

                // Story title
                Text(entry.story.title)
                    .font(fontManager.storyFontBold(size: 18))
                    .foregroundColor(Color("AppText"))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // First sentence preview
                Text(entry.story.sentences.first ?? "")
                    .font(fontManager.storyFont(size: 14))
                    .foregroundColor(Color("AppSecondaryText"))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer()

                // Date
                Text(formattedDate)
                    .font(fontManager.uiFont(size: 12))
                    .foregroundColor(Color("AppSecondaryText").opacity(0.7))
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
            .background(Color("AppCardBackground"))
            .cornerRadius(20)
            .shadow(color: Color(hex: "#2E3D2F").opacity(0.06), radius: 10)
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
