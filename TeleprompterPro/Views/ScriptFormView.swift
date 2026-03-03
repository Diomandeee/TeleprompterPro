import SwiftUI
import ComposableArchitecture

/// Form for creating or editing a script
struct ScriptFormView: View {
    @Bindable var store: StoreOf<TeleprompterFeature>
    @ObservedObject var scriptStorage: ScriptStorage
    let isEditing: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Script title", text: $store.formTitle)
                }

                Section("Hook") {
                    TextEditor(text: $store.formHook)
                        .frame(minHeight: 60)
                }

                Section("Setup") {
                    TextEditor(text: $store.formSetup)
                        .frame(minHeight: 60)
                }

                Section("Turn") {
                    TextEditor(text: $store.formTurn)
                        .frame(minHeight: 60)
                }

                Section("Closer") {
                    TextEditor(text: $store.formCloser)
                        .frame(minHeight: 60)
                }

                // Preview
                if !store.formTitle.isEmpty {
                    Section("Preview") {
                        let previewText = [store.formHook, store.formSetup, store.formTurn, store.formCloser]
                            .filter { !$0.isEmpty }
                            .joined(separator: "\n\n")
                        let wordCount = previewText.split(separator: " ").count
                        VStack(alignment: .leading, spacing: 8) {
                            Text(previewText)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .lineLimit(6)

                            Text("\(wordCount) words")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Script" : "New Script")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        store.send(.dismissScriptForm)
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveScript()
                        dismiss()
                    }
                    .disabled(store.formTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func saveScript() {
        if isEditing, let editID = store.editingScriptID,
           let script = scriptStorage.script(byID: editID) {
            scriptStorage.updateScript(
                script,
                title: store.formTitle,
                hook: store.formHook,
                setup: store.formSetup,
                turn: store.formTurn,
                closer: store.formCloser
            )
        } else {
            scriptStorage.addScript(
                title: store.formTitle,
                hook: store.formHook,
                setup: store.formSetup,
                turn: store.formTurn,
                closer: store.formCloser
            )
        }
        let items = scriptStorage.scripts.map { TeleprompterFeature.ScriptItem(from: $0) }
        store.send(.scriptsLoaded(items))
        store.send(.dismissScriptForm)
    }
}
