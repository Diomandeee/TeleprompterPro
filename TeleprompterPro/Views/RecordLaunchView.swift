import SwiftUI
import ComposableArchitecture

/// Landing view for the Record tab -- pick a script then launch the recorder
struct RecordLaunchView: View {
    @Bindable var store: StoreOf<TeleprompterFeature>
    @ObservedObject var scriptStorage: ScriptStorage
    @ObservedObject var recordingService: RecordingService

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Hero
                VStack(spacing: 12) {
                    Image(systemName: "video.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.indigo)

                    Text("Record with Teleprompter")
                        .font(.title2.bold())

                    Text("Select a script below, then tap Record to start.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)

                if scriptStorage.scripts.isEmpty {
                    VStack(spacing: 12) {
                        Text("No scripts available.")
                            .foregroundStyle(.secondary)

                        Button {
                            store.send(.selectTab(.scripts))
                            store.send(.showNewScript)
                        } label: {
                            Label("Create a Script", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.indigo)
                    }
                    .padding(.top, 20)
                } else {
                    // Script picker
                    List {
                        ForEach(scriptStorage.scripts, id: \.scriptID) { script in
                            Button {
                                store.send(.showRecording(script.scriptID))
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(script.title)
                                            .font(.headline)
                                            .foregroundStyle(.primary)

                                        Text(script.hook)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    if script.status != .notRecorded {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                            .font(.caption)
                                    }

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }

                Spacer()
            }
            .navigationTitle("Record")
            .fullScreenCover(isPresented: $store.isShowingRecording) {
                RecordingView(
                    store: store,
                    scriptStorage: scriptStorage,
                    recordingService: recordingService
                )
            }
        }
    }
}
