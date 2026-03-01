// Purpose: Manages the AVCaptureSession lifecycle, photo capture,
// and orchestrates Vision classification results.

import AVFoundation
import UIKit
import SwiftUI

// MARK: - Camera State
enum CameraState: Equatable {
    case idle           // Camera is live, waiting for capture
    case capturing      // Photo is being captured (brief flash)
    case processing     // Vision is classifying the image
    case lowConfidence  // Multiple options found, user must pick
    case error(String)  // Something went wrong
}

// MARK: - Setup Error
private enum SetupError: Error {
    case noCamera
    case sessionFailed(String)
}

// MARK: - Camera Session Manager (nonisolated — runs AVFoundation off main actor)
private final class CameraSessionManager: @unchecked Sendable {

    let session = AVCaptureSession()
    let photoOutput = AVCapturePhotoOutput()
    private var isSessionRunning = false

    func setup() throws {
        do {
            session.beginConfiguration()
            defer { session.commitConfiguration() }

            session.sessionPreset = .photo

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input) else {
                throw SetupError.noCamera
            }
            print("📷 Adding input...")
            session.addInput(input)

            guard session.canAddOutput(photoOutput) else {
                throw SetupError.sessionFailed("Cannot add photo output")
            }
            print("📷 Adding output...")
            session.addOutput(photoOutput)
        }
        // After block ends, defer has run — commitConfiguration() done. Now start.
        print("📷 Starting session...")
        session.startRunning()
        isSessionRunning = true
        print("📷 Camera setup complete")
    }

    func stopSession() {
        guard isSessionRunning else { return }
        isSessionRunning = false
        session.stopRunning()
    }

    func capturePhoto(settings: AVCapturePhotoSettings, delegate: AVCapturePhotoCaptureDelegate) {
        photoOutput.capturePhoto(with: settings, delegate: delegate)
    }
}

// MARK: - Camera View Model
@MainActor
class CameraViewModel: NSObject, ObservableObject {

    // MARK: - Published Properties
    @Published var cameraState: CameraState = .idle
    @Published var capturedImage: UIImage?
    @Published var lowConfidenceOptions: [VisionResult] = []
    @Published var selectedObject: String?         // Set when object is confirmed
    @Published var showFlash = false               // Brief white flash on capture
    @Published var permissionDenied = false

    // MARK: - Camera Session (nonisolated manager for AVFoundation work)
    private let sessionManager = CameraSessionManager()

    /// Session reference for preview layer; accessed from main actor for UI binding only.
    var session: AVCaptureSession { sessionManager.session }

    // MARK: - Continuation (main actor)
    private var photoContinuation: CheckedContinuation<UIImage, Error>?

    // MARK: - Services
    private let groqVisionService = GroqVisionService()

    // MARK: - Setup
    func setupCamera() async {
        print("📷 Starting camera setup...")
        // Check permission (main actor)
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        print("📷 Permission status: \(status.rawValue)")
        switch status {
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if !granted {
                permissionDenied = true
                return
            }
        case .denied, .restricted:
            permissionDenied = true
            return
        default:
            break
        }

        // Configure session off main actor
        let manager = sessionManager
        let setupError: Error? = await Task.detached(priority: .userInitiated) {
            do {
                try manager.setup()
                return nil as Error?
            } catch {
                print("📷 Setup failed: \(error)")
                return error
            }
        }.value

        if let error = setupError {
            cameraState = .error("Camera couldn't start. Please try again.")
            print("📷 Camera setup error: \(error)")
        }
    }

    // MARK: - Capture Photo
    func capturePhoto() {
        print("📸 Step 1 - capturePhoto called, state: \(cameraState)")
        guard case .idle = cameraState else { return }

        // Flash effect
        withAnimation(.easeIn(duration: 0.1)) { showFlash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.2)) { self.showFlash = false }
        }
        print("📸 Step 2 - flash triggered")

        cameraState = .capturing
        print("📸 Step 3 - state set to capturing")

        Task {
            print("📸 Step 4 - inside Task")
            do {
                let image = try await capturePhotoAsync()
                print("📸 Step 5 - photo captured, size: \(image.size)")
                capturedImage = image
                print("📸 Step 6 - image assigned")
                cameraState = .processing
                print("📸 Step 7 - state set to processing")
                print("📸 Step 8 - about to classify")
                await classifyImage(image)
            } catch {
                cameraState = .error("Couldn't take photo. Try again!")
            }
        }
    }

    // MARK: - Capture Photo Async
    private func capturePhotoAsync() async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            self.photoContinuation = continuation
            let settings = AVCapturePhotoSettings()
            self.sessionManager.capturePhoto(settings: settings, delegate: self)
        }
    }

    // MARK: - Classify Image
    private func classifyImage(_ image: UIImage) async {
        print("🔍 classifyImage START")
        do {
            print("🔍 About to call GroqVisionService")
            let results = try await groqVisionService.identifyObject(image: image)
            print("🔍 Got results: \(results.count)")

            if results.isEmpty {
                cameraState = .error("Hmm I could not see that clearly!\nTry pointing at something else")
                return
            }

            let top = results[0]
            print("🔍 Top result: \(top.label) confidence: \(top.confidence)")

            if top.confidence >= 0.5 {
                selectedObject = top.label
            } else if top.confidence >= 0.2 {
                lowConfidenceOptions = results
                cameraState = .lowConfidence
            } else {
                cameraState = .error("Hmm I could not see that clearly!\nTry pointing at something else")
            }
        } catch {
            print("🔍 ERROR: \(error)")
            print("🔍 ERROR TYPE: \(type(of: error))")
            cameraState = .error("Something went wrong. Try again!")
        }
        print("🔍 classifyImage END")
    }

    // MARK: - Select Object (from low confidence picker)
    func selectObject(_ label: String) {
        selectedObject = label
    }

    // MARK: - Reset (go back to idle camera)
    func reset() {
        cameraState = .idle
        capturedImage = nil
        lowConfidenceOptions = []
        selectedObject = nil
        showFlash = false
    }

    // MARK: - Stop Session
    func stopSession() {
        let manager = sessionManager
        Task.detached(priority: .background) {
            manager.stopSession()
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput,
                                  didFinishProcessingPhoto photo: AVCapturePhoto,
                                  error: Error?) {
        print("📸 Delegate called - error: \(String(describing: error))")
        if let error {
            Task { @MainActor in
                self.photoContinuation?.resume(throwing: error)
                self.photoContinuation = nil
            }
            return
        }

        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            Task { @MainActor in
                self.photoContinuation?.resume(throwing: VisionError.invalidImage)
                self.photoContinuation = nil
            }
            return
        }

        Task { @MainActor in
            self.photoContinuation?.resume(returning: image)
            self.photoContinuation = nil
        }
    }
}
