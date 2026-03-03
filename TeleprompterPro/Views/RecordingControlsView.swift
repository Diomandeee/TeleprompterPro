import SwiftUI

struct RecordingControlsView: View {
    let scriptTitle: String
    let isRecording: Bool
    let duration: String
    @Binding var scrollSpeed: Double
    @Binding var fontSize: CGFloat
    let onRecord: () -> Void
    let onStop: () -> Void
    let onToggleScroll: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Script title
            Text(scriptTitle)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())

            Spacer()

            // Bottom controls
            VStack(spacing: 12) {
                // Duration
                if isRecording {
                    Text(duration)
                        .font(.title3.monospaced())
                        .foregroundStyle(.red)
                        .fontWeight(.bold)
                }

                HStack(spacing: 24) {
                    // Font size buttons
                    HStack(spacing: 8) {
                        fontSizeButton(size: 18)
                        fontSizeButton(size: 24)
                        fontSizeButton(size: 32)
                    }

                    Spacer()

                    // Record button
                    Button(action: isRecording ? onStop : onRecord) {
                        Circle()
                            .fill(isRecording ? .red : .white)
                            .frame(width: 72, height: 72)
                            .overlay {
                                if isRecording {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(.white)
                                        .frame(width: 28, height: 28)
                                } else {
                                    Circle()
                                        .fill(.red)
                                        .frame(width: 62, height: 62)
                                }
                            }
                    }

                    Spacer()

                    // Scroll toggle
                    Button(action: onToggleScroll) {
                        Image(systemName: "text.line.first.and.arrowtriangle.forward")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }

                // Speed slider
                HStack {
                    Text("Speed")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    Slider(value: $scrollSpeed, in: 0.5...3.0, step: 0.25)
                        .tint(.white)
                    Text("\(scrollSpeed, specifier: "%.1f")x")
                        .font(.caption.monospaced())
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 36)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
        }
    }

    @ViewBuilder
    private func fontSizeButton(size: CGFloat) -> some View {
        Button {
            withAnimation { fontSize = size }
        } label: {
            Text("A")
                .font(.system(size: size == 18 ? 12 : size == 24 ? 16 : 20))
                .fontWeight(fontSize == size ? .bold : .regular)
                .foregroundStyle(fontSize == size ? .white : .white.opacity(0.5))
                .frame(width: 32, height: 32)
                .background(fontSize == size ? .white.opacity(0.2) : .clear)
                .clipShape(Circle())
        }
    }
}
