import Foundation
import Testing

@Suite @MainActor
struct TokiWorkTests {
    private let id = "93cf36a3-802e-4f91-9112-77d8a919efc5"
    private let first = "aaaaaaaa-802e-4f91-9112-77d8a919efc5"
    private let second = "bbbbbbbb-802e-4f91-9112-77d8a919efc5"

    private func result(_ phase: String, messageID: String? = nil) -> [String: Any] {
        ["conversation": ["id": id, "status": phase, "title": "Secret title"],
         "messages": [["id": messageID ?? first, "role": "user", "content": "Secret prompt"],
                      ["id": "assistant", "role": "assistant", "content": "Secret history"]]]
    }

    private func link(_ id: String) -> URL? {
        GlossiaDestination(screen: .conversation, server: "https://glossia.example.com",
                           organization: "acme", project: "website", id: id).url
    }

    private func configure(_ work: TokiWorkController, request: @escaping GlossiaRequest = { _ in [:] }) {
        work.configure(context: "account/workspace", request: request, authorized: { true }, destination: link)
    }

    @Test func idleHistoryAndUnacceptedWorkDoNotCreateActivityState() {
        let work = TokiWorkController()
        work.observe(result("running"), id: id, context: "account/workspace")
        #expect(work.snapshots.isEmpty)
        configure(work)
        work.observe(result("completed"), id: id, context: "account/workspace")
        work.observe(["conversation": ["id": id, "status": "running"], "messages": []], id: id, context: "account/workspace")
        work.observe(result("unknown"), id: id, context: "account/workspace")
        work.observe(result("queued"), id: id, context: "account/workspace", sentMessageID: second)
        #expect(work.snapshots.isEmpty)
    }

    @Test func activeTurnUsesObservedTimeAndEndsWithoutInventedProgress() throws {
        var date = Date(timeIntervalSince1970: 1000)
        let work = TokiWorkController(now: { date })
        configure(work)
        work.observe(result("queued"), id: id, context: "account/workspace", sentMessageID: first)
        #expect(work.snapshots[id]?.state.startedAt == date)
        date = date.addingTimeInterval(5)
        work.observe(result("running"), id: id, context: "account/workspace")
        let running = try #require(work.snapshots[id])
        #expect(running.state.phase == .running)
        #expect(running.state.startedAt == Date(timeIntervalSince1970: 1000))
        #expect(running.state.endedAt == nil)
        #expect(running.visiblePhase(at: date.addingTimeInterval(59)) == .running)
        #expect(running.visiblePhase(at: date.addingTimeInterval(60)) == .disconnected)
        date = date.addingTimeInterval(5)
        work.observe(result("completed"), id: id, context: "account/workspace")
        #expect(work.snapshots[id]?.state.endedAt == date)
        #expect(work.snapshots[id]?.state.phase == .completed)
        work.observe(result("running"), id: id, context: "account/workspace")
        #expect(work.snapshots[id]?.state.phase == .completed, "Older running observations cannot resurrect a terminal turn")
    }

    @Test func followupHasExactMessageIdentityAndFreshTimer() throws {
        var date = Date(timeIntervalSince1970: 1000)
        let work = TokiWorkController(now: { date })
        configure(work)
        work.observe(result("running"), id: id, context: "account/workspace", sentMessageID: first)
        work.observe(result("completed"), id: id, context: "account/workspace")
        date = date.addingTimeInterval(30)
        work.observe(result("queued", messageID: second), id: id, context: "account/workspace", sentMessageID: second)
        let followup = try #require(work.snapshots[id])
        #expect(followup.messageID == second && followup.state.startedAt == date && followup.state.endedAt == nil)
        work.observe(result("failed"), id: id, context: "account/workspace")
        #expect(work.snapshots[id] == followup, "An older turn must not finish the follow-up")
        work.observe(result("failed", messageID: second), id: id, context: "account/workspace")
        #expect(work.snapshots[id]?.state.phase == .failed)
    }

    @Test func synchronousCompletionOnlyBelongsToAcceptedSend() {
        let work = TokiWorkController()
        configure(work)
        work.observe(result("completed"), id: id, context: "account/workspace")
        #expect(work.snapshots.isEmpty)
        work.observe(result("completed"), id: id, context: "account/workspace", sentMessageID: first)
        #expect(work.snapshots[id]?.messageID == first)
        #expect(work.snapshots[id]?.state.phase == .completed)
        // The ActivityKit publisher never requests a terminal activity.
    }

    @Test func lockScreenPayloadIsGenericAndLinkRoundTripsThroughRust() throws {
        let work = TokiWorkController()
        configure(work)
        work.observe(result("running"), id: id, context: "account/workspace")
        let snapshot = try #require(work.snapshots[id])
        let attributes = TokiActivityAttributes(conversationURL: snapshot.url, messageID: snapshot.messageID)
        let encoder = JSONEncoder()
        let attributesData = try encoder.encode(attributes)
        let stateData = try encoder.encode(snapshot.state)
        let payload = String(decoding: attributesData + stateData, as: UTF8.self)
        #expect(!payload.contains("Secret"))
        let keys = try #require(JSONSerialization.jsonObject(with: stateData) as? [String: Any])
        #expect(Set(keys.keys) == ["phase", "observedAt", "startedAt"])
        let attributeKeys = try #require(JSONSerialization.jsonObject(with: attributesData) as? [String: Any])
        #expect(Set(attributeKeys.keys) == ["conversationURL", "messageID"])
        let destination = try GlossiaDestination.parse(snapshot.url)
        #expect(destination.id == id && destination.screen == .conversation)
        #expect(destination.url == snapshot.url)
    }

    @Test func workSurvivesClosingConversationAndReconcilesInForeground() async {
        let work = TokiWorkController()
        var calls = 0
        configure(work) { _ in calls += 1; return result("completed") }
        work.setForeground(true)
        let model = TokiModel(work: work, context: "account/workspace") { _ in result("running") }
        await model.open(id)
        #expect(model.workState?.phase == .running)
        model.close()
        await work.refresh()
        #expect(calls == 1)
        #expect(model.messages.isEmpty && model.selectedID == nil)
        #expect(work.snapshots[id]?.state.phase == .completed)
        work.clear()
    }

    @Test func backgroundDoesNotPollAndDisconnectedStateRequiresExplicitCheck() async {
        var calls = 0
        let work = TokiWorkController()
        configure(work) { _ in calls += 1; throw GlossiaFailure(kind: "network", message: "Offline") }
        work.observe(result("running"), id: id, context: "account/workspace")
        await work.refresh()
        #expect(calls == 0)
        work.setForeground(true)
        await work.refresh()
        #expect(calls == 1 && work.snapshots[id]?.state.phase == .disconnected)
        await work.refresh()
        #expect(calls == 1, "No unlimited offline retries")
        work.setForeground(false)
        work.clear()
    }

    @Test func boundedForegroundTrackingStopsStuckWork() async {
        var date = Date(timeIntervalSince1970: 1000)
        var calls = 0
        let work = TokiWorkController(now: { date })
        configure(work) { _ in calls += 1; return result("running") }
        work.setForeground(true)
        work.observe(result("running"), id: id, context: "account/workspace")
        date = date.addingTimeInterval(901)
        await work.refresh()
        #expect(calls == 0)
        #expect(work.snapshots[id]?.state.phase == .disconnected)
        work.clear()
    }

    @Test func revocationRemovesBothPrivateHistoryAndTrackedWork() async {
        let work = TokiWorkController()
        configure(work) { _ in throw GlossiaFailure(kind: "forbidden", message: "Revoked") }
        work.setForeground(true)
        let model = TokiModel(work: work, context: "account/workspace") { _ in result("running") }
        await model.open(id)
        model.draft = "Private unsent draft"
        await work.refresh()
        #expect(work.snapshots.isEmpty)
        #expect(model.detail == nil && model.draft.isEmpty && model.messages.isEmpty && model.workState == nil)
        work.clear()
    }

    @Test(arguments: ["success", "network"], ["forbidden", "not_found"])
    func revocationDuringSendClearsPrivateStateAndFencesLateCompletion(_ outcome: String, _ denial: String) async {
        let work = TokiWorkController()
        var finishCheck: CheckedContinuation<[String: Any], Error>?
        configure(work) { _ in try await withCheckedThrowingContinuation { finishCheck = $0 } }
        work.setForeground(true)
        var phase = "running"
        var finishSend: CheckedContinuation<[String: Any], Error>?
        var sentID: String?
        let model = TokiModel(work: work, context: "account/workspace") { input in
            if input["action"] as? String == "send" {
                sentID = input["message_id"] as? String
                return try await withCheckedThrowingContinuation { finishSend = $0 }
            }
            if input["operation"] as? String == "translation" { return ["session": ["id": second]] }
            var value = result(phase)
            var conversation = value["conversation"] as! [String: Any]
            conversation["translation_session_id"] = second
            value["conversation"] = conversation
            return value
        }
        await model.open(id)
        let check = Task { await work.refresh() }
        while finishCheck == nil { await Task.yield() }
        phase = "completed"
        await model.refreshDetail()
        model.draft = "Private follow-up"
        let send = Task { await model.send() }
        while finishSend == nil { await Task.yield() }
        #expect(model.sending && model.pending[id] != nil && model.source != nil)

        finishCheck?.resume(throwing: GlossiaFailure(kind: denial, message: "Revoked"))
        await check.value
        #expect(model.detail == nil && model.messages.isEmpty && model.draft.isEmpty)
        #expect(model.pending[id] == nil && model.source == nil && model.workState == nil)
        #expect(model.conversations.allSatisfy { $0["id"] as? String != id })
        let deniedError = model.detailError
        if outcome == "success" {
            finishSend?.resume(returning: result("queued", messageID: sentID))
        } else {
            finishSend?.resume(throwing: GlossiaFailure(kind: "network", message: "Offline"))
        }
        await send.value
        #expect(model.detail == nil && model.messages.isEmpty && model.draft.isEmpty && model.source == nil)
        #expect(model.pending[id] == nil && model.workState == nil && work.snapshots.isEmpty)
        #expect(model.detailError == deniedError && !model.sending)
        work.clear()
    }

    @Test func lateResultsCannotResurrectClearedWorkspaceOrRemovedWork() async {
        let work = TokiWorkController()
        var continuation: CheckedContinuation<[String: Any], Error>?
        configure(work) { _ in try await withCheckedThrowingContinuation { continuation = $0 } }
        work.setForeground(true)
        work.observe(result("running"), id: id, context: "account/workspace")
        let refresh = Task { await work.refresh() }
        while continuation == nil { await Task.yield() }
        work.remove(id, context: "account/workspace")
        continuation?.resume(returning: result("running"))
        await refresh.value
        #expect(work.snapshots.isEmpty)
        continuation = nil
        work.observe(result("running"), id: id, context: "account/workspace")
        let oldWorkspace = Task { await work.refresh() }
        while continuation == nil { await Task.yield() }
        work.clear()
        work.configure(context: "other/workspace", authorized: { true }, destination: link)
        continuation?.resume(returning: result("running"))
        await oldWorkspace.value
        #expect(work.snapshots.isEmpty)
        work.observe(result("running"), id: id, context: "account/workspace")
        #expect(work.snapshots.isEmpty)
        work.clear()
    }

    @Test func fixtureThinkingAndFailureUseProductionPresentationStateWithoutActivityKit() {
        let model = TokiModel { _ in [:] }
        model.selectedID = id
        model.detail = ["conversation": ["status": "completed"], "messages": []]
        #expect(model.workState == nil, "An idle thread is not a completed work event")
        model.detail = result("running")
        #expect(model.workState?.phase == .running)
        model.detail = result("failed")
        #expect(model.workState?.phase == .failed && model.workState?.endedAt != nil)
        model.close()
        #expect(model.workState == nil)
    }

    @Test func olderRefreshCannotFinishTheNewlyAcceptedTurn() async {
        let work = TokiWorkController()
        var continuation: CheckedContinuation<[String: Any], Error>?
        configure(work) { _ in try await withCheckedThrowingContinuation { continuation = $0 } }
        work.setForeground(true)
        work.observe(result("running"), id: id, context: "account/workspace", sentMessageID: first)
        let oldRefresh = Task { await work.refresh() }
        while continuation == nil { await Task.yield() }
        work.observe(result("queued", messageID: second), id: id, context: "account/workspace", sentMessageID: second)
        let newTurn = work.snapshots[id]
        continuation?.resume(returning: result("failed"))
        await oldRefresh.value
        #expect(work.snapshots[id] == newTurn)
        work.clear()
    }

    @Test func controllerReconciliationWinsOverOlderConversationRefresh() async {
        let work = TokiWorkController()
        configure(work) { _ in result("completed") }
        work.setForeground(true)
        var calls = 0
        var continuation: CheckedContinuation<[String: Any], Error>?
        let model = TokiModel(work: work, context: "account/workspace") { _ in
            calls += 1
            if calls == 1 { return result("running") }
            return try await withCheckedThrowingContinuation { continuation = $0 }
        }
        await model.open(id)
        let oldRefresh = Task { await model.refreshDetail() }
        while continuation == nil { await Task.yield() }
        await work.refresh()
        continuation?.resume(returning: result("queued"))
        await oldRefresh.value
        #expect(model.status == "completed" && !model.thinking)
        #expect(model.workState?.phase == .completed)
        work.clear()
    }

    @Test func credentialInvalidationPreventsLateObservationsEvenBeforeViewLifecycleRuns() async {
        let work = TokiWorkController()
        var authorized = true
        var calls = 0
        work.configure(context: "account/workspace", request: { _ in calls += 1; return result("running") },
                       authorized: { authorized }, destination: link)
        work.setForeground(true)
        authorized = false
        work.observe(result("running"), id: id, context: "account/workspace")
        await work.refresh()
        #expect(work.snapshots.isEmpty && calls == 0)
        work.clear()
    }
}
