import SwiftUI
import AVFoundation
import ComposableArchitecture

/// Full-screen recording view with camera preview, teleprompter overlay, and controls
struct RecordingView: View {
    @Bindable var store: StoreOf<TeleprompterFeature>
    @ObservedObject var scriptStorage: ScriptStorage
    @ObservedObject var recordingService: RecordingService
    @Environment(\.dismiss) private var dismiss

    @State private var hasSetupCamera = false
    @State private var showScriptPicker = false
    @State private var showPostRecording = false

    private var currentScript: Script? {
        guard let id = store.selectedScriptID else { return nil }
        return scriptStorage.script(byID: id)
    }

    var body: some View {
        ZStack {
            // Layer 1: Camera preview
            if recordingService.hasAllPermissions {
                CameraPreviewView(session: recordingService.captureSession)
                    .ignoresSafeArea()
            } else {
                permissionRequestView
            }

            // Layer 2: Teleprompter text overlay
            if let script = currentScript {
                TeleprompterOverlay(
                    text: script.fullScriptText,
                    fontSize: recordingService.fontSize,
                    speed: recordingService.scrollSpeed,
                    isScrolling: $recordingService.isScrolling,
                    scrollProgress: $recordingService.scrollProgress
                )
                .ignoresSafeArea()
            }

            // Layer 3: Controls
            VStack {
                // Top bar
                HStack {
                    Button {
                        recordingService.teardownCamera()
                        store.send(.dismissRecording)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }

                    Spacer()

                    // Camera switch
                    Button {
                        recordingService.switchCamera()
                        store.send(.switchCamera)
                    } label: {
                        Image(systemName: "camera.rotate")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }

                    Button { showScriptPicker = true } label: {
                        Label("Scripts", systemImage: "text.book.closed")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Spacer()
            }

            // Bottom controls
            RecordingControlsView(
                scriptTitle: currentScript?.title ?? "Select a script",
                isRecording: recordingService.isRecording,
                duration: recordingService.formattedDuration,
                scrollSpeed: $recordingService.scrollSpeed,
                fontSize: $recordingService.fontSize,
                onRecord: {
                    guard let script = currentScript else { return }
                    recordingService.startRecording(scriptID: script.scriptID)
                    recordingService.startScrolling()
                    store.send(.startRecording)
                },
                onStop: {
                    recordingService.stopRecording()
                    recordingService.pauseScrolling()
                    store.send(.stopRecording)
                },
                onToggleScroll: {
                    if recordingService.isScrolling {
                        recordingService.pauseScrolling()
                    } else {
                        recordingService.startScrolling()
                    }
                    store.send(.toggleScrolling)
                }
            )
        }
        .onAppear {
            if !hasSetupCamera {
                Task {
                    await recordingService.requestPermissions()
                    if recordingService.hasAllPermissions {
                        recordingService.setupCamera()
                        store.send(.permissionsResult(true))
                    } else {
                        store.send(.permissionsResult(false))
                    }
                    hasSetupCamera = true
                }
            }
        }
        .onChange(of: recordingService.lastRecordedURL) { _, newURL in
            if newURL != nil {
                showPostRecording = true
            }
        }
        .sheet(isPresented: $showPostRecording, onDismiss: {
            recordingService.lastRecordedURL = nil
        }) {
            if let url = recordingService.lastRecordedURL, let script = currentScript {
                PostRecordingView(
                    videoURL: url,
                    script: script,
                    scriptStorage: scriptStorage,
                    onKeep: {
                        scriptStorage.markRecorded(script)
                        syncScripts()
                        recordingService.teardownCamera()
                        store.send(.dismissRecording)
                        dismiss()
                    },
                    onReRecord: {
                        recordingService.resetScroll()
                        showPostRecording = false
                    },
                    onDiscard: {
                        try? FileManager.default.removeItem(at: url)
                        showPostRecording = false
                    }
                )
                .presentationDetents([.medium, .large])
            }
        }
        .sheet(isPresented: $showScriptPicker) {
            NavigationStack {
                scriptPickerList
            }
            .presentationDetents([.medium, .large])
        }
        .statusBarHidden()
    }

    // MARK: - Permission Request

    @ViewBuilder
    private var permissionRequestView: some View {
        VStack(spacing: 20) {
            Image(systemName: "video.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Camera & Microphone Access")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Teleprompter Pro needs camera and microphone access to record your videos.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Script Picker

    @ViewBuilder
    private var scriptPickerList: some View {
        List {
            ForEach(scriptStorage.scripts, id: \.scriptID) { script in
                Button {
                    store.send(.selectScript(script.scriptID))
                    recordingService.resetScroll()
                    showScriptPicker = false
                } label: {
                    HStack {
                        Text(script.title)
                            .font(.body)
                            .foregroundStyle(.primary)
                        Spacer()
                        if script.status != .notRecorded {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                        }
                        if store.selectedScriptID == script.scriptID {
                            Image(systemName: "play.fill")
                                .foregroundStyle(.indigo)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .navigationTitle("Choose Script")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { showScriptPicker = false }
            }
        }
    }

    private func syncScripts() {
        let items = scriptStorage.scripts.map { TeleprompterFeature.ScriptItem(from: $0) }
        store.send(.scriptsLoaded(items))
    }
}
