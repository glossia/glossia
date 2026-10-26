import SwiftUI

@MainActor
final class GoalFixture {
    static let chatID = "93cf36a3-802e-4f91-9112-77d8a919efc5"
    static let replyID = "aaa12345-802e-4f91-9112-77d8a919efc5"
    let state: String
    var resolved = false
    private var failedResolution = false
    private var answer = "Use informal tú."
    private var guidance: String? = "Use informal Spanish in onboarding."
    private var contextPath = "L10N/es.md"
    init(_ state: String) { self.state = state; resolved = state == "goal-resolved" }
    var review: [String: Any] {
        var row: [String: Any] = ["id": "def12345-802e-4f91-9112-77d8a919efc5", "conversation_id": Self.chatID,
            "translation_session_id": GlossiaPreviewApp.translationID, "status": resolved ? "answered" : state == "goal-stale" ? "stale" : "open",
            "question": "Should we address the reader with tú or usted?", "locale": "es",
            "source_path": "locales/en/welcome.json", "output_path": "locales/es/welcome.json",
            "source_excerpt": "Welcome back!", "translation_excerpt": "¡Bienvenido de nuevo!",
            "participants": [["name": "Alex", "fluent_languages": ["es"]], ["name": "Sam", "fluent_languages": ["es-MX"]]]]
        if state.contains("rtl") { row["question"] = "هل نخاطب القارئ بصيغة رسمية أم ودية؟"; row["locale"] = "ar"; row["output_path"] = "locales/ar/welcome.json"; row["translation_excerpt"] = "مرحبًا بعودتك!" }
        if state.contains("hebrew") { row["question"] = "באיזה סגנון נפנה לקוראים?"; row["locale"] = "he"; row["translation_excerpt"] = "ברוכים השבים!" }
        if resolved {
            row["answer"] = answer
            row["answered_by"] = ["id": "eee12345-802e-4f91-9112-77d8a919efc5", "name": "Alex"]
            if let guidance { row["guidance"] = guidance; row["context_path"] = contextPath }
            row["resumed_session_id"] = Self.replyID
        }
        return row
    }
    var thread: [String: Any] {
        ["conversation": ["id": Self.chatID, "title": "Spanish onboarding", "status": "completed", "linguistic_review": review],
         "messages": [["id": "bbb12345-802e-4f91-9112-77d8a919efc5", "role": "assistant", "content": review["question"]!],
            ["id": "ddd12345-802e-4f91-9112-77d8a919efc5", "role": "user", "author": "Sam", "content": "Let's keep the welcome approachable."],
            ["id": "ccc12345-802e-4f91-9112-77d8a919efc5", "role": "user", "author": "Alex", "content": state.contains("rtl") ? "نريد أسلوبًا وديًا." : state.contains("hebrew") ? "נרצה סגנון ידידותי." : "Our onboarding should feel friendly."],
            ["id": Self.replyID, "role": "assistant", "status": "completed", "reply_to_id": "ccc12345-802e-4f91-9112-77d8a919efc5", "content": state.contains("rtl") ? "استخدم صيغة ودية في رسالة الترحيب." : state.contains("hebrew") ? "נשתמש בסגנון ידידותי בהודעת הפתיחה." : "Use informal tú."]]]
    }
    func request(_ input: [String: Any]) async throws -> [String: Any] {
        if state == "goal-denied" { throw GlossiaFailure(kind: "forbidden", message: "You do not have permission to view this shared conversation.") }
        if input["operation"] as? String == "translation_reviews" {
            if state == "goal-error" { failedResolution = true; throw GlossiaFailure(kind: "network", message: "Connection lost while saving.") }
            if state == "goal-permission" { failedResolution = true; throw GlossiaFailure(kind: "forbidden", message: "Saving requires translation:write permission.") }
            answer = input["answer"] as? String ?? answer
            guidance = input["guidance"] as? String
            contextPath = input["context_scope"] as? String == "project" ? "L10N.md" : "L10N/es.md"
            resolved = true; return ["review": review]
        }
        if failedResolution { throw GlossiaFailure(kind: "network", message: "Cannot refresh yet. Your decision draft is retained; reconnect before explicitly retrying.") }
        return thread
    }
}

struct GoalPreview: View {
    @StateObject private var model: TokiModel
    @State private var resumed = false
    private let fixture: GoalFixture
    let state: String
    init(state: String) {
        self.state = state
        let fixture = GoalFixture(state); self.fixture = fixture
        let model = TokiModel { try await fixture.request($0) }
        model.selectedID = GoalFixture.chatID
        if state != "goal-denied" { model.detail = fixture.thread }
        _model = StateObject(wrappedValue: model)
    }
    var body: some View {
        NavigationStack {
            TokiConversationView(model: model, openSource: { _ in resumed = true })
                .navigationDestination(isPresented: $resumed) { Text("Resumed translation").navigationTitle("Translation") }
        }
        .environment(\.layoutDirection, state.contains("rtl") || state.contains("hebrew") ? .rightToLeft : .leftToRight)
        .environment(\.locale, Locale(identifier: state.contains("rtl") ? "ar" : state.contains("hebrew") ? "he" : "en"))
        .dynamicTypeSize(state.contains("large") ? .accessibility2 : .large)
        .preferredColorScheme(state.contains("dark") ? .dark : nil)
        .task {
            if state == "goal-denied" { await model.open(GoalFixture.chatID) }
            if ["goal-editing", "goal-error", "goal-permission", "goal-closed-draft"].contains(state) {
                model.beginResolution()
                model.decision?.reusable = true; model.decision?.guidance = "Use informal Spanish in onboarding."
                if state == "goal-closed-draft" { fixture.resolved = true; await model.refreshVisible() }
                else if state != "goal-editing" { await model.saveDecision() }
            }
        }
    }
}
