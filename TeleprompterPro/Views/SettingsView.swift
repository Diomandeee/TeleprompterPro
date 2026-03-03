import SwiftUI
import ComposableArchitecture

/// Settings tab for configuring scroll speed, font size, and camera defaults
struct SettingsView: View {
    @Bindable var store: StoreOf<TeleprompterFeature>
    @ObservedObject var recordingService: RecordingService

    var body: some View {
        NavigationStack {
            Form {
                Section("Teleprompter") {
                    HStack {
                        Text("Default Scroll Speed")
                        Spacer()
                        Text("\(store.scrollSpeed, specifier: "%.1f")x")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $store.scrollSpeed, in: 0.5...3.0, step: 0.25) {
                        Text("Scroll Speed")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Default Font Size")
                        Picker("Font Size", selection: $store.fontSize) {
                            Text("Small (18)").tag(CGFloat(18))
                            Text("Medium (24)").tag(CGFloat(24))
                            Text("Large (32)").tag(CGFloat(32))
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Section("Camera") {
                    Picker("Default Camera", selection: $store.cameraPosition) {
                        Text("Front").tag(CameraPosition.front)
                        Text("Back").tag(CameraPosition.back)
                    }
                }

                Section("Preview") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sample Teleprompter Text")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("This is what your teleprompter text will look like at the current font size. Adjust the settings above to find what works best for you.")
                            .font(.system(size: store.fontSize, weight: .medium))
                            .lineSpacing(store.fontSize * 0.5)
                            .padding()
                            .background(.black.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
