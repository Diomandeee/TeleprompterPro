import SwiftUI
import ComposableArchitecture

/// Root view with tabbed navigation: Scripts, Record, Settings
struct TeleprompterRootView: View {
    @Bindable var store: StoreOf<TeleprompterFeature>
    @StateObject private var scriptStorage = ScriptStorage()
    @StateObject private var recordingService = RecordingService()

    var body: some View {
        TabView(selection: $store.selectedTab.sending(\.selectTab)) {
            // Scripts Tab
            ScriptListView(store: store, scriptStorage: scriptStorage)
                .tabItem {
                    Label("Scripts", systemImage: "text.book.closed")
                }
                .tag(TeleprompterFeature.State.Tab.scripts)

            // Record Tab
            RecordLaunchView(store: store, scriptStorage: scriptStorage, recordingService: recordingService)
                .tabItem {
                    Label("Record", systemImage: "video.fill")
                }
                .tag(TeleprompterFeature.State.Tab.record)

            // Settings Tab
            SettingsView(store: store, recordingService: recordingService)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(TeleprompterFeature.State.Tab.settings)
        }
        .tint(.indigo)
        .onAppear {
            syncScripts()
            store.send(.onAppear)
        }
    }

    private func syncScripts() {
        let items = scriptStorage.scripts.map { TeleprompterFeature.ScriptItem(from: $0) }
        store.send(.scriptsLoaded(items))
    }
}
