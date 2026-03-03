import SwiftUI

struct TeleprompterOverlay: View {
    let text: String
    let fontSize: CGFloat
    let speed: Double
    @Binding var isScrolling: Bool
    @Binding var scrollProgress: Double

    @State private var offset: CGFloat = 0
    @State private var textHeight: CGFloat = 0

    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Semi-transparent background
                Color.black.opacity(0.3)

                // Reading guide line
                Rectangle()
                    .fill(.white.opacity(0.15))
                    .frame(height: fontSize * 2)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.35)

                // Scrolling text
                Text(text)
                    .font(.system(size: fontSize, weight: .medium))
                    .foregroundStyle(.white)
                    .lineSpacing(fontSize * 0.5)
                    .padding(.horizontal, 24)
                    .background(
                        GeometryReader { textGeo in
                            Color.clear.onAppear {
                                textHeight = textGeo.size.height
                            }
                        }
                    )
                    .offset(y: geo.size.height * 0.35 - offset)
            }
            .onReceive(timer) { _ in
                guard isScrolling, textHeight > 0 else { return }
                let scrollRate = speed * 1.2 // pixels per frame at 60fps
                offset += scrollRate

                let maxOffset = textHeight
                if maxOffset > 0 {
                    scrollProgress = min(Double(offset / maxOffset), 1.0)
                }

                if offset >= textHeight {
                    isScrolling = false
                }
            }
            .onChange(of: isScrolling) { _, newValue in
                if !newValue && offset >= textHeight {
                    // Reset when finished
                }
            }
        }
        .allowsHitTesting(false)
    }
}
