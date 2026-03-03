import Foundation

/// Tracks a batch recording session with ordered script queue
struct RecordingSession: Identifiable, Codable, Hashable {
    let id: UUID
    var scriptIDs: [UUID]
    var currentIndex: Int
    var status: SessionStatus
    var startedAt: Date?
    var completedAt: Date?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        scriptIDs: [UUID],
        currentIndex: Int = 0,
        status: SessionStatus = .pending,
        startedAt: Date? = nil,
        completedAt: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.scriptIDs = scriptIDs
        self.currentIndex = currentIndex
        self.status = status
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.createdAt = createdAt
    }

    var totalScripts: Int {
        scriptIDs.count
    }

    var completedCount: Int {
        currentIndex
    }

    var progress: Double {
        guard totalScripts > 0 else { return 0 }
        return Double(completedCount) / Double(totalScripts)
    }

    var currentScriptID: UUID? {
        guard currentIndex < scriptIDs.count else { return nil }
        return scriptIDs[currentIndex]
    }

    var isComplete: Bool {
        currentIndex >= scriptIDs.count
    }
}

enum SessionStatus: String, Codable, CaseIterable {
    case pending
    case inProgress = "in_progress"
    case paused
    case completed

    var displayName: String {
        switch self {
        case .pending: "Pending"
        case .inProgress: "In Progress"
        case .paused: "Paused"
        case .completed: "Completed"
        }
    }
}
