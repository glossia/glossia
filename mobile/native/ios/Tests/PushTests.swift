import Foundation
import Testing

private final class PushMemory {
    var data: [String: Data] = [:]
    var store: GlossiaPushStore {
        GlossiaPushStore(read: { self.data[$0] }, write: { self.data[$0] = try JSONSerialization.data(withJSONObject: $1) },
                         remove: { self.data[$0] = nil })
    }
}

@Suite @MainActor
struct PushTests {
    let origin = "https://glossia.example/"
    let id = "01922cc0-0000-7000-8000-000000000001"

    @Test func optInIsExplicitDenialAndUnavailableBuildDoNotEnroll() async {
        for environment: String? in [nil, "sandbox"] {
            let memory = PushMemory()
            var requested = 0, calls = 0
            let model = GlossiaPushNotifications(store: memory.store, environment: { environment },
                authorize: { requested += 1; return false }, allowed: { false }, register: {}, unregister: {})
            await model.configure(origin: origin) { _ in calls += 1; return [:] }
            #expect(calls == 0 && requested == 0 && !model.enabled)
            await model.enable()
            #expect(calls == 0 && !model.enabled && memory.data.isEmpty && model.message != nil)
            #expect(requested == (environment == nil ? 0 : 1))
        }
    }

    @Test func tokenRotationAndRevocationReconcileAndDisableBeforeNetworking() async throws {
        let memory = PushMemory()
        var permitted = true
        var actions: [[String: Any]] = []
        let model = GlossiaPushNotifications(store: memory.store, environment: { "production" }, authorize: { true },
            allowed: { permitted }, register: {}, unregister: {})
        await model.configure(origin: origin) { action in
            actions.append(action)
            if action["action"] as? String == "unregister" {
                let saved = try memory.store.load(origin)
                #expect(saved?.enabled == false)
                return ["deleted": true]
            }
            return ["registered": true, "registration_id": action["installation_id"]!]
        }
        await model.enable()
        #expect(actions.isEmpty)
        await model.refresh(token: "ab".repeating(32))
        await model.refresh(token: "cd".repeating(32))
        #expect(actions.count == 2 && actions[0]["installation_id"] as? String == actions[1]["installation_id"] as? String)
        #expect(actions[1]["token"] as? String == "cd".repeating(32))
        permitted = false
        await model.refresh()
        #expect(!model.enabled && actions.last?["action"] as? String == "unregister")
        #expect(try memory.store.load(origin) == nil)
    }

    @Test func offlineCleanupRemainsDisabledAcrossSessionsAndOrigins() async throws {
        let memory = PushMemory()
        try memory.store.save(GlossiaPushRegistration(installationID: id, origin: origin, enabled: true, registrationID: id))
        _ = try memory.store.disable(origin)
        let model = GlossiaPushNotifications(store: memory.store, environment: { "sandbox" }, authorize: { true }, allowed: { true }, register: {}, unregister: {})
        var actions: [String] = []
        await model.configure(origin: origin) { input in
            actions.append(input["action"] as! String)
            throw GlossiaFailure(kind: "network", message: "Offline")
        }
        #expect(!model.enabled && actions == ["unregister"])
        #expect(try memory.store.load(origin)?.enabled == false)
        await model.enable()
        #expect(!model.enabled && actions == ["unregister", "unregister"])
        #expect(try memory.store.load("https://other.example/") == nil)
        model.prepareForSessionEnd()
        await model.refresh(token: "ab".repeating(32))
        #expect(actions.count == 2)
    }

    @Test func sessionEndFencesAnInFlightRegistrationReply() async throws {
        let memory = PushMemory()
        let model = GlossiaPushNotifications(store: memory.store, environment: { "sandbox" }, authorize: { true }, allowed: { true }, register: {}, unregister: {})
        var continuation: CheckedContinuation<[String: Any], Error>?
        await model.configure(origin: origin) { _ in try await withCheckedThrowingContinuation { continuation = $0 } }
        await model.enable()
        let task = Task { await model.refresh(token: "ab".repeating(32)) }
        while continuation == nil { await Task.yield() }
        let loaded = try memory.store.load(origin)
        let saved = try #require(loaded)
        model.prepareForSessionEnd()
        continuation?.resume(returning: ["registration_id": saved.installationID])
        await task.value
        let disabled = try memory.store.load(origin)
        #expect(!model.enabled && disabled?.enabled == false)
        #expect(try memory.store.load(origin)?.registrationID == nil)
    }

    @Test func retiredProviderRegistrationIsCleanedUpBeforeRenewal() async throws {
        let memory = PushMemory()
        var actions: [[String: Any]] = []
        let model = GlossiaPushNotifications(store: memory.store, environment: { "production" }, authorize: { true }, allowed: { true }, register: {}, unregister: {})
        await model.configure(origin: origin) { action in
            actions.append(action)
            if actions.count == 1 { throw GlossiaFailure(kind: "conflict", message: "Retired") }
            return ["registered": true, "registration_id": action["installation_id"]!, "deleted": true]
        }
        await model.enable()
        await model.refresh(token: "ab".repeating(32))
        #expect(actions.map { $0["action"] as! String } == ["register", "unregister", "register"])
        #expect(actions[0]["installation_id"] as? String == actions[1]["installation_id"] as? String)
        #expect(actions[0]["installation_id"] as? String != actions[2]["installation_id"] as? String)
        let saved = try memory.store.load(origin)
        #expect(model.enabled && saved?.registrationID == actions[2]["installation_id"] as? String)
    }

    @Test func payloadAllowsOnlyVersionedRegisteredSameOriginReadDestinations() throws {
        var saved = GlossiaPushRegistration(installationID: id, origin: origin, enabled: true, registrationID: id)
        let target = GlossiaDestination(screen: .translation, server: origin, organization: "acme", project: "website", id: id)
        let url = try #require(target.url)
        let payload: [AnyHashable: Any] = ["v": "1", "url": url.absoluteString, "registration_id": id]
        #expect(GlossiaPushPayload.destination(payload, origin: origin, saved: saved) == url)
        for change in [["v": "2"], ["registration_id": "other"], ["url": "glossia://oauth/callback?code=x"],
                       ["url": try #require(GlossiaDestination(screen: .profile, server: origin).url).absoluteString],
                       ["url": try #require(GlossiaDestination(screen: .conversation, server: "https://other.example/", organization: "acme", project: "website", id: id).url).absoluteString]] {
            #expect(GlossiaPushPayload.destination(payload.merging(change) { _, value in value }, origin: origin, saved: saved) == nil)
        }
        saved.enabled = false
        #expect(GlossiaPushPayload.destination(payload, origin: origin, saved: saved) == nil)
    }
}

private extension String {
    func repeating(_ count: Int) -> String { String(repeating: self, count: count) }
}
