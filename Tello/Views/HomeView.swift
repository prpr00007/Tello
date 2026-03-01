// Purpose: Home screen and main hub for Tello.
// Greets the child, shows word jar progress, and provides
// navigation to the camera and word jar.

import SwiftUI

struct HomeView: View {

    @EnvironmentObject var fontManager: FontManager
    @AppStorage("childName") private var childName = ""
    @AppStorage("wordCount") private var wordCount = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var navigationPath = NavigationPath()
    @State private var cloud1Offset: CGFloat = -200
    @State private var cloud2Offset: CGFloat = -400
    @State private var cloud3Offset: CGFloat = -100
    @State private var titleScale: CGFloat = 0.8
    @State private var titleOpacity: CGFloat = 0
    @State private var contentOpacity: CGFloat = 0

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {

                // MARK: - Landscape Background
                LandscapeBackground(
                    cloud1Offset: cloud1Offset,
                    cloud2Offset: cloud2Offset,
                    cloud3Offset: cloud3Offset
                )

                // MARK: - Main Content
                VStack(spacing: 0) {

                    // Top bar
                    topBar

                    Spacer()

                    // Centre content
                    centreContent

                    Spacer()

                    // Bottom actions
                    bottomActions
                        .padding(.bottom, 48)
                }
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
            .ignoresSafeArea()
            .navigationBarHidden(true)
            .navigationDestination(for: String.self) { destination in
                if destination == "camera" {
                    CameraView(navigationPath: $navigationPath)
                        .navigationBarHidden(true)
                } else if destination == "wordjar" {
                    WordJarView()
                        .navigationBarHidden(true)
                } else {
                    LoadingView(detectedObject: destination, childName: childName, navigationPath: $navigationPath)
                        .navigationBarHidden(true)
                }
            }
            .navigationDestination(for: StoryModel.self) { story in
                StoryView(story: story, navigationPath: $navigationPath)
                    .navigationBarHidden(true)
            }
            .onAppear {
                startAnimations()
            }
        }
    }

    // MARK: - Top Bar
    var topBar: some View {
        HStack {
            // Tello logo + greeting
            VStack(alignment: .leading, spacing: 4) {
                Text("Tello")
                    .font(fontManager.storyFontBold(size: 32))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.2), radius: 4)

                Text("Hi, \(childName)! 👋")
                    .font(fontManager.storyFont(size: 20))
                    .foregroundColor(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.2), radius: 3)
            }

            Spacer()

            // Word jar teaser
            Button {
                navigationPath.append("wordjar")
            } label: {
                HStack(spacing: 10) {
                    Text("🫙")
                        .font(.system(size: 24))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(wordCount) words")
                            .font(fontManager.uiFont(size: 16, weight: .bold))
                            .foregroundColor(Color("AppText"))
                        Text("in your jar")
                            .font(fontManager.uiFont(size: 13))
                            .foregroundColor(Color("AppSecondaryText"))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
            }
            .accessibilityLabel("Word jar, \(wordCount) words collected")

            // Settings
            Button {
                // Settings — Stage 8
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(.ultraThinMaterial)
                    .cornerRadius(24)
            }
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, 36)
        .padding(.top, 36)
        .opacity(contentOpacity)
    }

    // MARK: - Centre Content
    var centreContent: some View {
        VStack(spacing: 28) {

            // Main illustration / icon
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 160, height: 160)

                Text("📖")
                    .font(.system(size: 80))
            }
            .scaleEffect(titleScale)
            .opacity(titleOpacity)

            // Tagline
            VStack(spacing: 10) {
                Text("What will you discover")
                    .font(fontManager.storyFont(size: 28))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4)

                Text("today, \(childName)?")
                    .font(fontManager.storyFontBold(size: 34))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4)
            }
            .opacity(titleOpacity)

            // Big CTA Button
            Button {
                navigationPath.append("camera")
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 24, weight: .semibold))
                    Text("Start a Story!")
                        .font(fontManager.storyFontBold(size: 26))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 48)
                .padding(.vertical, 22)
                .background(
                    LinearGradient(
                        colors: [Color("AppPrimary"), Color("AppPrimary").opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(28)
                .shadow(color: Color("AppPrimary").opacity(0.5), radius: 16, x: 0, y: 8)
            }
            .scaleEffect(titleScale)
            .opacity(titleOpacity)
            .accessibilityLabel("Start a story — opens camera")
        }
    }

    // MARK: - Bottom Actions
    var bottomActions: some View {
        HStack(spacing: 20) {

            // Word Jar button
            Button {
                navigationPath.append("wordjar")
            } label: {
                HStack(spacing: 10) {
                    Text("🫙")
                        .font(.system(size: 22))
                    Text("My Word Jar")
                        .font(fontManager.uiFont(size: 18, weight: .semibold))
                        .foregroundColor(Color("AppText"))
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
            }
            .accessibilityLabel("My Word Jar")

            // Accessibility settings
            Button {
                // show accessibility sheet
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "textformat.size")
                        .font(.system(size: 20))
                    Text("Text Settings")
                        .font(fontManager.uiFont(size: 18, weight: .semibold))
                }
                .foregroundColor(Color("AppText"))
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
            }
            .accessibilityLabel("Text settings")

            // Reset onboarding (test only)
            Button {
                hasCompletedOnboarding = false
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset")
                }
                .font(fontManager.uiFont(size: 15))
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.black.opacity(0.15))
                .cornerRadius(16)
            }
            .accessibilityLabel("Reset onboarding — test only")
        }
        .opacity(contentOpacity)
    }

    // MARK: - Animations
    private func startAnimations() {
        // Cloud drift animations
        withAnimation(.linear(duration: 40).repeatForever(autoreverses: false)) {
            cloud1Offset = 1400
        }
        withAnimation(.linear(duration: 55).repeatForever(autoreverses: false).delay(5)) {
            cloud2Offset = 1400
        }
        withAnimation(.linear(duration: 35).repeatForever(autoreverses: false).delay(12)) {
            cloud3Offset = 1400
        }

        // Content entrance
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
            titleScale = 1.0
            titleOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
            contentOpacity = 1.0
        }
    }
}

// MARK: - Landscape Background
struct LandscapeBackground: View {

    let cloud1Offset: CGFloat
    let cloud2Offset: CGFloat
    let cloud3Offset: CGFloat

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Sky gradient
                LinearGradient(
                    colors: [Color(hex: "#B8E4F7"), Color(hex: "#E8F4FD")],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()

                // Clouds
                CloudShape()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 180, height: 60)
                    .offset(x: cloud1Offset, y: h * 0.08)

                CloudShape()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 240, height: 70)
                    .offset(x: cloud2Offset, y: h * 0.15)

                CloudShape()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 140, height: 45)
                    .offset(x: cloud3Offset, y: h * 0.05)

                // Far hill (lightest green)
                FarHillShape()
                    .fill(Color(hex: "#A8D5A2"))
                    .ignoresSafeArea()

                // Mid hill
                MidHillShape()
                    .fill(Color(hex: "#7BC47A"))
                    .ignoresSafeArea()

                // Near hill (richest green, foreground)
                NearHillShape()
                    .fill(Color(hex: "#4CAF50"))
                    .ignoresSafeArea()
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Hill Shapes
struct FarHillShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: 0, y: h * 0.72))
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.68),
            control1: CGPoint(x: w * 0.25, y: h * 0.52),
            control2: CGPoint(x: w * 0.75, y: h * 0.78)
        )
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()
        return path
    }
}

struct MidHillShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: 0, y: h * 0.80))
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.76),
            control1: CGPoint(x: w * 0.3, y: h * 0.60),
            control2: CGPoint(x: w * 0.7, y: h * 0.88)
        )
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()
        return path
    }
}

struct NearHillShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: 0, y: h * 0.88))
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.84),
            control1: CGPoint(x: w * 0.35, y: h * 0.70),
            control2: CGPoint(x: w * 0.65, y: h * 0.95)
        )
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()
        return path
    }
}

// MARK: - Cloud Shape
struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        // Overlapping ellipses for a soft cloud shape
        path.addEllipse(in: CGRect(x: w * 0.05, y: h * 0.1, width: w * 0.3, height: h * 0.7))
        path.addEllipse(in: CGRect(x: w * 0.25, y: 0, width: w * 0.4, height: h * 0.85))
        path.addEllipse(in: CGRect(x: w * 0.58, y: h * 0.15, width: w * 0.32, height: h * 0.65))
        path.addEllipse(in: CGRect(x: 0, y: h * 0.4, width: w * 0.6, height: h * 0.5))
        path.addEllipse(in: CGRect(x: w * 0.35, y: h * 0.35, width: w * 0.5, height: h * 0.55))
        return path
    }
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
