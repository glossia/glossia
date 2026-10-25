import ActivityKit
import Foundation

// Shared verbatim with the WidgetKit extension. This is the entire lock-screen
// payload: never add conversation titles, prompts, messages, or account names.
struct TokiActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var phase: TokiWorkPhase
        var observedAt: Date
        var startedAt: Date
        var endedAt: Date?
    }

    // Produced by GlossiaDestination.url (Rust's canonical link contract).
    var conversationURL: URL
    // Durable user-message UUID, not message content. One activity per turn.
    var messageID: String
}

enum TokiWorkPhase: String, Codable, Hashable {
    case queued, running, completed, failed, disconnected

    var active: Bool { self == .queued || self == .running }

    var label: String {
        switch self {
        case .queued: String(localized: "Waiting for Toki")
        case .running: String(localized: "Toki is thinking")
        case .completed: String(localized: "Toki finished")
        case .failed: String(localized: "Toki couldn't finish")
        case .disconnected: String(localized: "Open Glossia to check Toki")
        }
    }
}
