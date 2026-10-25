import ActivityKit
import Foundation

// All ActivityKit side effects are serialized. Clearing a workspace is ordered
// after any in-flight update, so a suspended update cannot resurrect old work.
actor TokiLiveActivities {
    private var activities: [String: Activity<TokiActivityAttributes>] = [:]
    private var turns: [String: String] = [:]
    private var generation: UUID?
    private let enabled: Bool

    init(enabled: Bool) { self.enabled = enabled }

    func reset(generation: UUID) async {
        self.generation = generation
        guard enabled else { return }
        let old = Array(activities.values)
        activities = [:]; turns = [:]
        // Include survivors from a previous process. Work is not restored from
        // lock-screen data before fresh, authenticated server authorization.
        let survivors = Activity<TokiActivityAttributes>.activities
        for activity in old + survivors {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    func publish(id: String, messageID: String, state: TokiActivityAttributes.ContentState, url: URL,
                 generation: UUID, allowStart: Bool) async {
        guard enabled, self.generation == generation else { return }
        if let old = activities[id], turns[id] != messageID {
            activities[id] = nil; turns[id] = nil
            await old.end(nil, dismissalPolicy: .immediate)
        }
        let content = ActivityContent(state: state,
                                      staleDate: state.phase.active ? state.observedAt.addingTimeInterval(60) : nil)
        if let activity = activities[id], activity.activityState == .active || activity.activityState == .stale {
            if state.phase.active {
                await activity.update(content)
            } else {
                // Keep the handle until workspace clear/revocation, including
                // the short terminal presentation on the Lock Screen.
                let dismissal: ActivityUIDismissalPolicy = state.phase == .disconnected
                    ? .immediate : .after(Date().addingTimeInterval(60))
                await activity.end(content, dismissalPolicy: dismissal)
                if state.phase == .disconnected { activities[id] = nil; turns[id] = nil }
            }
        } else if activities[id] == nil, state.phase.active, allowStart, ActivityAuthorizationInfo().areActivitiesEnabled {
            // A user's dismissal is final for this turn. A follow-up with a
            // different message UUID can create a new activity, never this poll.
            // Local-only for now. APNs integration replaces nil with .token and
            // binds each per-activity token to authenticated work on the server.
            if let activity = try? Activity.request(attributes: TokiActivityAttributes(conversationURL: url, messageID: messageID),
                                                    content: content, pushType: nil) {
                activities[id] = activity; turns[id] = messageID
            }
        }
    }

    func remove(id: String, generation: UUID) async {
        guard self.generation == generation, let activity = activities.removeValue(forKey: id) else { return }
        turns[id] = nil
        await activity.end(nil, dismissalPolicy: .immediate)
    }
}
