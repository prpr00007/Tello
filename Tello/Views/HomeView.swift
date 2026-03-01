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
                    let w = geo.size.width
                    let h = geo.size.height
                    let barnFill: Double = wordCount >= 20 ? 1.0 : wordCount >= 10 ? 0.5 : wordCount >= 5 ? 0.25 : 0
                    VStack(spacing: 4) {
                        Button {
                            navigationPath.append("wordbarn")
                        } label: {
                            HomeViewBarn(fillLevel: barnFill)
                                .frame(width: 90, height: 80)
                        }
                        .buttonStyle(PlainButtonStyle())
                        Text("Word Barn")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2)
                    }
                    .frame(width: 90, height: 80 + 24)
                    .position(
                        x: w * 0.12 + 45,
                        y: h * 0.65 - 30
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

// MARK: - Home View Barn (90x80pt decorative barn on landscape)
struct HomeViewBarn: View {
    let fillLevel: Double

    private let barnBodyWidth: CGFloat = 90
    private let barnBodyHeight: CGFloat = 50
    private let roofHeight: CGFloat = 30

    var body: some View {
        ZStack(alignment: .bottom) {
            // 1. Barn body — plain Rectangle, 90x50pt, #C0392B, anchored to bottom
            Rectangle()
                .fill(Color(hex: "#C0392B"))
                .frame(width: barnBodyWidth, height: barnBodyHeight)
                .overlay(
                    // 3. Left window — 14x14, 10pt from left, 8pt from top of body
                    HStack(alignment: .top, spacing: 0) {
                        Rectangle()
                            .fill(Color(hex: "#F5CBA7"))
                            .frame(width: 14, height: 14)
                            .padding(.leading, 10)
                            .padding(.top, 8)
                        Spacer()
                        // 4. Right window
                        Rectangle()
                            .fill(Color(hex: "#F5CBA7"))
                            .frame(width: 14, height: 14)
                            .padding(.trailing, 10)
                            .padding(.top, 8)
                    }
                )
                .overlay(alignment: .bottom) {
                    // 5. Door — two Rectangles side by side, centre bottom, 2pt gap
                    HStack(spacing: 2) {
                        Rectangle()
                            .fill(Color(hex: "#922B21"))
                            .frame(width: 16, height: 26)
                        Rectangle()
                            .fill(Color(hex: "#922B21"))
                            .frame(width: 16, height: 26)
                    }
                }
                .overlay(alignment: .bottom) {
                    // 6. Door X pattern — X on each door
                    HStack(spacing: 2) {
                        HomeBarnDoorXShape()
                            .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                            .frame(width: 16, height: 26)
                        HomeBarnDoorXShape()
                            .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                            .frame(width: 16, height: 26)
                    }
                }
                .overlay(
                    // 7. Hay fill — grows from bottom, clipped to body (animatable)
                    HomeBarnHayFillShape(fillLevel: fillLevel, bodyHeight: barnBodyHeight)
                        .fill(Color(hex: "#F4D03F").opacity(0.7))
                        .frame(width: 86, height: barnBodyHeight)
                        .clipped()
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: fillLevel)
                )

            // 2. Roof — Triangle above body
            HomeBarnRoofShape()
                .fill(Color(hex: "#6B3A2A"))
                .frame(width: 90, height: roofHeight)
                .overlay(
                    // 8. Loft opening — 18x12 at peak of roof
                    Rectangle()
                        .fill(Color(hex: "#3D1F0F"))
                        .frame(width: 18, height: 12)
                        .position(x: 45, y: 6)
                )
                .offset(y: -barnBodyHeight)
        }
        .frame(width: 90, height: 80)
    }
}

// Roof triangle: bottom-left (0,30), bottom-right (90,30), peak (45,0) in 90x30 rect
struct HomeBarnRoofShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: 0, y: h))
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: w / 2, y: 0))
        path.closeSubpath()
        return path
    }
}

// X from corner to corner on a door (16x26)
struct HomeBarnDoorXShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.move(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        return path
    }
}

// Hay fill: rectangle from bottom, height = bodyHeight * fillLevel, animatable
struct HomeBarnHayFillShape: Shape {
    var fillLevel: Double
    var bodyHeight: CGFloat
    var animatableData: Double {
        get { fillLevel }
        set { fillLevel = newValue }
    }
    func path(in rect: CGRect) -> Path {
        let h = bodyHeight * CGFloat(fillLevel)
        return Path(CGRect(x: 0, y: rect.height - h, width: rect.width, height: h))
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
