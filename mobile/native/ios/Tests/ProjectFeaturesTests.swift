import Foundation
import Testing

@Suite @MainActor
struct ProjectFeaturesTests {
    @Test func composingIsLocalAndDraftsSurviveHistoryNavigation() async throws {
        var requests: [[String: Any]] = []
        let model = TokiModel { input in
            requests.append(input)
            if input["resource"] as? String == "conversations" {
                return ["conversations": [["id": "existing", "title": "Our next language"]], "meta": ["has_next_page?": false]]
            }
            return ["conversation": ["id": input["id"]!, "title": "Review Japanese onboarding", "status": "queued"],
                    "messages": input["content"].map { [["role": "user", "content": $0]] } ?? []]
        }
        await model.prepare(translationID: nil)
        #expect(requests.isEmpty && model.messages.isEmpty && model.sourceID == nil)
        model.close()
        #expect(model.conversations.isEmpty, "Backing out of an untouched composer must not leave an empty conversation")

        await model.prepare(translationID: nil)
        let id = try #require(model.selectedID)
        model.draft = "Review Japanese onboarding"
        model.close()
        await model.load(reset: true)
        #expect(model.conversations.count == 2)
        await model.open(id)
        #expect(model.draft == "Review Japanese onboarding")
        #expect(model.selectedID == id && model.hasProtectedWork)
        #expect(requests.allSatisfy { $0["resource"] as? String == "conversations" })

        await model.send()
        #expect(requests.filter { $0["action"] as? String == "create" }.count == 1)
        #expect(requests.filter { $0["action"] as? String == "send" }.count == 1)
        #expect(requests.filter { $0["operation"] as? String == "conversation" }.allSatisfy {
            $0["id"] as? String == id && $0["translation_session_id"] == nil
        })
        #expect(model.messages.count == 1 && model.draft.isEmpty)
        #expect(model.conversations.filter { $0["id"] as? String == id }.count == 1)
        #expect(model.conversations.first?["title"] as? String == "Review Japanese onboarding")
        #expect(!model.hasProtectedWork)
    }

    @Test func failedMessagesReplayTheSameIDAndContent() async {
        var requests: [[String: Any]] = []
        let model = TokiModel { input in
            requests.append(input)
            if requests.count == 1 { throw GlossiaFailure(kind: "network", message: "Offline") }
            return ["conversation": ["status": "queued"], "messages": [["id": input["message_id"]!, "role": "user", "content": input["content"]!]]]
        }
        model.selectedID = "conversation"
        model.detail = ["conversation": ["status": "completed"], "messages": []]
        model.draft = "Translate our welcome page"
        await model.send()
        #expect(model.draft == "Translate our welcome page")
        #expect(model.detailError == "Offline")
        await model.send()
        #expect(requests.count == 2)
        #expect(requests[0]["message_id"] as? String == requests[1]["message_id"] as? String)
        #expect(requests[1]["content"] as? String == "Translate our welcome page")
        #expect(model.draft.isEmpty)
        #expect(model.messages.count == 1)
        #expect(model.thinking)
    }

    @Test func translatedPagesAppendAndFailedPageCanRetry() async {
        var fail = true
        let model = TranslationsModel { input in
            if input["page"] as? Int == 2 && fail {
                fail = false
                throw GlossiaFailure(kind: "network", message: "Offline")
            }
            let id = input["page"] as? Int == 1 ? "first" : "second"
            return ["sessions": [["id": id]], "meta": ["has_next_page?": id == "first"]]
        }
        await model.load(reset: true)
        await model.load()
        #expect(model.sessions.compactMap { $0["id"] as? String } == ["first"])
        await model.load()
        #expect(model.sessions.compactMap { $0["id"] as? String } == ["first", "second"])
        #expect(!model.hasMore)
    }

    @Test func revokedConversationRemovesPrivateMessagesAndDraft() async {
        let model = TokiModel { _ in throw GlossiaFailure(kind: "forbidden", message: "Access revoked") }
        model.selectedID = "private"
        model.detail = ["conversation": ["status": "completed"], "messages": [["content": "private"]]]
        model.draft = "Unsent private draft"
        await model.refreshDetail()
        #expect(model.detail == nil)
        #expect(model.draft.isEmpty)
        #expect(model.messages.isEmpty)
    }

    @Test func translationDraftDoesNotWriteUntilSendAndReplaysItsOrigin() async {
        let sourceID = "abc12345-802e-4f91-9112-77d8a919efc5"
        var requests: [[String: Any]] = []
        var fail = true
        let model = TokiModel { input in
            requests.append(input)
            if input["operation"] as? String == "translation" { return ["session": ["id": sourceID]] }
            if input["action"] as? String == "create", fail {
                fail = false
                throw GlossiaFailure(kind: "network", message: "Response lost")
            }
            return ["conversation": ["id": input["id"]!, "status": "completed", "translation_session_id": sourceID], "messages": []]
        }
        await model.prepare(translationID: sourceID)
        #expect(requests.count == 1)
        #expect(requests[0]["operation"] as? String == "translation")
        #expect(model.messages.isEmpty)
        #expect(model.sourceID == sourceID)
        model.draft = "Use a warmer tone in onboarding."
        await model.send()
        let pendingID = model.pending[model.selectedID!]!.id
        #expect(model.hasProtectedWork)
        await model.send()
        let creates = requests.filter { $0["action"] as? String == "create" }
        #expect(creates.count == 2)
        #expect(creates[0]["id"] as? String == creates[1]["id"] as? String)
        #expect(creates.allSatisfy { $0["translation_session_id"] as? String == sourceID })
        #expect(requests.last?["message_id"] as? String == pendingID)
        #expect(!model.hasProtectedWork)
    }

    @Test func directTranslationLookupRetriesWithoutAListAndRejectsWrongIdentity() async {
        let id = "abc12345-802e-4f91-9112-77d8a919efc5"
        var calls = 0
        let model = TranslationDetailModel(id: id) { input in
            #expect(input["operation"] as? String == "translation")
            #expect(input["id"] as? String == id)
            calls += 1
            if calls == 1 { throw GlossiaFailure(kind: "not_found", message: "Not available") }
            return ["session": ["id": calls == 2 ? id : "wrong", "summary": "Private summary"]]
        }
        await model.load()
        #expect(model.record == nil && model.error == "Not available")
        await model.load()
        #expect(model.record?["id"] as? String == id)
        await model.load()
        #expect(model.record == nil && model.error != nil)
    }
}

@Suite @MainActor
struct NavigationTests {
    private let server = "https://glossia.example.com/"
    private let id = "abc12345-802e-4f91-9112-77d8a919efc5"

    private func session() -> GlossiaSession {
        let session = GlossiaSession()
        session.restoring = false; session.server = server
        session.organization = "acme"; session.project = "website"
        return session
    }

    private func workspace() -> [String: Any] {
        ["selection": ["organization": "acme", "project": "website"],
         "organizations": [["handle": "acme"]], "projects": [["handle": "website"]]]
    }

    @Test func allTypedDestinationsRoundTripThroughRust() throws {
        for screen in [GlossiaDestination.Screen.toki, .conversation, .newConversation, .translations, .translation, .analytics, .profile] {
            let destination = GlossiaDestination(screen: screen, server: "https://GLOSSIA.example.com:443",
                organization: screen == .profile ? nil : "acme", project: screen == .profile ? nil : "website",
                id: [.conversation, .translation].contains(screen) ? id : nil,
                translationID: screen == .newConversation ? id : nil)
            let normalized = try destination.validated()
            #expect(normalized.server == server)
            #expect(try GlossiaDestination.parse(#require(normalized.url)) == normalized)
        }
    }

    @Test func pendingLatestLinkWaitsForAuthenticationAndIgnoresOAuthCallbacks() async throws {
        let session = GlossiaSession()
        let first = GlossiaDestination(screen: .translation, server: server, organization: "acme", project: "website", id: id)
        let second = GlossiaDestination(screen: .analytics, server: server, organization: "acme", project: "website")
        await session.receive(try #require(first.url))
        await session.receive(try #require(second.url))
        let revision = session.navigation.pendingRevision
        await session.receive(try #require(URL(string: "glossia://oauth/callback?state=not-a-navigation-intent")))
        #expect(session.navigation.pendingRevision == revision)
        #expect(session.navigation.targets.isEmpty)
        session.server = server; session.restoring = false
        await session.resolveNavigation { _ in workspace() }
        #expect(session.tab == "analytics")
        #expect(session.navigation.targets["analytics"] == second)
        #expect(session.navigation.pending == nil)
    }

    @Test func foreignServerAndWorkspaceFallbackNeverChangeSelection() async {
        let session = session()
        var calls = 0
        await session.navigate(GlossiaDestination(screen: .profile, server: "https://other.example.com")) { _ in
            calls += 1; return workspace()
        }
        #expect(calls == 0 && session.tab == "toki")
        #expect(session.navigation.message?.contains("different Glossia server") == true)
        let destination = GlossiaDestination(screen: .translation, server: server, organization: "missing", project: "website", id: id)
        await session.navigate(destination) { _ in calls += 1; return workspace() }
        #expect(calls == 1)
        #expect(session.organization == "acme" && session.project == "website")
        #expect(session.navigation.targets.isEmpty)
        #expect(session.navigation.message?.contains("unavailable") == true)
    }

    @Test func aLateLookupCannotReplaceTheLatestDestination() async {
        let session = session()
        let started = AsyncStream<Void>.makeStream()
        var finish: CheckedContinuation<[String: Any], Never>?
        let first = GlossiaDestination(screen: .translation, server: server, organization: "acme", project: "website", id: id)
        let old = Task {
            await session.navigate(first) { _ in
                await withCheckedContinuation { finish = $0; started.continuation.yield(()) }
            }
        }
        for await _ in started.stream { break }
        let latest = GlossiaDestination(screen: .analytics, server: server, organization: "acme", project: "website")
        await session.navigate(latest) { _ in workspace() }
        finish?.resume(returning: workspace())
        await old.value
        #expect(session.tab == "analytics")
        #expect(session.navigation.targets["translations"] == nil)
        #expect(session.navigation.targets["analytics"] == latest)
    }

    @Test func hiddenDraftsAndDraftsCreatedDuringLookupRemainProtected() async {
        let session = session()
        let model = TokiModel { _ in [:] }
        model.selectedID = "draft"
        session.navigation.protect(UUID()) { [weak model] in model?.hasProtectedWork ?? false }
        let started = AsyncStream<Void>.makeStream()
        var finish: CheckedContinuation<[String: Any], Never>?
        let destination = GlossiaDestination(screen: .translation, server: server, organization: "acme", project: "website", id: id)
        let lookup = Task {
            await session.navigate(destination) { _ in
                await withCheckedContinuation { finish = $0; started.continuation.yield(()) }
            }
        }
        for await _ in started.stream { break }
        model.draft = "A linguistic decision not yet shared"
        finish?.resume(returning: workspace())
        await lookup.value
        #expect(session.navigation.targets.isEmpty)
        #expect(model.draft == "A linguistic decision not yet shared")
        session.tab = "profile"
        await session.navigate(destination) { _ in Issue.record("Protected navigation made a request"); return [:] }
        #expect(session.tab == "profile")
        model.discardDrafts()
        await session.navigate(destination) { _ in workspace() }
        #expect(session.tab == "translations")
        session.navigation.queue(destination)
        session.navigation.reset()
        await session.resolveNavigation { _ in Issue.record("Reset intent survived session end"); return [:] }
        #expect(session.navigation.targets.isEmpty && session.navigation.pending == nil)
    }
}
