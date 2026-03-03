import Foundation
import ComposableArchitecture
import AVFoundation

/// TCA Reducer managing the entire Teleprompter Pro lifecycle
@Reducer
struct TeleprompterFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        // Navigation
        var selectedTab: Tab = .scripts
        var isShowingRecording = false
        var isShowingSettings = false
        var isShowingNewScript = false
        var isShowingEditScript = false

        // Scripts
        var scripts: IdentifiedArrayOf<ScriptItem> = []
        var selectedScriptID: UUID?

        // Recording
        var recordingState: RecordingState = .idle
        var recordingDuration: TimeInterval = 0
        var lastRecordedURL: URL?
        var cameraPosition: CameraPosition = .front
        var hasPermissions = false

        // Teleprompter
        var scrollSpeed: Double = 1.0
        var fontSize: CGFloat = 24
        var isScrolling = false
        var scrollProgress: Double = 0

        // New/Edit Script form
        var editingScriptID: UUID?
        var formTitle: String = ""
        var formHook: String = ""
        var formSetup: String = ""
        var formTurn: String = ""
        var formCloser: String = ""

        var selectedScript: ScriptItem? {
            guard let id = selectedScriptID else { return nil }
            return scripts[id: id]
        }

        enum Tab: Equatable, Hashable {
            case scripts
            case record
            case settings
        }
    }

    // MARK: - Script Item (value type for TCA state)

    struct ScriptItem: Equatable, Identifiable {
        let id: UUID
        var title: String
        var hook: String
        var setup: String
        var turn: String
        var closer: String
        var hashtags: [String]
        var estimatedDuration: Int
        var recordingStatus: RecordingStatus
        var createdAt: Date
        var updatedAt: Date
        var sortOrder: Int

        var fullScriptText: String {
            [hook, setup, turn, closer]
                .filter { !$0.isEmpty }
                .joined(separator: "\n\n")
        }

        var wordCount: Int {
            fullScriptText.split(separator: " ").count
        }

        init(from script: Script) {
            self.id = script.scriptID
            self.title = script.title
            self.hook = script.hook
            self.setup = script.setup
            self.turn = script.turn
            self.closer = script.closer
            self.hashtags = script.hashtags
            self.estimatedDuration = script.estimatedDuration
            self.recordingStatus = script.status
            self.createdAt = script.createdAt
            self.updatedAt = script.updatedAt
            self.sortOrder = script.sortOrder
        }
    }

    enum RecordingState: Equatable {
        case idle
        case recording
        case paused
        case done
    }

    // MARK: - Action

    enum Action: BindableAction {
        case binding(BindingAction<State>)

        // Lifecycle
        case onAppear
        case scriptsLoaded([ScriptItem])
        case permissionsResult(Bool)

        // Navigation
        case selectTab(State.Tab)
        case showRecording(UUID?)
        case dismissRecording
        case showSettings
        case dismissSettings
        case showNewScript
        case showEditScript(UUID)
        case dismissScriptForm

        // Script management
        case selectScript(UUID)
        case deleteScript(UUID)
        case saveScript
        case refreshScripts

        // Recording
        case requestPermissions
        case setupCamera
        case teardownCamera
        case startRecording
        case stopRecording
        case recordingFinished(URL?)
        case switchCamera

        // Teleprompter
        case startScrolling
        case pauseScrolling
        case toggleScrolling
        case resetScroll
        case setScrollSpeed(Double)
        case setFontSize(CGFloat)

        // Duration timer
        case timerTick
    }

    // MARK: - Dependencies

    @Dependency(\.continuousClock) var clock

    // MARK: - Reducer

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            // MARK: Lifecycle

            case .onAppear:
                return .send(.refreshScripts)

            case .scriptsLoaded(let items):
                state.scripts = IdentifiedArray(uniqueElements: items)
                return .none

            case .permissionsResult(let granted):
                state.hasPermissions = granted
                return .none

            // MARK: Navigation

            case .selectTab(let tab):
                state.selectedTab = tab
                return .none

            case .showRecording(let scriptID):
                if let id = scriptID {
                    state.selectedScriptID = id
                }
                state.isShowingRecording = true
                return .send(.requestPermissions)

            case .dismissRecording:
                state.isShowingRecording = false
                state.recordingState = .idle
                state.recordingDuration = 0
                state.isScrolling = false
                state.scrollProgress = 0
                return .send(.teardownCamera)

            case .showSettings:
                state.isShowingSettings = true
                return .none

            case .dismissSettings:
                state.isShowingSettings = false
                return .none

            case .showNewScript:
                state.editingScriptID = nil
                state.formTitle = ""
                state.formHook = ""
                state.formSetup = ""
                state.formTurn = ""
                state.formCloser = ""
                state.isShowingNewScript = true
                return .none

            case .showEditScript(let id):
                guard let script = state.scripts[id: id] else { return .none }
                state.editingScriptID = id
                state.formTitle = script.title
                state.formHook = script.hook
                state.formSetup = script.setup
                state.formTurn = script.turn
                state.formCloser = script.closer
                state.isShowingEditScript = true
                return .none

            case .dismissScriptForm:
                state.isShowingNewScript = false
                state.isShowingEditScript = false
                state.editingScriptID = nil
                return .none

            // MARK: Script Management

            case .selectScript(let id):
                state.selectedScriptID = id
                return .none

            case .deleteScript:
                // Handled by the view via ScriptStorage
                return .send(.refreshScripts)

            case .saveScript:
                // Handled by the view via ScriptStorage
                return .merge(
                    .send(.dismissScriptForm),
                    .send(.refreshScripts)
                )

            case .refreshScripts:
                // The view observes ScriptStorage and sends scriptsLoaded
                return .none

            // MARK: Recording

            case .requestPermissions:
                return .none // Handled by RecordingService in the view

            case .setupCamera:
                return .none // Handled by RecordingService in the view

            case .teardownCamera:
                return .none // Handled by RecordingService in the view

            case .startRecording:
                state.recordingState = .recording
                state.recordingDuration = 0
                return .none

            case .stopRecording:
                state.recordingState = .done
                return .none

            case .recordingFinished(let url):
                state.lastRecordedURL = url
                state.recordingState = .done
                return .none

            case .switchCamera:
                state.cameraPosition = state.cameraPosition == .front ? .back : .front
                return .none

            // MARK: Teleprompter

            case .startScrolling:
                state.isScrolling = true
                return .none

            case .pauseScrolling:
                state.isScrolling = false
                return .none

            case .toggleScrolling:
                state.isScrolling.toggle()
                return .none

            case .resetScroll:
                state.scrollProgress = 0
                state.isScrolling = false
                return .none

            case .setScrollSpeed(let speed):
                state.scrollSpeed = speed
                return .none

            case .setFontSize(let size):
                state.fontSize = size
                return .none

            case .timerTick:
                if state.recordingState == .recording {
                    state.recordingDuration += 0.1
                }
                return .none
            }
        }
    }
}
