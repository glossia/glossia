import Combine
import Foundation

struct TokiWorkSnapshot: Equatable {
    let id: String
    let messageID: String
    var state: TokiActivityAttributes.ContentState
    let url: URL

    func visiblePhase(at now: Date) -> TokiWorkPhase {
        state.phase.active && now.timeIntervalSince(state.observedAt) >= 60 ? .disconnected : state.phase
    }
}

// App-owned, not conversation-owned. Only authenticated observations enter this
// store, and only foreground polling is allowed. No credential or history cache.
@MainActor
final class TokiWorkController: ObservableObject {
    @Published private(set) var snapshots: [String: TokiWorkSnapshot] = [:]
    let updates = PassthroughSubject<(String, [String: Any]), Never>()
    private var context: String?
    private var generation = UUID()
    private var foreground = false
    private var request: GlossiaRequest?
    private var destination: ((String) -> URL?)?
    private var authorized: () -> Bool = { false }
    private var polling: Task<Void, Never>?
    private var activityTask: Task<Void, Never>?
    private let activities: TokiLiveActivities
    private let now: () -> Date
    private var trackedSince: [String: Date] = [:]
    private var workTickets: [String: UUID] = [:]

    init(liveActivities: Bool = false, now: @escaping () -> Date = Date.init) {
        activities = TokiLiveActivities(enabled: liveActivities)
        self.now = now
    }

    func configure(context: String?, request: GlossiaRequest? = nil,
                   authorized: @escaping () -> Bool = { false }, destination: ((String) -> URL?)? = nil) {
        guard self.context != context else { return }
        generation = UUID()
        polling?.cancel(); polling = nil
        snapshots = [:]; trackedSince = [:]; workTickets = [:]
        self.context = context; self.request = request
        self.authorized = authorized; self.destination = destination
        let generation = generation
        enqueueActivity { activities in await activities.reset(generation: generation) }
    }

    // Also called on a signed-out cold launch to clear surviving activities.
    func clear() {
        generation = UUID()
        polling?.cancel(); polling = nil
        context = nil; request = nil; destination = nil; authorized = { false }
        snapshots = [:]; trackedSince = [:]; workTickets = [:]
        let generation = generation
        enqueueActivity { activities in await activities.reset(generation: generation) }
    }

    func setForeground(_ value: Bool) {
        foreground = value
        polling?.cancel(); polling = nil
        // Do not claim that background local polling can continue. ActivityKit
        // switches to its stale UI after 60 seconds without a server observation.
        if value { startPolling() }
    }

    func snapshot(_ id: String?, context: String?) -> TokiWorkSnapshot? {
        guard context == self.context, authorized(), let id else { return nil }
        return snapshots[id]
    }

    func observe(_ result: [String: Any], id: String, context: String,
                 sentMessageID: String? = nil, allowNewTurn: Bool = false) {
        guard self.context == context, authorized(),
              let conversation = result["conversation"] as? [String: Any],
              conversation["id"] as? String == id,
              let messages = result["messages"] as? [[String: Any]],
              let messageID = messages.last(where: { $0["role"] as? String == "user" })?["id"] as? String,
              UUID(uuidString: messageID) != nil,
              sentMessageID == nil || sentMessageID == messageID,
              let raw = conversation["status"] as? String,
              let phase = TokiWorkPhase(rawValue: raw), phase != .disconnected,
              let url = destination?(id) else { return }
        let date = now()
        let previous = snapshots[id]
        // Terminal history alone is not evidence of current work. It may still
        // render in the conversation, but must not start a Live Activity.
        guard phase.active || previous?.messageID == messageID || sentMessageID == messageID else { return }
        // Polling is only allowed to reconcile the turn it started with.
        // Changing turns needs a newly accepted Send or an explicit history read.
        guard previous == nil || previous?.messageID == messageID || sentMessageID != nil || allowNewTurn else { return }
        if previous?.messageID == messageID, [.completed, .failed].contains(previous?.state.phase), phase.active { return }
        if previous == nil {
            // Keep work bounded, even if a user opens many running conversations.
            guard snapshots.values.filter({ $0.state.phase.active }).count < 8 else { return }
            trackedSince[id] = date
            workTickets[id] = UUID()
        }
        let newRun = previous?.messageID != messageID || (phase.active && previous?.state.phase == .disconnected)
        if newRun { trackedSince[id] = date; workTickets[id] = UUID() }
        let state = TokiActivityAttributes.ContentState(
            phase: phase, observedAt: date,
            // Observation time is truthful; do not infer a server start time
            // from the conversation's mutable updated_at field.
            startedAt: newRun ? date : (previous?.state.startedAt ?? date),
            endedAt: phase.active ? nil : date)
        snapshots[id] = TokiWorkSnapshot(id: id, messageID: messageID, state: state, url: url)
        // Bound terminal history too. Its view can reconstruct from detail.
        if snapshots.count > 16, let oldest = snapshots.values.filter({ !$0.state.phase.active && $0.id != id })
            .min(by: { $0.state.observedAt < $1.state.observedAt }) {
            remove(oldest.id, context: context)
        }
        let generation = generation, allowStart = foreground
        enqueueActivity { activities in
            await activities.publish(id: id, messageID: messageID, state: state, url: url,
                                     generation: generation, allowStart: allowStart)
        }
        startPolling()
    }

    func remove(_ id: String, context: String) {
        guard self.context == context else { return }
        snapshots[id] = nil; trackedSince[id] = nil; workTickets[id] = nil
        let generation = generation
        enqueueActivity { activities in await activities.remove(id: id, generation: generation) }
    }

    // Internal to allow deterministic lifecycle tests with fixture requests.
    func refresh() async {
        guard foreground, let context, authorized(), let request else { return }
        let ticket = generation
        let ids = snapshots.values.filter { $0.state.phase.active }.map(\.id)
        for id in ids {
            guard ticket == generation, foreground, authorized(), !Task.isCancelled else { return }
            let workTicket = workTickets[id]
            // Stop fifteen minutes after observation, even when a backend job is
            // stuck. Reopening that conversation is an explicit fresh check.
            if now().timeIntervalSince(trackedSince[id] ?? now()) >= 900 {
                disconnect(id)
                continue
            }
            do {
                let result = try await request(["operation": "conversation", "action": "show", "id": id])
                guard ticket == generation, foreground, authorized(), !Task.isCancelled else { return }
                guard workTicket == workTickets[id], snapshots[id] != nil else { continue }
                guard (result["conversation"] as? [String: Any])?["id"] as? String == id else {
                    disconnect(id); continue
                }
                guard (result["messages"] as? [[String: Any]])?.last(where: { $0["role"] as? String == "user" })?["id"] as? String == snapshots[id]?.messageID,
                      let raw = (result["conversation"] as? [String: Any])?["status"] as? String,
                      TokiWorkPhase(rawValue: raw) != nil else {
                    disconnect(id); continue
                }
                observe(result, id: id, context: context)
                if snapshots[id]?.state.phase == TokiWorkPhase(rawValue: raw) { updates.send((id, result)) }
            } catch is CancellationError { return }
            catch {
                guard ticket == generation, foreground, authorized(), !Task.isCancelled else { return }
                guard workTicket == workTickets[id], snapshots[id] != nil else { continue }
                if let failure = error as? GlossiaFailure {
                    if ["rejected", "sign_in_required"].contains(failure.kind) { clear(); return }
                    if ["forbidden", "not_found"].contains(failure.kind) {
                        remove(id, context: context)
                        updates.send((id, [:]))
                        continue
                    }
                }
                disconnect(id)
            }
        }
    }

    private func disconnect(_ id: String) {
        guard var snapshot = snapshots[id] else { return }
        snapshot.state.phase = .disconnected
        snapshot.state.endedAt = min(now(), snapshot.state.observedAt.addingTimeInterval(60))
        snapshots[id] = snapshot
        let generation = generation
        enqueueActivity { activities in
            await activities.publish(id: id, messageID: snapshot.messageID, state: snapshot.state, url: snapshot.url,
                                     generation: generation, allowStart: false)
        }
    }

    private func startPolling() {
        guard foreground, authorized(), polling == nil, snapshots.values.contains(where: { $0.state.phase.active }) else { return }
        let ticket = generation
        polling = Task { [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(2)) } catch { return }
                guard let self, ticket == self.generation, self.foreground, self.authorized() else { return }
                await self.refresh()
                guard ticket == self.generation else { return }
                if !self.snapshots.values.contains(where: { $0.state.phase.active }) {
                    self.polling = nil
                    return
                }
            }
        }
    }

    private func enqueueActivity(_ action: @escaping (TokiLiveActivities) async -> Void) {
        let previous = activityTask, activities = activities
        activityTask = Task {
            await previous?.value
            await action(activities)
        }
    }
}
