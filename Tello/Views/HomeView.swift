// Purpose: Home screen and main hub for Tello.
// Greets the child, shows word barn progress, and provides
// navigation to the camera and word barn.

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

                // MARK: - Decorative barn on mid hill (left side, behind book)
                GeometryReader { geo in
                    let barnFill: Double = wordCount >= 20 ? 1.0 : wordCount >= 10 ? 0.5 : wordCount >= 5 ? 0.25 : 0
                    VStack(spacing: 8) {
                        Button {
                            navigationPath.append("wordbarn")
                        } label: {
                            HomeViewBarn(fillLevel: barnFill)
                        }
                        .buttonStyle(PlainButtonStyle())
                        Text("Word Barn")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.4), radius: 2)
                    }
                    .position(
                        x: geo.size.width * 0.15,
                        y: geo.size.height * 0.62
                    )
                }

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
                } else if destination == "wordbarn" {
                    WordBarnView()
                        .navigationBarHidden(true)
                } else if destination == "settings" {
                    SettingsView(navigationPath: $navigationPath)
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
                titleScale = 0.8
                titleOpacity = 0
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

            // Word barn teaser
            Button {
                navigationPath.append("wordbarn")
            } label: {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(wordCount) words")
                            .font(fontManager.uiFont(size: 16, weight: .bold))
                            .foregroundColor(Color("AppText"))
                        Text("In the Barn")
                            .font(fontManager.uiFont(size: 13))
                            .foregroundColor(Color("AppSecondaryText"))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
            }
            .accessibilityLabel("Word Barn, \(wordCount) words collected")

            // Settings
            Button {
                navigationPath.append("settings")
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

    // MARK: - Centre Content (Book)
    var centreContent: some View {
        BookView(
            childName: childName,
            fontManager: fontManager,
            onOpen: {
                navigationPath.append("camera")
            }
        )
        .scaleEffect(titleScale)
        .opacity(titleOpacity)
    }

    // MARK: - Bottom Actions
    var bottomActions: some View {
        HStack(spacing: 20) {

            // Word Barn button
            Button {
                navigationPath.append("wordbarn")
            } label: {
                HStack(spacing: 10) {
                    Text("My Word Barn")
                        .font(fontManager.uiFont(size: 18, weight: .semibold))
                        .foregroundColor(Color("AppText"))
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
            }
            .accessibilityLabel("My Word Barn")

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

// MARK: - Book View
struct BookView: View {

    let childName: String
    let fontManager: FontManager
    let onOpen: () -> Void

    @State private var isOpening = false
    @State private var coverAngle: Double = 0
    @State private var bobOffset: CGFloat = 0

    let bookWidth: CGFloat = 300
    let bookHeight: CGFloat = 380

    var body: some View {
        ZStack {
            // Book shadow
            Ellipse()
                .fill(Color.black.opacity(0.15))
                .frame(width: bookWidth * 0.85, height: 24)
                .offset(y: bookHeight * 0.52)
                .blur(radius: 8)

            // Pages (visible when book opens)
            BookPages(width: bookWidth, height: bookHeight)
                .opacity(isOpening ? 1.0 : 0.0)

            // Book cover
            BookCover(
                width: bookWidth,
                height: bookHeight,
                childName: childName,
                fontManager: fontManager,
                isOpening: isOpening
            )
            .rotation3DEffect(
                .degrees(coverAngle),
                axis: (x: 0, y: 1, z: 0),
                anchor: .leading,
                perspective: 0.4
            )

            // Tap target overlay
            if !isOpening {
                Color.clear
                    .frame(width: bookWidth, height: bookHeight)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        openBook()
                    }
            }
        }
        .frame(width: bookWidth, height: bookHeight)
        .offset(y: bobOffset)
        .onAppear {
            isOpening = false
            coverAngle = 0
            bobOffset = 0
            withAnimation(
                .easeInOut(duration: 2.5)
                .repeatForever(autoreverses: true)
            ) {
                bobOffset = -12
            }
        }
        .accessibilityLabel("Tello storybook")
        .accessibilityHint("Tap to open the book and start a story")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Open Book
    private func openBook() {
        guard !isOpening else { return }
        isOpening = true

        // Stop bobbing
        withAnimation(.easeOut(duration: 0.2)) {
            bobOffset = 0
        }

        // Open cover with 3D rotation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
            coverAngle = -170
        }

        // Navigate after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            onOpen()
        }
    }
}

// MARK: - Book Cover
struct BookCover: View {

    let width: CGFloat
    let height: CGFloat
    let childName: String
    let fontManager: FontManager
    let isOpening: Bool

    var body: some View {
        ZStack {
            // Cover background
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#C0392B"), Color(hex: "#922B21")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: width, height: height)

            // Spine shadow on left
            Rectangle()
                .fill(Color.black.opacity(0.25))
                .frame(width: 20, height: height)
                .offset(x: -(width / 2) + 10)
                .cornerRadius(4)

            // Gold border
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(hex: "#F4D03F"), lineWidth: 3)
                .frame(width: width - 24, height: height - 24)

            // Inner gold border (double border effect)
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color(hex: "#F4D03F").opacity(0.5), lineWidth: 1)
                .frame(width: width - 36, height: height - 36)

            // Cover content
            VStack(spacing: 16) {
                Spacer()

                // Book illustration
                ZStack {
                    Circle()
                        .fill(Color(hex: "#F4D03F").opacity(0.15))
                        .frame(width: 110, height: 110)

                    Circle()
                        .stroke(Color(hex: "#F4D03F").opacity(0.4), lineWidth: 2)
                        .frame(width: 110, height: 110)

                    Text("✨")
                        .font(.system(size: 56))
                }

                // Title
                Text("Tello")
                    .font(fontManager.storyFontBold(size: 42))
                    .foregroundColor(Color(hex: "#F9EBEA"))
                    .shadow(color: .black.opacity(0.3), radius: 4)

                // Subtitle
                Text("Your Story Starts Here")
                    .font(fontManager.storyFont(size: 16))
                    .foregroundColor(Color(hex: "#F4D03F").opacity(0.9))
                    .italic()

                Spacer()

                // Tap prompt (only show when not opening)
                if !isOpening {
                    HStack(spacing: 8) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 16))
                        Text("Tap to open")
                            .font(fontManager.uiFont(size: 16, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "#F4D03F").opacity(0.8))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(20)
                    .padding(.bottom, 28)
                } else {
                    Color.clear.frame(height: 50)
                }
            }
            .frame(width: width, height: height)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: Color(hex: "#922B21").opacity(0.4), radius: 12, x: 4, y: 8)
    }
}

// MARK: - Book Pages
struct BookPages: View {

    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack(alignment: .leading) {
            // Pages stack (right side)
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "#FDF5E6"))
                .frame(width: width, height: height)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 2, y: 2)

            // Page lines to look like text
            VStack(alignment: .leading, spacing: 14) {
                ForEach(0..<10, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.15))
                        .frame(
                            width: i % 3 == 0 ? width * 0.6 : width * 0.75,
                            height: 8
                        )
                }
            }
            .padding(40)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Home View Barn (140x120pt decorative barn on landscape)
struct HomeViewBarn: View {
    let fillLevel: Double

    var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .bottom) {
                // LAYER 1 - Roof triangle: Path (0,55)→(140,55)→(70,0), frame 140x55, #5D3A1A
                HomeBarnRoofTriangle()
                    .fill(Color(hex: "#5D3A1A"))
                    .frame(width: 140, height: 55)
                    .offset(y: -70)

                // LAYER 2 - Roof overhang: 148x5, #4A2E12, at roof base
                Rectangle()
                    .fill(Color(hex: "#4A2E12"))
                    .frame(width: 148, height: 5)
                    .offset(x: -4, y: -65)

                // LAYER 3 - Barn body: 140x70, #C0392B
                Rectangle()
                    .fill(Color(hex: "#C0392B"))
                    .frame(width: 140, height: 70)

                // LAYER 4 - Hay fill: 134 wide, height 66*fillLevel, #F39C12 0.85, bottom-anchored, clipped
                ZStack(alignment: .bottom) {
                    Rectangle()
                        .fill(Color(hex: "#F39C12").opacity(0.85))
                        .frame(width: 134, height: 66 * CGFloat(fillLevel))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: fillLevel)
                }
                .frame(width: 140, height: 70)
                .clipped()

                // LAYER 5 - Left wall shadow: 8x70, black 0.15, far left
                Rectangle()
                    .fill(Color.black.opacity(0.15))
                    .frame(width: 8, height: 70)
                    .position(x: 4, y: 85)

                // LAYER 6 - Right wall shadow: 8x70, far right
                Rectangle()
                    .fill(Color.black.opacity(0.15))
                    .frame(width: 8, height: 70)
                    .position(x: 136, y: 85)

                // LAYER 7 - Left window: 18x18 RoundedRectangle, #F8C471, 16pt from left, 12pt from top of body
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: "#F8C471"))
                    .frame(width: 18, height: 18)
                    .position(x: 25, y: 71)

                // LAYER 8 - Right window: 18x18, 16pt from right
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: "#F8C471"))
                    .frame(width: 18, height: 18)
                    .position(x: 115, y: 71)

                // LAYER 9 - Left door: 28x38 RoundedRectangle, #922B21, centre - 29pt, bottom
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: "#922B21"))
                    .frame(width: 28, height: 38)
                    .position(x: 41, y: 101)

                // LAYER 10 - Right door: 28x38, centre + 1pt, bottom
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: "#922B21"))
                    .frame(width: 28, height: 38)
                    .position(x: 71, y: 101)

                // LAYER 11 - Door trim: 2x38, #7B241C, centred between doors
                Rectangle()
                    .fill(Color(hex: "#7B241C"))
                    .frame(width: 2, height: 38)
                    .position(x: 70, y: 101)

                // LAYER 12 - Loft window: 22x16 RoundedRectangle, #3D1F0F, 10pt from bottom of roof
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: "#3D1F0F"))
                    .frame(width: 22, height: 16)
                    .position(x: 70, y: 32)
            }
        }
        .frame(width: 140, height: 120)
    }
}

// Roof triangle: (0,55)→(140,55)→(70,0) in 140x55 frame
struct HomeBarnRoofTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: rect.width / 2, y: 0))
        path.closeSubpath()
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
