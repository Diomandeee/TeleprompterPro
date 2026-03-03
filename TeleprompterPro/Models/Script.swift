import Foundation
import SwiftData

/// A teleprompter script with structured sections for recording
@Model
final class Script {
    @Attribute(.unique) var scriptID: UUID
    var title: String
    var hook: String
    var setup: String
    var turn: String
    var closer: String
    var hashtags: [String]
    var estimatedDuration: Int // seconds
    var recordingStatus: String // maps to RecordingStatus.rawValue
    var createdAt: Date
    var updatedAt: Date
    var recordingFileURL: String?
    var sortOrder: Int

    init(
        scriptID: UUID = UUID(),
        title: String,
        hook: String = "",
        setup: String = "",
        turn: String = "",
        closer: String = "",
        hashtags: [String] = [],
        estimatedDuration: Int = 60,
        recordingStatus: String = RecordingStatus.notRecorded.rawValue,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        recordingFileURL: String? = nil,
        sortOrder: Int = 0
    ) {
        self.scriptID = scriptID
        self.title = title
        self.hook = hook
        self.setup = setup
        self.turn = turn
        self.closer = closer
        self.hashtags = hashtags
        self.estimatedDuration = estimatedDuration
        self.recordingStatus = recordingStatus
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.recordingFileURL = recordingFileURL
        self.sortOrder = sortOrder
    }

    /// Full script text for teleprompter display
    var fullScriptText: String {
        [hook, setup, turn, closer]
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }

    /// Word count for estimated reading time
    var wordCount: Int {
        fullScriptText.split(separator: " ").count
    }

    var status: RecordingStatus {
        RecordingStatus(rawValue: recordingStatus) ?? .notRecorded
    }
}

enum RecordingStatus: String, Codable, CaseIterable {
    case notRecorded = "not_recorded"
    case recorded
    case edited
    case scheduled
    case posted

    var displayName: String {
        switch self {
        case .notRecorded: "Not Recorded"
        case .recorded: "Recorded"
        case .edited: "Edited"
        case .scheduled: "Scheduled"
        case .posted: "Posted"
        }
    }

    var iconName: String {
        switch self {
        case .notRecorded: "circle"
        case .recorded: "checkmark.circle"
        case .edited: "wand.and.stars"
        case .scheduled: "calendar.badge.clock"
        case .posted: "checkmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .notRecorded: "gray"
        case .recorded: "blue"
        case .edited: "orange"
        case .scheduled: "purple"
        case .posted: "green"
        }
    }
}
