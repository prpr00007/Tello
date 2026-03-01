// Purpose: Main camera screen. Shows a live camera feed with an animated
// viewfinder overlay. Handles object detection and navigates to LoadingView.

import SwiftUI
import AVFoundation

struct CameraView: View {

    @EnvironmentObject var fontManager: FontManager
    @AppStorage("childName") private var childName = ""
    @AppStorage("wordCount") private var wordCount = 0

    @StateObject private var viewModel = CameraViewModel()
    @State private var viewfinderPulse = false
    @State private var showPermissionAlert = false

    var body: some View {
        ZStack {

            // MARK: - Camera Feed
            CameraPreviewView(session: viewModel.session)
                .ignoresSafeArea()

            // MARK: - Flash Overlay
            if viewModel.showFlash {
                Color.white
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            // MARK: - Main Overlay UI
            VStack(spacing: 0) {

                topBar

                Spacer()

                viewfinder

                Spacer()

                bottomBar
            }

            // MARK: - Processing Overlay
            if case .processing = viewModel.cameraState {
                processingOverlay
            }

            // MARK: - Error Overlay
            if case .error(let message) = viewModel.cameraState {
                errorOverlay(message: message)
            }

            // MARK: - Low Confidence Picker
            if case .lowConfidence = viewModel.cameraState {
                lowConfidencePicker
            }

            // MARK: - Navigate to Loading
            if let object = viewModel.selectedObject {
                NavigationLink(value: object) {
                    EmptyView()
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(for: String.self) { object in
            LoadingView(detectedObject: object, childName: childName)
                .navigationBarHidden(true)
        }
        .task {
            await viewModel.setupCamera()
            if viewModel.permissionDenied {
                showPermissionAlert = true
            }
        }
        .onDisappear {
            viewModel.stopSession()
        }
        .alert("Camera Access Needed", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Tello needs camera access to identify objects and create stories. Please enable it in Settings.")
        }
    }

    // MARK: - Top Bar
    var topBar: some View {
        HStack {
            NavigationLink(destination: Text("Word Jar — Stage 7").navigationBarHidden(true)) {
                HStack(spacing: 10) {
                    Image(systemName: "text.book.closed.fill")
                        .font(.system(size: 20, weight: .medium))
                    Text("\(wordCount)")
                        .font(fontManager.uiFont(size: 19, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
                )
            }
            .accessibilityLabel("Word Jar, \(wordCount) words collected")

            Spacer()

            Text("Hi, \(childName)")
                .font(fontManager.uiFont(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.4), radius: 6)
                .shadow(color: Color("AppPrimary").opacity(0.3), radius: 2)

            Spacer()

            NavigationLink(destination: SettingsPlaceholderView().navigationBarHidden(true)) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 52, height: 52)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 1))
                    )
            }
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, 28)
        .padding(.top, 24)
    }

    // MARK: - Viewfinder
    var viewfinder: some View {
        VStack(spacing: 20) {
            Text("Point at something")
                .font(fontManager.storyFontBold(size: 28))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 8)
                .shadow(color: Color("AppPrimary").opacity(0.4), radius: 4)

            ZStack {
                RoundedRectangle(cornerRadius: 32)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.5),
                                Color.white.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 340, height: 340)

                ViewfinderBrackets(pulse: viewfinderPulse)
                    .frame(width: 340, height: 340)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    viewfinderPulse = true
                }
            }
        }
    }

    // MARK: - Bottom Bar
    var bottomBar: some View {
        HStack {
            Spacer()

            // TEMPORARY TEST BUTTON - REMOVE BEFORE SUBMISSION
            NavigationLink(value: "dog") {
                Text("Test Story 🧪")
                    .font(fontManager.uiFont(size: 16, weight: .semibold))
                    .foregroundColor(Color("AppPrimary"))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color("AppCardBackground"))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color("AppPrimary").opacity(0.4), lineWidth: 1))
                    )
            }
            .padding(.trailing, 16)

            Button {
                viewModel.capturePhoto()
            } label: {
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(Color("AppPrimary").opacity(0.25))
                        .frame(width: 100, height: 100)
                        .blur(radius: 12)

                    Circle()
                        .fill(.white)
                        .frame(width: 88, height: 88)
                        .shadow(color: .black.opacity(0.25), radius: 12)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color("AppPrimary"), Color("AppPrimary").opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)

                    Image(systemName: "camera.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .disabled(viewModel.cameraState != .idle)
            .scaleEffect(viewModel.cameraState == .idle ? 1.0 : 0.92)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.cameraState == .idle)
            .accessibilityLabel("Take photo")
            .accessibilityHint("Takes a photo and identifies the object to create a story")

            Spacer()
        }
        .padding(.bottom, 48)
    }

    // MARK: - Processing Overlay
    var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 24) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(1.6)

                Text("Looking at that...")
                    .font(fontManager.storyFontBold(size: 24))
                    .foregroundColor(.white)
            }
            .padding(48)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Error Overlay
    func errorOverlay(message: String) -> some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()

            VStack(spacing: 28) {
                Text(message)
                    .font(fontManager.storyFont(size: 24))
                    .foregroundColor(Color("AppText"))
                    .multilineTextAlignment(.center)

                PrimaryButton(label: "Try Again", icon: "arrow.clockwise") {
                    viewModel.reset()
                }
                .frame(maxWidth: 320)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color("AppCardBackground"))
                    .shadow(color: Color.black.opacity(0.2), radius: 24)
            )
            .padding(48)
        }
    }

    // MARK: - Low Confidence Picker
    var lowConfidencePicker: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()

            VStack(spacing: 28) {
                Text("I see a few things!\nWhich one did you mean?")
                    .font(fontManager.storyFontBold(size: 28))
                    .foregroundColor(Color("AppText"))
                    .multilineTextAlignment(.center)

                VStack(spacing: 14) {
                    ForEach(viewModel.lowConfidenceOptions, id: \.label) { option in
                        Button {
                            viewModel.selectObject(option.label)
                        } label: {
                            Text(option.label.capitalized)
                                .font(fontManager.storyFont(size: 24))
                                .foregroundColor(Color("AppText"))
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 64)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color("AppBackground"))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .frame(maxWidth: 420)

                Button {
                    viewModel.reset()
                } label: {
                    Text("Try again")
                        .font(fontManager.uiFont(size: 19))
                        .foregroundColor(Color("AppSecondaryText"))
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color("AppCardBackground"))
                    .shadow(color: Color.black.opacity(0.2), radius: 24)
            )
            .padding(48)
        }
    }
}

// MARK: - Viewfinder Brackets
struct ViewfinderBrackets: View {

    let pulse: Bool
    let bracketLength: CGFloat = 44
    let bracketWidth: CGFloat = 5

    var body: some View {
        ZStack {
            bracketShape(rotation: 0)
                .offset(x: -152, y: -152)
            bracketShape(rotation: 90)
                .offset(x: 152, y: -152)
            bracketShape(rotation: 180)
                .offset(x: 152, y: 152)
            bracketShape(rotation: 270)
                .offset(x: -152, y: 152)
        }
        .opacity(pulse ? 1.0 : 0.65)
        .scaleEffect(pulse ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: pulse)
    }

    func bracketShape(rotation: Double) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: bracketLength, height: bracketWidth)
                .offset(x: bracketLength / 2 - 2.5, y: 0)

            RoundedRectangle(cornerRadius: 3)
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: bracketWidth, height: bracketLength)
                .offset(x: 0, y: bracketLength / 2 - 2.5)
        }
        .rotationEffect(.degrees(rotation))
        .shadow(color: Color("AppPrimary").opacity(0.6), radius: 6)
    }
}

// MARK: - Camera Preview (UIViewRepresentable)
struct CameraPreviewView: UIViewRepresentable {

    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
                layer.frame = uiView.bounds
            }
        }
    }
}

// MARK: - Settings Placeholder
struct SettingsPlaceholderView: View {
    @EnvironmentObject var fontManager: FontManager

    var body: some View {
        ZStack {
            Color("AppBackground").ignoresSafeArea()
            VStack(spacing: 24) {
                Text("Settings")
                    .font(fontManager.storyFontBold(size: 36))
                    .foregroundColor(Color("AppText"))
                Text("Coming soon!")
                    .font(fontManager.storyFont(size: 22))
                    .foregroundColor(Color("AppSecondaryText"))
                AccessibilityToolbar()
            }
        }
    }
}
