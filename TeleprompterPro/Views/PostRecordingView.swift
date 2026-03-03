import SwiftUI
import AVKit

/// Shown after a recording finishes -- preview, keep, re-record, or discard
struct PostRecordingView: View {
    let videoURL: URL
    let script: Script
    @ObservedObject var scriptStorage: ScriptStorage
    let onKeep: () -> Void
    let onReRecord: () -> Void
    let onDiscard: () -> Void

    @State private var player: AVPlayer?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Video preview
                if let player {
                    VideoPlayer(player: player)
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.gray.opacity(0.2))
                        .frame(height: 300)
                        .overlay {
                            ProgressView()
                        }
                        .padding(.horizontal)
                }

                // Script info
                VStack(alignment: .leading, spacing: 8) {
                    Text(script.title)
                        .font(.headline)

                    Text("\(script.wordCount) words")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    Button(action: onKeep) {
                        Label("Keep Recording", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)

                    Button(action: onReRecord) {
                        Label("Re-Record", systemImage: "arrow.counterclockwise")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button(role: .destructive, action: onDiscard) {
                        Label("Discard", systemImage: "trash")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Recording Complete")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                player = AVPlayer(url: videoURL)
            }
        }
    }
}
