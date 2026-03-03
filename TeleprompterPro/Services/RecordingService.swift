import Foundation
import AVFoundation
import SwiftUI

/// Camera position for recording
enum CameraPosition: String, Codable, CaseIterable {
    case front
    case back

    var displayName: String {
        switch self {
        case .front: "Front"
        case .back: "Back"
        }
    }

    var avPosition: AVCaptureDevice.Position {
        switch self {
        case .front: .front
        case .back: .back
        }
    }
}

/// Manages camera recording and teleprompter state
@MainActor
final class RecordingService: ObservableObject {
    // Camera
    let captureSession = AVCaptureSession()
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var cameraPermissionGranted = false
    @Published var micPermissionGranted = false
    @Published var errorMessage: String?
    @Published var lastRecordedURL: URL?
    @Published var cameraPosition: CameraPosition = .front

    // Teleprompter
    @Published var scrollSpeed: Double = 1.0 // 0.5x to 3.0x
    @Published var fontSize: CGFloat = 24 // 18, 24, or 32
    @Published var isScrolling = false
    @Published var scrollProgress: Double = 0

    private var movieOutput = AVCaptureMovieFileOutput()
    private var recordingDelegate: RecordingDelegate?
    private var durationTimer: Timer?
    private var currentOutputURL: URL?

    // MARK: - Permissions

    func requestPermissions() async {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if cameraStatus == .notDetermined {
            cameraPermissionGranted = await AVCaptureDevice.requestAccess(for: .video)
        } else {
            cameraPermissionGranted = cameraStatus == .authorized
        }

        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        if micStatus == .notDetermined {
            micPermissionGranted = await AVCaptureDevice.requestAccess(for: .audio)
        } else {
            micPermissionGranted = micStatus == .authorized
        }
    }

    var hasAllPermissions: Bool {
        cameraPermissionGranted && micPermissionGranted
    }

    // MARK: - Camera Setup

    func setupCamera() {
        setupCamera(position: cameraPosition)
    }

    func setupCamera(position: CameraPosition) {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high

        // Remove existing inputs
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }

        // Remove existing outputs
        for output in captureSession.outputs {
            captureSession.removeOutput(output)
        }

        // Camera
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position.avPosition),
              let videoInput = try? AVCaptureDeviceInput(device: camera),
              captureSession.canAddInput(videoInput) else {
            errorMessage = "Could not access \(position.displayName.lowercased()) camera"
            captureSession.commitConfiguration()
            return
        }
        captureSession.addInput(videoInput)

        // Microphone
        if let mic = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: mic),
           captureSession.canAddInput(audioInput) {
            captureSession.addInput(audioInput)
        }

        // Movie output
        movieOutput = AVCaptureMovieFileOutput()
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
        }

        captureSession.commitConfiguration()

        cameraPosition = position

        Task.detached { [captureSession] in
            captureSession.startRunning()
        }
    }

    func teardownCamera() {
        Task.detached { [captureSession] in
            captureSession.stopRunning()
        }
    }

    func switchCamera() {
        let newPosition: CameraPosition = cameraPosition == .front ? .back : .front
        setupCamera(position: newPosition)
    }

    // MARK: - Recording

    func startRecording(scriptID: UUID) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let recordingsDir = documentsPath.appendingPathComponent("recordings", isDirectory: true)

        try? FileManager.default.createDirectory(at: recordingsDir, withIntermediateDirectories: true)

        let outputURL = recordingsDir.appendingPathComponent("\(scriptID.uuidString).mov")

        // Remove existing file if any
        try? FileManager.default.removeItem(at: outputURL)

        let delegate = RecordingDelegate { [weak self] url, error in
            Task { @MainActor in
                self?.didFinishRecording(url: url, error: error)
            }
        }
        recordingDelegate = delegate
        currentOutputURL = outputURL

        movieOutput.startRecording(to: outputURL, recordingDelegate: delegate)
        isRecording = true
        recordingDuration = 0

        durationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.recordingDuration += 0.1
            }
        }
    }

    func stopRecording() {
        movieOutput.stopRecording()
        durationTimer?.invalidate()
        durationTimer = nil
        isRecording = false
    }

    private func didFinishRecording(url: URL?, error: Error?) {
        if let error {
            errorMessage = "Recording failed: \(error.localizedDescription)"
        }
        lastRecordedURL = url
        isScrolling = false
    }

    /// URL for a script's recording file
    func recordingURL(for scriptID: UUID) -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = documentsPath.appendingPathComponent("recordings/\(scriptID.uuidString).mov")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    // MARK: - Teleprompter

    func startScrolling() {
        isScrolling = true
    }

    func pauseScrolling() {
        isScrolling = false
    }

    func resetScroll() {
        scrollProgress = 0
        isScrolling = false
    }

    /// Formatted recording duration (MM:SS.S)
    var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        let tenths = Int((recordingDuration.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
    }
}

// MARK: - Recording Delegate

private class RecordingDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
    let completion: (URL?, Error?) -> Void

    init(completion: @escaping (URL?, Error?) -> Void) {
        self.completion = completion
    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection], error: Error?) {
        completion(error == nil ? outputFileURL : nil, error)
    }
}
