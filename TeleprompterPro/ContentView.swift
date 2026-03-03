import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "star.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("Teleprompter Pro")
                    .font(.largeTitle.bold())

                Text("Welcome to Teleprompter Pro")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Teleprompter Pro")
        }
    }
}

#Preview {
    ContentView()
}
