// Purpose: Animated loading screen shown while Gemini generates the story.
// Shows multi-stage progress and handles success/error states.

import SwiftUI

// MARK: - Loading View
struct LoadingView: View {

    let detectedObject: String
    let childName: String
    @Binding var navigationPath: NavigationPath

    @EnvironmentObject var fontManager: FontManager
    @StateObject private var viewModel: LoadingViewModel

    init(detectedObject: String, childName: String, navigationPath: Binding<NavigationPath>) {
        self.detectedObject = detectedObject
        self.childName = childName
        _navigationPath = navigationPath
        _viewModel = StateObject(wrappedValue: LoadingViewModel(
            detectedObject: detectedObject,
            childName: childName
        ))
    }

    var body: some View {
        let _ = print("🎬 LoadingView body rendered")
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#B8E4F7"), Color(hex: "#F0F7EE")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            FloatingShapeBackground()

            VStack(spacing: 40) {

                // Home button
                HStack {
                    Button {
                        navigationPath = NavigationPath()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "house.fill")
                            Text("Home")
                        }
                        .font(fontManager.uiFont(size: 17, weight: .semibold))
                        .foregroundColor(Color("AppPrimary"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color("AppPrimary").opacity(0.1))
                        .cornerRadius(20)
                    }
                    .frame(minHeight: 44)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)

                Spacer()

                VStack(spacing: 12) {
                    Text("Creating your story,")
                        .font(fontManager.storyFont(size: 26))
                        .foregroundColor(Color("AppSecondaryText"))

                    Text(childName)
                        .font(fontManager.storyFontBold(size: 36))
                        .foregroundColor(Color("AppText"))
                }

                VStack(spacing: 16) {
                    ForEach(LoadingStage.allCases, id: \.rawValue) { stage in
                        LoadingStageRow(
                            stage: stage,
                            isActive: viewModel.currentStage == stage,
                            isComplete: viewModel.currentStage.rawValue > stage.rawValue,
                            fontManager: fontManager
                        )
                    }
                }
                .frame(maxWidth: 500)
                .roundedCard()

                if viewModel.showSlowMessage {
                    Text("Almost there... good stories take a moment.")
                        .font(fontManager.storyFont(size: 18))
                        .foregroundColor(Color("AppSecondaryText"))
                        .multilineTextAlignment(.center)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer()
            }
            .padding(.horizontal, 40)
            .frame(maxWidth: 700)

            if let error = viewModel.errorMessage {
                errorOverlay(message: error)
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.generateStory()
        }
        .onDisappear {
            viewModel.cancel()
        }
        .onChange(of: viewModel.generatedStory) { _, newValue in
            if let story = newValue {
                navigationPath.append(story)
            }
        }
    }

    func errorOverlay(message: String) -> some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Something went wrong")
                    .font(fontManager.storyFontBold(size: 24))
                    .foregroundColor(Color("AppText"))

                Text(message)
                    .font(fontManager.storyFont(size: 18))
                    .foregroundColor(Color("AppSecondaryText"))
                    .multilineTextAlignment(.center)

                PrimaryButton(label: "Try Again", icon: "arrow.clockwise") {
                    Task { await viewModel.generateStory() }
                }
                .frame(maxWidth: 300)
            }
            .padding(32)
            .background(Color("AppCardBackground"))
            .cornerRadius(24)
            .shadow(color: Color(hex: "#2C1810").opacity(0.08), radius: 12)
            .padding(40)
        }
    }
}

// MARK: - Loading Stage Row
private struct LoadingStageRow: View {

    let stage: LoadingStage
    let isActive: Bool
    let isComplete: Bool
    let fontManager: FontManager

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isComplete ? Color("AppSuccess") : isActive ? Color("AppPrimary") : Color("AppSecondaryText").opacity(0.2))
                    .frame(width: 44, height: 44)

                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                } else if isActive {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: stage.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color("AppSecondaryText"))
                }
            }

            Text(stage.label)
                .font(fontManager.storyFont(size: 20))
                .foregroundColor(isActive ? Color("AppText") : Color("AppSecondaryText"))

            Spacer()
        }
        .opacity(isActive || isComplete ? 1.0 : 0.5)
        .animation(.easeInOut(duration: 0.3), value: isActive)
        .animation(.easeInOut(duration: 0.3), value: isComplete)
    }
}

// MARK: - Floating Shape Background
private struct FloatingShapeBackground: View {

    @State private var positions: [(x: CGFloat, y: CGFloat)] = []
    @State private var sizes: [CGFloat] = []
    @State private var offsets: [CGSize] = Array(repeating: .zero, count: 8)
    @State private var opacities: [Double] = Array(repeating: 0, count: 8)
    @State private var hasAnimated = false

    var body: some View {
        GeometryReader { geo in
            ForEach(Array(positions.enumerated()), id: \.offset) { i, pos in
                Circle()
                    .fill(Color("AppPrimary").opacity(0.08))
                    .frame(width: sizes.count > i ? sizes[i] : 60, height: sizes.count > i ? sizes[i] : 60)
                    .position(x: pos.x, y: pos.y)
                    .offset(offsets.count > i ? offsets[i] : .zero)
                    .opacity(opacities.count > i ? opacities[i] : 0)
            }
            .onAppear {
                if positions.isEmpty && geo.size.width > 0 {
                    positions = (0..<8).map { _ in (CGFloat.random(in: 0...geo.size.width), CGFloat.random(in: 0...geo.size.height)) }
                    sizes = (0..<8).map { _ in CGFloat.random(in: 40...80) }
                    startAnimations()
                }
            }
            .onChange(of: geo.size.width) { _, _ in
                if positions.isEmpty && geo.size.width > 0 {
                    positions = (0..<8).map { _ in (CGFloat.random(in: 0...geo.size.width), CGFloat.random(in: 0...geo.size.height)) }
                    sizes = (0..<8).map { _ in CGFloat.random(in: 40...80) }
                    startAnimations()
                }
            }
        }
        .ignoresSafeArea()
    }

    private func startAnimations() {
        guard !hasAnimated else { return }
        hasAnimated = true
        for i in 0..<8 {
            let delay = Double(i) * 0.2
            withAnimation(.easeIn(duration: 0.5).delay(delay)) {
                opacities[i] = Double.random(in: 0.3...0.6)
            }
            withAnimation(
                .easeInOut(duration: Double.random(in: 3...6))
                .repeatForever(autoreverses: true)
                .delay(delay)
            ) {
                offsets[i] = CGSize(
                    width: CGFloat.random(in: -30...30),
                    height: CGFloat.random(in: -40...(-10))
                )
            }
        }
    }
}

#Preview {
    LoadingView(detectedObject: "dog", childName: "Jake", navigationPath: .constant(NavigationPath()))
        .environmentObject(FontManager())
}
