import Foundation
import Testing

@Suite @MainActor
struct TranslationReviewsTests {
    private let id = "abc12345-802e-4f91-9112-77d8a919efc5"
    private let reviewID = "def12345-802e-4f91-9112-77d8a919efc5"
    private let chatID = "93cf36a3-802e-4f91-9112-77d8a919efc5"
    private let replyID = "aaa12345-802e-4f91-9112-77d8a919efc5"
    private func row(_ status: String = "open") -> [String: Any] {
        ["id": reviewID, "conversation_id": chatID, "translation_session_id": id, "status": status,
         "locale": "es", "question": "Formal or informal?", "source_excerpt": "Welcome back!", "translation_excerpt": "¡Bienvenido de nuevo!"]
    }
    private func thread(_ status: String = "open", phase: String = "completed", reply: String? = nil) -> [String: Any] {
        ["conversation": ["id": chatID, "status": phase, "linguistic_review": row(status)],
         "messages": [["id": "bbb12345-802e-4f91-9112-77d8a919efc5", "role": "user", "content": "Our readers prefer tú."],
                      ["id": reply ?? replyID, "role": "assistant", "status": "completed", "reply_to_id": "bbb12345-802e-4f91-9112-77d8a919efc5", "content": "Use informal tú."]]]
    }

    @Test(arguments: [false, true]) func explicitDecisionUsesCurrentReplyAndIndependentGuidance(_ reusable: Bool) async {
        var writes: [[String: Any]] = []
        let model = TokiModel { input in
            if input["operation"] as? String == "conversation" { return thread(writes.isEmpty ? "open" : "answered") }
            writes.append(input); return ["review": row("answered")]
        }
        await model.open(chatID)
        #expect(model.sharedGoal && model.canResolve && writes.isEmpty)
        model.beginResolution()
        #expect(model.hasProtectedWork && model.decision?.reusable == false)
        model.decision = ReviewDraft(answer: "Approved informal tú.", reusable: reusable, guidance: "Use informal Spanish in onboarding.", scope: "project")
        await model.saveDecision()
        #expect(writes.count == 1)
        #expect(writes[0]["resolution_message_id"] as? String == replyID)
        #expect(writes[0]["answer"] as? String == "Approved informal tú.")
        #expect(writes[0]["guidance"] as? String == (reusable ? "Use informal Spanish in onboarding." : nil))
        #expect(writes[0]["context_scope"] as? String == (reusable ? "project" : nil))
        #expect(model.goalClosed && model.decision == nil && !model.hasProtectedWork)
        model.draft = "Do not send to a resolved thread"; await model.send()
        #expect(writes.count == 1)
    }

    @Test(arguments: ["network", "conflict", "forbidden"])
    func uncertainDecisionNeedsAuthoritativeRefreshAndNeverAutomaticallyRetries(_ failure: String) async {
        var writes = 0
        let model = TokiModel { input in
            if input["operation"] as? String == "conversation" { return thread(writes == 0 ? "open" : "answered") }
            writes += 1; throw GlossiaFailure(kind: failure, message: failure)
        }
        await model.open(chatID); model.beginResolution()
        await model.saveDecision(); await model.saveDecision()
        #expect(writes == 1 && model.resolutionNeedsRefresh && model.hasProtectedWork)
        await model.refreshDetail()
        #expect(model.goalClosed && model.hasProtectedWork && model.decision?.answer == "Use informal tú.")
        #expect(!model.canSaveDecision && model.resolutionError != nil)
        model.discardDecision(); #expect(!model.hasProtectedWork)
    }

    @Test func eligibilityRejectsBusyDraftPendingInitialQuestionFailedStaleAndChangedReplies() async {
        let model = TokiModel { _ in thread() }
        await model.open(chatID)
        model.draft = "unsent"; #expect(!model.canResolve); model.draft = ""
        model.pending[chatID] = .init(id: replyID, content: "Unconfirmed")
        #expect(!model.canResolve); model.pending = [:]
        for status in ["queued", "running", "failed"] { model.detail = thread(phase: status); #expect(!model.canResolve) }
        model.detail = thread("stale"); #expect(!model.canResolve && model.goalClosed)
        model.detail = thread(); model.detail?["messages"] = [["id": replyID, "role": "assistant", "content": "Question only"]]
        #expect(!model.canResolve)
        model.detail = thread()
        var turns = model.messages
        turns.append(["id": "ccc12345-802e-4f91-9112-77d8a919efc5", "role": "user", "content": "A newer turn"])
        model.detail?["messages"] = turns; #expect(!model.canResolve)
        model.detail = thread(); model.beginResolution()
        model.detail = thread(reply: "ccc12345-802e-4f91-9112-77d8a919efc5")
        #expect(!model.canSaveDecision && model.hasProtectedWork)
        model.close(); #expect(model.selectedID == chatID)
        model.discardDecision(); #expect(model.canResolve)
    }

    @Test func authoritativeReloadExposesResumedIdentityAndAccessLossClearsDraft() async {
        var reads = 0
        let model = TokiModel { _ in
            reads += 1
            if reads == 4 { throw GlossiaFailure(kind: "forbidden", message: "Access revoked") }
            var value = thread(reads == 1 ? "open" : "answered")
            if reads == 3 {
                var conversation = value["conversation"] as! [String: Any]
                var goal = conversation["linguistic_review"] as! [String: Any]
                goal["resumed_session_id"] = replyID; conversation["linguistic_review"] = goal; value["conversation"] = conversation
            }
            return value
        }
        await model.open(chatID); model.beginResolution()
        await model.refreshDetail(); #expect(model.goalClosed && model.decision != nil && !model.canSaveDecision)
        await model.refreshDetail(); #expect(model.goal?["resumed_session_id"] as? String == replyID)
        await model.refreshDetail(); #expect(model.detail == nil && !model.hasProtectedWork)
    }

    @Test func idleSharedGoalRefreshesOtherParticipantsWithoutReplacingApprovalOrDrafts() async {
        var response = thread()
        var reads = 0
        let model = TokiModel { _ in reads += 1; return response }
        await model.open(chatID); #expect(model.shouldPollVisible && !model.thinking)
        model.draft = "Unsent chat"
        response = thread(reply: "ccc12345-802e-4f91-9112-77d8a919efc5")
        await model.refreshVisible()
        #expect(reads == 2 && model.draft == "Unsent chat")
        model.draft = ""; model.beginResolution()
        model.decision?.answer = "My reviewed decision"; model.decision?.reusable = true; model.decision?.guidance = "My independent rule"
        response = thread(reply: replyID)
        await model.refreshVisible()
        #expect(!model.canSaveDecision && model.decision?.answer == "My reviewed decision")
        response = thread("answered")
        await model.refreshVisible()
        #expect(model.goalClosed && model.hasProtectedWork && !model.canSaveDecision)
        #expect(model.decision?.guidance == "My independent rule" && model.resolutionError != nil)
        model.discardDecision(); #expect(!model.hasProtectedWork)
        var privateThread = thread(); var conversation = privateThread["conversation"] as! [String: Any]
        conversation["linguistic_review"] = NSNull(); privateThread["conversation"] = conversation
        let privateModel = TokiModel { _ in reads += 1; return privateThread }
        await privateModel.open(chatID)
        let before = reads; await privateModel.refreshVisible(); #expect(reads == before && !privateModel.shouldPollVisible)
    }

    @Test func localizedResourcesAreLookedUpWhenFixedModelCopyIsCreated() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let localized = directory.appendingPathComponent("de.lproj")
        try FileManager.default.createDirectory(at: localized, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let catalog = "\"Choose Files\" = \"Dateien wählen SENTINEL\";\n\"Allow microphone and speech recognition in Settings to use on-device dictation.\" = \"Mikrofon SENTINEL erlauben\";\n\"Participants: %@\" = \"Teilnehmende SENTINEL: %@\";"
        try catalog.write(to: localized.appendingPathComponent("Localizable.strings"), atomically: true, encoding: .utf8)
        let bundle = try #require(Bundle(path: localized.path))
        #expect(String(localized: "Choose Files", bundle: bundle) == "Dateien wählen SENTINEL")
        let people = "Alex, سام"
        #expect(String(localized: "Participants: \(people)", bundle: bundle) == "Teilnehmende SENTINEL: \u{2068}Alex, سام\u{2069}")
        let voice = TokiVoiceInput(capture: ReviewVoiceCapture(), permission: { false }, localize: { String(localized: $0, bundle: bundle) })
        await voice.start(); #expect(voice.error == "Mikrofon SENTINEL erlauben")
    }

    @Test func textImportsRemainEditableAndRejectBinaryOversizeOrOverlongDrafts() throws {
        #expect(try TokiTextImport.appending(Data("مرحبا".utf8), to: "draft") == "draft\nمرحبا")
        for data in [Data([0xff, 0xfe]), Data([0, 1]), Data(repeating: 65, count: 16_385)] {
            #expect(throws: GlossiaFailure.self) { try TokiTextImport.appending(data, to: "unchanged") }
        }
        #expect(throws: GlossiaFailure.self) { try TokiTextImport.appending(Data("hello".utf8), to: String(repeating: "字", count: 4000)) }
    }

    @Test func staleListAndDecisionResponsesCannotRestoreOtherWorkspaces() async {
        let started = AsyncStream<Void>.makeStream()
        var finish: CheckedContinuation<[String: Any], Never>?
        let model = TranslationReviewsModel(id: id) { _ in
            await withCheckedContinuation { finish = $0; started.continuation.yield(()) }
        }
        let loading = Task { await model.load() }
        for await _ in started.stream { break }
        model.invalidate(clear: true); finish?.resume(returning: ["reviews": [row()]])
        await loading.value
        #expect(model.reviews.isEmpty && !model.loaded)
        let chat = TokiModel { input in
            if input["operation"] as? String == "conversation" { return thread() }
            return await withCheckedContinuation { finish = $0; started.continuation.yield(()) }
        }
        await chat.open(chatID); chat.beginResolution()
        let saving = Task { await chat.saveDecision() }
        for await _ in started.stream { break }
        #expect(chat.resolving && chat.hasProtectedWork)
        chat.selectedID = replyID; chat.detail = nil
        finish?.resume(returning: ["review": row("answered")]); await saving.value
        #expect(chat.detail == nil && chat.selectedID == replyID)
    }

    @Test func scalarLimitsAndIndependentRuleAreValidated() {
        #expect(!ReviewDraft(answer: " \n").valid)
        #expect(ReviewDraft(answer: String(repeating: "字", count: 8000)).valid)
        #expect(!ReviewDraft(answer: String(repeating: "字", count: 8001)).valid)
        #expect(!ReviewDraft(answer: "One-off", reusable: true, guidance: " ").valid)
    }

    @Test func fluentLanguagesAreDistinctProfileWritesWithPreservedDraftAndFencedResults() async {
        var writes: [[String: Any]] = []
        var fail = true
        let model = FluentLanguagesModel { input in
            if input["operation"] as? String == "fluent_languages" {
                writes.append(input)
                if fail { throw GlossiaFailure(kind: "forbidden", message: "user:write required") }
                return ["user": ["fluent_languages": input["fluent_languages"]!]]
            }
            return ["user": ["fluent_languages": ["es"]]]
        }
        await model.load(); #expect(model.saved == ["es"] && !model.dirty)
        model.draft = "ar, zh-Hant"; await model.save()
        #expect(model.dirty && model.draft == "ar, zh-Hant" && model.error != nil)
        fail = false; await model.save()
        #expect(!model.dirty && model.saved == ["ar", "zh-Hant"])
        #expect(writes[0].keys.count == 2 && writes[0]["fluent_languages"] as? [String] == ["ar", "zh-Hant"])
        model.draft = ""; await model.save(); #expect(model.saved.isEmpty)
        let started = AsyncStream<Void>.makeStream()
        var finish: CheckedContinuation<[String: Any], Never>?
        let late = FluentLanguagesModel { _ in await withCheckedContinuation { finish = $0; started.continuation.yield(()) } }
        let loading = Task { await late.load() }
        for await _ in started.stream { break }
        late.invalidate(); finish?.resume(returning: ["user": ["fluent_languages": ["he"]]])
        await loading.value; #expect(!late.loaded && !late.busy && late.saved.isEmpty)
    }

    @Test func voiceUsesMeasuredUpdatesAndFencesLatePermissionAndCaptureWithoutSending() async {
        let capture = ReviewVoiceCapture()
        let voice = TokiVoiceInput(capture: capture, permission: { true })
        await voice.start(); #expect(voice.phase == .recording)
        capture.update?(.level(0.75)); capture.update?(.transcript("مرحبا", final: false))
        #expect(voice.levels.last == 0.75)
        var text = "existing draft"
        voice.finish { text = TokiVoiceInput.appending($0, to: text) }
        #expect(text == "existing draft مرحبا" && !voice.busy)
        capture.update?(.transcript("late", final: true)); #expect(text == "existing draft مرحبا" && !voice.busy)
        await voice.start(); voice.cancel(); capture.update?(.failed)
        #expect(!voice.busy && voice.error == nil)
        let denied = TokiVoiceInput(capture: capture, permission: { false })
        await denied.start(); #expect(!denied.busy && denied.error != nil)
    }

    @Test(arguments: ["pending", "running", "awaiting_input", "completed", "failed", "cancelled"])
    func onlyExecutingRunsShowLiveConnection(_ status: String) async {
        let model = TranslationDetailModel(id: id) { _ in ["session": ["id": id, "status": status]] }
        await model.load(); #expect(model.showsLiveConnection == ["pending", "running"].contains(status))
    }
}

@MainActor private final class ReviewVoiceCapture: TokiVoiceCapturing {
    var update: (@MainActor (TokiVoiceUpdate) -> Void)?
    func start(update: @escaping @MainActor (TokiVoiceUpdate) -> Void) throws { self.update = update }
    func stop() {}
}
