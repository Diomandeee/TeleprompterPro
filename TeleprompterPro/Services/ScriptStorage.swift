import Foundation
import SwiftData

/// Manages script CRUD operations via SwiftData
@MainActor
final class ScriptStorage: ObservableObject {
    let modelContainer: ModelContainer
    let modelContext: ModelContext

    @Published var scripts: [Script] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    init() {
        do {
            let schema = Schema([Script.self])
            let config = ModelConfiguration(schema: schema)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
            modelContext = modelContainer.mainContext
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
        fetchScripts()
        if scripts.isEmpty {
            seedSampleScripts()
        }
    }

    // MARK: - Fetch

    func fetchScripts() {
        let descriptor = FetchDescriptor<Script>(
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            scripts = try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Failed to fetch scripts: \(error.localizedDescription)"
        }
    }

    func script(byID id: UUID) -> Script? {
        scripts.first { $0.scriptID == id }
    }

    // MARK: - CRUD

    func addScript(
        title: String,
        hook: String = "",
        setup: String = "",
        turn: String = "",
        closer: String = "",
        hashtags: [String] = [],
        estimatedDuration: Int = 60
    ) {
        let script = Script(
            title: title,
            hook: hook,
            setup: setup,
            turn: turn,
            closer: closer,
            hashtags: hashtags,
            estimatedDuration: estimatedDuration,
            sortOrder: scripts.count
        )
        modelContext.insert(script)
        save()
        fetchScripts()
    }

    func updateScript(
        _ script: Script,
        title: String? = nil,
        hook: String? = nil,
        setup: String? = nil,
        turn: String? = nil,
        closer: String? = nil
    ) {
        if let title { script.title = title }
        if let hook { script.hook = hook }
        if let setup { script.setup = setup }
        if let turn { script.turn = turn }
        if let closer { script.closer = closer }
        script.updatedAt = .now
        save()
        fetchScripts()
    }

    func markRecorded(_ script: Script) {
        script.recordingStatus = RecordingStatus.recorded.rawValue
        script.updatedAt = .now
        save()
        fetchScripts()
    }

    func updateRecordingStatus(_ script: Script, status: RecordingStatus) {
        script.recordingStatus = status.rawValue
        script.updatedAt = .now
        save()
        fetchScripts()
    }

    func deleteScript(_ script: Script) {
        modelContext.delete(script)
        save()
        fetchScripts()
    }

    func deleteScript(byID id: UUID) {
        guard let script = script(byID: id) else { return }
        deleteScript(script)
    }

    // MARK: - Persistence

    private func save() {
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }

    // MARK: - Seed Data

    private func seedSampleScripts() {
        let samples: [(String, String, String, String, String)] = [
            (
                "Why AI Won't Replace Creators",
                "Everyone keeps saying AI is coming for your job. But here's what they're NOT telling you...",
                "AI can generate content at scale, sure. But there's one thing it absolutely cannot replicate.",
                "YOUR lived experience. Your specific story. The way you tell it with YOUR voice and YOUR face.",
                "So stop worrying about AI replacing you and start using it as your creative co-pilot. Link in bio."
            ),
            (
                "3 Books That Changed My Business",
                "These 3 books completely transformed how I run my business, and none of them are what you'd expect.",
                "Book one: The Almanack of Naval Ravikant. Not a business book, but it rewired how I think about leverage and wealth creation.",
                "Book two: Show Your Work by Austin Kleon. It convinced me to build in public. Book three: The Mom Test - it taught me how to actually talk to customers.",
                "Save this and grab at least one of these. Trust me, your future self will thank you."
            ),
            (
                "Morning Routine for Productivity",
                "I tried the 5AM morning routine for 30 days and here's what actually happened.",
                "The first week was brutal. But by week two, something shifted. I was getting more done before 9AM than I used to get done all day.",
                "But here's the twist - it wasn't the early wake-up that mattered. It was having 2 hours of uninterrupted focus before the world woke up.",
                "The real hack isn't waking up early. It's protecting your focus time. Whenever that works for you. Follow for more productivity tips."
            ),
            (
                "Solo Founder Mistakes",
                "I've been a solo founder for 3 years. Here are the 3 biggest mistakes I made so you don't have to.",
                "Mistake one: Building in stealth for too long. I spent 6 months building before talking to a single customer. Don't do that.",
                "Mistake two: Trying to do everything myself. Hire help early, even if it's just a VA for 5 hours a week. Mistake three: Not setting boundaries. Burnout is real and it will catch up with you.",
                "Which one of these hit home? Drop a comment below. And follow for more real talk about building solo."
            ),
            (
                "The Future of Content Creation",
                "Content creation in 2026 looks NOTHING like it did two years ago. Here's what changed.",
                "First, AI tools went from novelty to necessity. Second, short-form video isn't just TikTok anymore - it's everywhere. Third, community-driven content is outperforming algorithmic content.",
                "But the biggest shift? Authenticity isn't just a buzzword anymore. Audiences can smell scripted content from a mile away. The creators winning right now are the ones being genuinely themselves.",
                "The playbook has changed. Are you keeping up? Follow for more creator economy insights."
            ),
        ]

        for (index, sample) in samples.enumerated() {
            let script = Script(
                title: sample.0,
                hook: sample.1,
                setup: sample.2,
                turn: sample.3,
                closer: sample.4,
                hashtags: ["contentcreator", "creator", "tips"],
                estimatedDuration: 60,
                sortOrder: index
            )
            modelContext.insert(script)
        }
        save()
        fetchScripts()
    }
}
