import SwiftUI
import ComposableArchitecture
import OpenClawCore

@main
struct TeleprompterProApp: App {
    init() {
        KeychainHelper.service = "com.openclaw.teleprompterpro"
    }

    var body: some Scene {
        WindowGroup {
            TeleprompterRootView(
                store: Store(initialState: TeleprompterFeature.State()) {
                    TeleprompterFeature()
                }
            )
        }
    }
}
