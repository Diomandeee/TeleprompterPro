import SwiftUI
import ComposableArchitecture

/// Displays the user's scripts with add/edit/delete capabilities
struct ScriptListView: View {
    @Bindable var store: StoreOf<TeleprompterFeature>
    @ObservedObject var scriptStorage: ScriptStorage

    var body: some View {
        NavigationStack {
            Group {
                if scriptStorage.scripts.isEmpty {
                    emptyState
                } else {
                    scriptList
                }
            }
            .navigationTitle("Scripts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        store.send(.showNewScript)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $store.isShowingNewScript) {
                ScriptFormView(
                    store: store,
                    scriptStorage: scriptStorage,
                    isEditing: false
                )
            }
            .sheet(isPresented: $store.isShowingEditScript) {
                ScriptFormView(
                    store: store,
                    scriptStorage: scriptStorage,
                    isEditing: true
                )
            }
        }
    }

    @ViewBuilder
    private var scriptList: some View {
        List {
            ForEach(scriptStorage.scripts, id: \.scriptID) { script in
                ScriptRowView(script: script) {
                    store.send(.selectScript(script.scriptID))
                    store.send(.showRecording(script.scriptID))
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        scriptStorage.deleteScript(script)
                        syncScripts()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                    Button {
                        store.send(.showEditScript(script.scriptID))
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.orange)
                }
                .contextMenu {
                    Button {
                        store.send(.selectScript(script.scriptID))
                        store.send(.showRecording(script.scriptID))
                    } label: {
                        Label("Record", systemImage: "video.fill")
                    }

                    Button {
                        store.send(.showEditScript(script.scriptID))
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Divider()

                    Button(role: .destructive) {
                        scriptStorage.deleteScript(script)
                        syncScripts()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.book.closed")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)

            Text("No Scripts Yet")
                .font(.title2.bold())

            Text("Create your first script to start\nrecording with the teleprompter.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                store.send(.showNewScript)
            } label: {
                Label("Create Script", systemImage: "plus")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
        }
        .padding()
    }

    private func syncScripts() {
        let items = scriptStorage.scripts.map { TeleprompterFeature.ScriptItem(from: $0) }
        store.send(.scriptsLoaded(items))
    }
}

// MARK: - Script Row

struct ScriptRowView: View {
    let script: Script
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(script.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer()

                    statusBadge
                }

                Text(script.hook)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 12) {
                    Label("\(script.wordCount) words", systemImage: "text.word.spacing")
                    Label("~\(script.estimatedDuration)s", systemImage: "clock")
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        let status = script.status
        HStack(spacing: 4) {
            Image(systemName: status.iconName)
            Text(status.displayName)
        }
        .font(.caption2)
        .foregroundStyle(statusColor(status))
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(statusColor(status).opacity(0.1))
        .clipShape(Capsule())
    }

    private func statusColor(_ status: RecordingStatus) -> Color {
        switch status {
        case .notRecorded: .gray
        case .recorded: .blue
        case .edited: .orange
        case .scheduled: .purple
        case .posted: .green
        }
    }
}
