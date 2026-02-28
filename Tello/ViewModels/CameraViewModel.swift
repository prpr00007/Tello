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

    // MARK: - Camera Session
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var photoContinuation: CheckedContinuation<UIImage, Error>?
    private var isSessionRunning = false

    // MARK: - Services
    private let visionService = VisionService()

    // MARK: - Setup
    func setupCamera() async {
        // Check permission
        let status = AVCaptureDevice.authorizationStatus(for: .video)
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

        // Configure session on background thread
        await Task.detached(priority: .userInitiated) {
            var configured = false
            do {
                self.session.beginConfiguration()
                defer { self.session.commitConfiguration() }

                self.session.sessionPreset = .photo

                // Add video input
                guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                      let input = try? AVCaptureDeviceInput(device: device),
                      self.session.canAddInput(input) else {
                    await MainActor.run { self.cameraState = .error("Camera not available") }
                    return
                }
                self.session.addInput(input)

                // Add photo output
                if self.session.canAddOutput(self.photoOutput) {
                    self.session.addOutput(self.photoOutput)
                }

                configured = true
            } catch {
                await MainActor.run { self.cameraState = .error("Camera not available") }
            }

            if configured {
                self.session.startRunning()
                await MainActor.run { self.isSessionRunning = true }
            }
        }.value
    }

    // MARK: - Capture Photo
    func capturePhoto() {
        guard case .idle = cameraState else { return }

        // Flash effect
        withAnimation(.easeIn(duration: 0.1)) { showFlash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.2)) { self.showFlash = false }
        }

        cameraState = .capturing

        Task {
            do {
                let image = try await capturePhotoAsync()
                capturedImage = image
                cameraState = .processing
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
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    // MARK: - Classify Image
    private func classifyImage(_ image: UIImage) async {
        do {
            let results = try await visionService.classify(image: image)

            if results.isEmpty {
                // Nothing recognised
                cameraState = .error("Hmm, I couldn't see that clearly!\nTry pointing at something else 🔍")
                return
            }

            let top = results[0]

            if top.confidence >= 0.5 {
                // High confidence — auto proceed
                selectedObject = top.label
                print("✅ High confidence: \(top.label) (\(top.confidence))")
            } else if top.confidence >= 0.2 {
                // Low confidence — show picker
                lowConfidenceOptions = results
                cameraState = .lowConfidence
                print("⚠️ Low confidence options: \(results.map { "\($0.label) \($0.confidence)" })")
            } else {
                // Too low — nothing useful found
                cameraState = .error("Hmm, I couldn't see that clearly!\nTry pointing at something else 🔍")
            }
        } catch {
            cameraState = .error("Something went wrong. Try again! 🔄")
        }
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
        guard isSessionRunning else { return }
        isSessionRunning = false
        Task.detached(priority: .background) {
            self.session.stopRunning()
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput,
                                  didFinishProcessingPhoto photo: AVCapturePhoto,
                                  error: Error?) {
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
