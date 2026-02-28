// Purpose: Main camera screen. Shows a live camera feed with an animated
// viewfinder overlay. Handles object detection and navigates to LoadingView.

import SwiftUI
import AVFoundation

struct CameraView: View {

    @EnvironmentObject var fontManager: FontManager
    @AppStorage("childName") private var childName = ""
    @AppStorage("wordCount") private var wordCount = 0

    @StateObject private var viewModel = CameraViewModel()
    @State private var navigateToLoading = false
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

                // Top Bar
                topBar

                Spacer()

                // Viewfinder
                viewfinder

                Spacer()

                // Bottom Bar
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
            NavigationLink(
                destination: LoadingView(
                    detectedObject: viewModel.selectedObject ?? "",
                    childName: childName
                )
                .navigationBarHidden(true),
                isActive: $navigateToLoading
            ) { EmptyView() }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.setupCamera()
            if viewModel.permissionDenied {
                showPermissionAlert = true
            }
        }
        .onDisappear {
            viewModel.stopSession()
        }
        .onChange(of: viewModel.selectedObject) { _, object in
            if object != nil {
                navigateToLoading = true
            }
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
            // Word Jar Button
            NavigationLink(destination: Text("Word Jar — Stage 7").navigationBarHidden(true)) {
                HStack(spacing: 8) {
                    Text("🫙")
                        .font(.system(size: 24))
                    Text("\(wordCount)")
                        .font(fontManager.uiFont(size: 18, weight: .bold))
                        .foregroundColor(Color("AppText"))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.4))
                .cornerRadius(20)
            }
            .accessibilityLabel("Word Jar, \(wordCount) words collected")

            Spacer()

            // Greeting
            Text("Hi, \(childName)! 👋")
                .font(fontManager.uiFont(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 4)

            Spacer()

            // Settings Button
            NavigationLink(destination: SettingsPlaceholderView().navigationBarHidden(true)) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(22)
            }
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    // MARK: - Viewfinder
    var viewfinder: some View {
        VStack(spacing: 16) {
            Text("Point at something! 📷")
                .font(fontManager.storyFontBold(size: 24))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.6), radius: 6)

            ZStack {
                // Dimmed border area hint
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    .frame(width: 320, height: 320)

                // Animated corner brackets
                ViewfinderBrackets(pulse: viewfinderPulse)
                    .frame(width: 320, height: 320)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    viewfinderPulse = true
                }
            }
        }
    }

    // MARK: - Bottom Bar
    var bottomBar: some View {
        HStack {
            Spacer()

            // Capture Button
            Button {
                viewModel.capturePhoto()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 80, height: 80)
                        .shadow(color: .black.opacity(0.3), radius: 8)

                    Circle()
                        .fill(Color("AppPrimary"))
                        .frame(width: 66, height: 66)

                    Image(systemName: "camera.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .disabled(viewModel.cameraState != .idle)
            .scaleEffect(viewModel.cameraState == .idle ? 1.0 : 0.9)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.cameraState == .idle)
            .accessibilityLabel("Take photo")
            .accessibilityHint("Takes a photo and identifies the object to create a story")

            Spacer()
        }
        .padding(.bottom, 40)
    }

    // MARK: - Processing Overlay
    var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(1.5)

                Text("Looking at that...")
                    .font(fontManager.storyFontBold(size: 22))
                    .foregroundColor(.white)
            }
            .padding(40)
            .background(Color.black.opacity(0.6))
            .cornerRadius(24)
        }
    }

    // MARK: - Error Overlay
    func errorOverlay(message: String) -> some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(spacing: 24) {
                Text(message)
                    .font(fontManager.storyFont(size: 22))
                    .foregroundColor(Color("AppText"))
                    .multilineTextAlignment(.center)

                PrimaryButton(label: "Try Again 🔄", icon: nil) {
                    viewModel.reset()
                }
                .frame(maxWidth: 300)
            }
            .padding(32)
            .background(Color("AppCardBackground"))
            .cornerRadius(24)
            .shadow(radius: 20)
            .padding(40)
        }
    }

    // MARK: - Low Confidence Picker
    var lowConfidencePicker: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(spacing: 24) {
                Text("I see a few things!\nWhich one did you mean?")
                    .font(fontManager.storyFontBold(size: 26))
                    .foregroundColor(Color("AppText"))
                    .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    ForEach(viewModel.lowConfidenceOptions, id: \.label) { option in
                        Button {
                            viewModel.selectObject(option.label)
                        } label: {
                            Text(option.label.capitalized)
                                .font(fontManager.storyFont(size: 22))
                                .foregroundColor(Color("AppText"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(Color("AppBackground"))
                                .cornerRadius(16)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .frame(maxWidth: 400)

                Button {
                    viewModel.reset()
                } label: {
                    Text("Try again 🔄")
                        .font(fontManager.uiFont(size: 18))
                        .foregroundColor(Color("AppSecondaryText"))
                }
            }
            .padding(32)
            .background(Color("AppCardBackground"))
            .cornerRadius(24)
            .shadow(radius: 20)
            .padding(40)
        }
    }
}

// MARK: - Viewfinder Brackets
struct ViewfinderBrackets: View {

    let pulse: Bool
    let bracketLength: CGFloat = 40
    let bracketWidth: CGFloat = 4

    var body: some View {
        ZStack {
            // Top Left
            bracketShape(rotation: 0)
                .offset(x: -140, y: -140)

            // Top Right
            bracketShape(rotation: 90)
                .offset(x: 140, y: -140)

            // Bottom Right
            bracketShape(rotation: 180)
                .offset(x: 140, y: 140)

            // Bottom Left
            bracketShape(rotation: 270)
                .offset(x: -140, y: 140)
        }
        .opacity(pulse ? 1.0 : 0.6)
        .scaleEffect(pulse ? 1.04 : 1.0)
    }

    func bracketShape(rotation: Double) -> some View {
        ZStack {
            // Horizontal arm
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white)
                .frame(width: bracketLength, height: bracketWidth)
                .offset(x: bracketLength / 2 - 2, y: 0)

            // Vertical arm
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white)
                .frame(width: bracketWidth, height: bracketLength)
                .offset(x: 0, y: bracketLength / 2 - 2)
        }
        .rotationEffect(.degrees(rotation))
        .shadow(color: Color("AppPrimary").opacity(0.6), radius: 4)
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
            VStack(spacing: 20) {
                Text("⚙️ Settings")
                    .font(fontManager.storyFontBold(size: 32))
                    .foregroundColor(Color("AppText"))
                Text("Coming soon!")
                    .font(fontManager.storyFont(size: 20))
                    .foregroundColor(Color("AppSecondaryText"))
                AccessibilityToolbar()
            }
        }
    }
}
