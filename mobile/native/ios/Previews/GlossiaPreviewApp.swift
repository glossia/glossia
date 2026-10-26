import SwiftUI

// Separate bundle and source list: these fixtures cannot authenticate and never
// enter the production app. They render the same production views.
@main
struct GlossiaPreviewApp: App {
    @StateObject private var session: GlossiaSession
    @StateObject private var chat: TokiModel
    @StateObject private var work: TokiWorkController
    @StateObject private var appearance = GlossiaAppearance(request: themeRequest)
    @Environment(\.scenePhase) private var scenePhase
    private let screen: String

    init() {
        // A cold launch through iOS's URL dispatcher has no XCTest arguments.
        // Restore only the preview scenario, never production credentials.
        screen = ProcessInfo.processInfo.arguments.dropFirst().first
            ?? UserDefaults.standard.string(forKey: "glossia.preview.screen") ?? "login"
        UserDefaults.standard.set(screen, forKey: "glossia.preview.screen")
        if ProcessInfo.processInfo.arguments.contains("--reset-app-language") {
            UserDefaults.standard.removeObject(forKey: GlossiaLanguage.preferenceKey)
        }
        let session = GlossiaSession(push: Self.previewPush(screen))
        session.restoring = false
        if screen != "login" {
            session.server = "https://glossia.example.com"
            session.organization = "acme"; session.project = "website"
            session.organizations = [["handle": "acme", "name": "Acme"], ["handle": "other", "name": "Other team"]]
            session.projects = [["handle": "website", "name": "Website"]]
            session.tab = screen == "empty" ? "toki" : screen
            if screen == "language-rtl" { session.tab = "toki" }
            if screen.hasPrefix("profile-push-") { session.tab = "profile" }
            if ["translations-empty", "translation-detail", "translation-live"].contains(screen) { session.tab = "translations" }
            if screen == "analytics-empty" { session.tab = "analytics" }
            if screen == "source-chat" { session.tab = "toki" }
            if screen == "no-project" { session.project = nil; session.tab = "toki" }
        }
        _session = StateObject(wrappedValue: session)
        let state = screen
        let work = TokiWorkController(liveActivities: state.hasPrefix("activity-"), now: {
            Date().addingTimeInterval(state == "activity-stale" ? -90 : 0)
        })
        if state.hasPrefix("activity-") {
            work.configure(context: session.projectContext, request: { _ in
                Self.activityConversation(state == "activity-queued" ? "queued" : "running")
            }, authorized: { true }, destination: { id in session.destination(.conversation, id: id)?.url })
        }
        _work = StateObject(wrappedValue: work)
        let chat = TokiModel(work: state.hasPrefix("activity-") ? work : nil, context: session.projectContext) { input in
            if state.hasPrefix("activity-") { return Self.activityConversation(state == "activity-queued" ? "queued" : "running") }
            var result = try await Self.request(input)
            if state == "thinking", input["operation"] as? String == "conversation" {
                result["conversation"] = ["status": "running"]
            }
            return result
        }
        chat.selectedID = "93cf36a3-802e-4f91-9112-77d8a919efc5"
        chat.detail = Self.chat
        if screen == "thinking" { chat.detail?["conversation"] = ["status": "running"] }
        if screen == "failed" { chat.detail?["conversation"] = ["status": "failed"] }
        if screen == "empty-chat" { chat.detail?["messages"] = [] }
        if state.hasPrefix("activity-") { chat.detail = Self.activityConversation(state == "activity-queued" ? "queued" : "running") }
        _chat = StateObject(wrappedValue: chat)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if screen == "login" { GlossiaLoginView(session: session) }
                else if ["chat", "thinking", "failed", "empty-chat"].contains(screen) || screen.hasPrefix("activity-") {
                    NavigationStack { TokiConversationView(model: chat) }
                } else if screen == "workspace" {
                    WorkspacePicker(session: session, request: Self.request)
                } else if screen.hasPrefix("review-") {
                    ReviewPreview(state: screen)
                } else if screen.hasPrefix("goal-") {
                    GoalPreview(state: screen)
                } else {
                    GlossiaWorkspaceView(session: session) { value in
                        if screen == "empty" && value["resource"] as? String == "conversations" {
                            return ["conversations": [], "meta": ["has_next_page?": false]]
                        }
                        if screen == "translations-empty" && value["resource"] as? String == "translations" {
                            return ["sessions": [], "meta": ["has_next_page?": false]]
                        }
                        if screen == "analytics-empty" && value["resource"] as? String == "analytics" {
                            return ["summary": ["pageviews": 0, "unique_visitors": 0, "locale_gap_visits": 0,
                                                "top_country": "", "top_browser_language": ""], "top_pages": [],
                                    "traffic": ["granularity": "day", "points": []], "days": value["days"] ?? 30]
                        }
                        return try await Self.request(value)
                    }.id(session.projectContext)
                }
            }
            .modifier(GlossiaThemeScope(appearance: appearance))
            .modifier(GlossiaLinkNotice(navigation: session.navigation) { Task { await session.resolveNavigation(request: Self.request) } })
            .modifier(GlossiaLanguageScope())
            .environment(\.layoutDirection, screen == "language-rtl" ? .rightToLeft : .leftToRight)
            .task { await appearance.configure(server: session.server ?? "https://glossia.ai") }
            .onOpenURL { url in Task { await session.receive(url, request: Self.request) } }
            .onChange(of: scenePhase, initial: true) { _, phase in work.setForeground(phase == .active) }
            .task {
                if screen.hasPrefix("profile-push-") {
                    await session.push.configure(origin: session.server) { input in
                        ["registered": true, "registration_id": input["installation_id"] as Any? ?? NSNull(), "deleted": true]
                    }
                    await session.push.enable()
                    if screen == "profile-push-enabled" { await session.push.refresh(token: String(repeating: "ab", count: 32)) }
                }
                if screen.hasPrefix("activity-") {
                    work.observe(Self.activityConversation(screen == "activity-queued" ? "queued" : "running"),
                                 id: chat.selectedID!, context: session.projectContext)
                    if ["activity-completed", "activity-failed"].contains(screen) {
                        try? await Task.sleep(for: .seconds(2))
                        let result = Self.activityConversation(screen == "activity-completed" ? "completed" : "failed")
                        chat.detail = result
                        work.observe(result, id: chat.selectedID!, context: session.projectContext)
                    }
                }
                let arguments = ProcessInfo.processInfo.arguments
                if let index = arguments.firstIndex(of: "--link"), index + 1 < arguments.count,
                   let url = URL(string: arguments[index + 1]) {
                    await session.receive(url, request: Self.request)
                } else if ["translation-detail", "translation-live", "source-chat"].contains(screen),
                          let destination = session.destination(screen == "source-chat" ? .newConversation : .translation,
                                                                id: screen == "source-chat" ? nil : Self.translationID,
                                                                translationID: screen == "source-chat" ? Self.translationID : nil) {
                    await session.navigate(destination, request: Self.request)
                }
            }
        }
    }

    static func previewPush(_ state: String) -> GlossiaPushNotifications {
        var values: [String: Data] = [:]
        let store = GlossiaPushStore(read: { values[$0] }, write: { values[$0] = try JSONSerialization.data(withJSONObject: $1) },
                                    remove: { values[$0] = nil })
        return GlossiaPushNotifications(store: store, environment: { state == "profile-push-unavailable" ? nil : "sandbox" },
            authorize: { state == "profile-push-enabled" }, allowed: { state == "profile-push-enabled" }, register: {}, unregister: {})
    }

    static func themeRequest(_ input: [String: Any]) async throws -> Data {
        if input["operation"] as? String == "validate_themes" { return try await GlossiaAppearance.bridge(input) }
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "--theme-catalog"), index + 1 < arguments.count,
              let data = Data(base64Encoded: arguments[index + 1]) else { throw CancellationError() }
        return try await GlossiaAppearance.bridge(["operation": "validate_themes", "catalog": JSONSerialization.jsonObject(with: data)])
    }

    static let chat: [String: Any] = [
        "conversation": ["id": "93cf36a3-802e-4f91-9112-77d8a919efc5", "title": "Our next language", "status": "completed"],
        "messages": [
            ["id": "one", "role": "user", "content": "We’re launching in Japan. Where should we start?"],
            ["id": "two", "role": "assistant", "content": "Let's start with your welcome flow and pricing page.\n\nYour project already supports English, Spanish and German. Japanese would be a new target language.\n\nBefore translating, agree on a glossary for your product names and a voice that feels natural to your Japanese readers."],
            ["id": "three", "role": "user", "content": "Can you help me plan the glossary?"],
            ["id": "four", "role": "assistant", "content": "Of course. Gather your product names, navigation labels, and the terms people see during onboarding. We can decide which to translate and which to keep."],
        ],
    ]

    static let translationID = "abc12345-802e-4f91-9112-77d8a919efc5"
    static let translation: [String: Any] = [
        "id": translationID, "commit_message": "Refresh the welcome experience", "status": "completed",
        "source_language": "en", "target_languages": ["es", "de"], "translated_content_count": 24,
        "summary": "Updated onboarding copy across two languages.", "commit_sha": "a1b2c3d4e5f6",
    ]

    static var conversationOrigins: [String: String] = [:]
    static var liveConnections: [String: Int] = [:]

    static func activityConversation(_ phase: String) -> [String: Any] {
        var conversation = chat["conversation"] as! [String: Any]
        conversation["status"] = phase
        var messages = [["id": "aaaaaaaa-802e-4f91-9112-77d8a919efc5", "role": "user",
                         "content": "Review the Japanese onboarding copy."]]
        if phase == "completed" { messages.append(["id": "preview-answer", "role": "assistant", "content": "The review is ready."]) }
        return ["conversation": conversation, "messages": messages]
    }

    static func translationSnapshot(done: Int, running: Bool) -> [String: Any] {
        var session = translation
        session["status"] = running ? "running" : "completed"
        session["translated_content_count"] = done
        return ["session": session,
                "progress": ["seq": 12, "summary": ["total": 4, "checked": 4, "needs_translation": 3,
                                                     "assessed?": true, "done": done, "skipped": 1,
                                                     "failed": 0, "cancelled": 0],
                             "items": [
                                ["output_path": "locales/es/welcome.json", "locale": "es", "status": "done"],
                                ["output_path": "locales/de/welcome.json", "locale": "de", "status": running ? "running" : "done"],
                                ["output_path": "locales/de/pricing.json", "locale": "de", "status": running ? "queued" : "done"],
                             ], "omitted_items": 0]]
    }

    static func request(_ input: [String: Any]) async throws -> [String: Any] {
        if input["operation"] as? String == "translation_reviews" { return ["reviews": []] }
        if input["operation"] as? String == "translation" {
            guard input["id"] as? String == translationID else { throw GlossiaFailure(kind: "not_found", message: "This translation is no longer available.") }
            let running = ProcessInfo.processInfo.arguments.contains("translation-live")
            return translationSnapshot(done: running ? 1 : 3, running: running)
        }
        if input["operation"] as? String == "translation_live" {
            switch input["action"] as? String {
            case "open":
                let handle = UUID().uuidString
                liveConnections[handle] = 0
                return ["connection": handle]
            case "next":
                let handle = input["connection"] as? String ?? ""
                guard let step = liveConnections[handle] else { return ["state": "closed"] }
                let running = ProcessInfo.processInfo.arguments.contains("translation-live") && step == 0
                if step > 0 { try await Task.sleep(for: .seconds(step == 1 ? 8 : 30)) }
                guard liveConnections[handle] != nil else { return ["state": "closed"] }
                liveConnections[handle] = step + 1
                return ["sequence": step + 1, "state": "live",
                        "snapshot": translationSnapshot(done: running ? 1 : 3, running: running)]
            default:
                if let handle = input["connection"] as? String { liveConnections[handle] = nil }
                return ["closed": true]
            }
        }
        if input["operation"] as? String == "conversation" {
            if ["create", "send"].contains(input["action"] as? String ?? "") {
                let id = input["id"] as! String
                let creating = input["action"] as? String == "create"
                if creating { conversationOrigins[id] = input["translation_session_id"] as? String }
                return ["conversation": ["id": id, "title": input["content"] as? String ?? "New conversation",
                                         "status": creating ? "idle" : "completed", "translation_session_id": conversationOrigins[id] as Any? ?? NSNull()],
                        "messages": input["content"].map { [["id": "preview-message", "role": "user", "content": $0]] } ?? []]
            }
            return chat
        }
        if input["operation"] as? String == "workspace" {
            let organization = (input["selection"] as? [String: Any])?["organization"] as? String ?? "acme"
            let project = (input["selection"] as? [String: Any])?["project"] as? String ?? "website"
            return ["organizations": [["handle": "acme", "name": "Acme"], ["handle": "other", "name": "Other team"]],
                    "selection": ["organization": organization, "project": project],
                    "projects": [["handle": "website", "name": "Website"], ["handle": "docs", "name": "Documentation"], ["handle": "mobile", "name": "Mobile app"]]]
        }
        switch input["resource"] as? String {
        case "conversations":
            return ["conversations": [["id": "93cf36a3-802e-4f91-9112-77d8a919efc5", "title": "Our next language", "status": "completed", "updated_at": "2026-10-25T09:30:00Z"]], "meta": ["has_next_page?": false]]
        case "translations":
            return ["sessions": [
                translation,
                ["id": "def12345-802e-4f91-9112-77d8a919efc5", "commit_message": "Introduce team workspaces", "source_language": "en", "target_languages": ["es", "de"], "status": "running", "translated_content_count": 8],
            ], "meta": ["has_next_page?": false]]
        case "analytics":
            let days = input["days"] as? Int ?? 30
            // Dated preview records only. Production charts use the server's buckets unchanged.
            let records = [0: [3300, 1200], 1: [2900, 1100], 2: [1380, 600],
                           3: [1600, 800], 5: [1000, 450], 6: [800, 300],
                           24: [1500, 700], 60: [2500, 1000]]
            let formatter = ISO8601DateFormatter()
            let end = formatter.date(from: "2026-10-25T00:00:00Z")!
            let points: [[String: Any]] = (0..<days).reversed().map { age in
                let counts = records[age] ?? [0, 0]
                return ["bucket": formatter.string(from: end.addingTimeInterval(-Double(age) * 86_400)),
                        "pageviews": counts[0], "unique_visitors": counts[1]]
            }
            let pageviews = records.filter { $0.key < days }.values.reduce(0) { $0 + $1[0] }
            let visitors = days == 7 ? 2900 : (days == 30 ? 3206 : 3900)
            return ["summary": ["pageviews": pageviews, "unique_visitors": visitors,
                                "locale_gap_visits": days == 7 ? 700 : (days == 30 ? 846 : 1100),
                                "top_country": "DE", "top_browser_language": "de"],
                    "top_pages": [["pathname": "/", "pageviews": pageviews - 6230], ["pathname": "/pricing", "pageviews": 3240], ["pathname": "/docs", "pageviews": 2990]],
                    "traffic": ["granularity": "day", "points": points], "days": days]
        case "profile":
            return ["user": ["id": "person", "name": "Alex Rivera", "email": "alex@example.com", "handle": "alex"], "server_version": "0.1.0-preview"]
        default: return [:]
        }
    }
}

// Deterministic review states are isolated in this preview bundle, not the app.
private struct ReviewPreview: View {
    @StateObject private var reviews: TranslationReviewsModel
    @State private var resumed = false
    let state: String
    static let reviewID = "def12345-802e-4f91-9112-77d8a919efc5"

    init(state: String) {
        self.state = state
        let model = TranslationReviewsModel(id: GlossiaPreviewApp.translationID) { input in try await Self.request(input, state: state) }
        _reviews = StateObject(wrappedValue: model)
    }

    var body: some View {
        NavigationStack {
            TranslationDetailView(destination: GlossiaDestination(screen: .translation, server: "https://glossia.example.com/",
                organization: "acme", project: "website", id: GlossiaPreviewApp.translationID),
                request: { try await Self.request($0, state: state) }, reviewsModel: reviews,
                openResumed: { _ in resumed = true }) {}
                .navigationDestination(isPresented: $resumed) { Text("Resumed translation").navigationTitle("Translation") }
        }
    }

    static func row(_ status: String) -> [String: Any] {
        var row: [String: Any] = ["id": reviewID, "translation_session_id": GlossiaPreviewApp.translationID,
            "status": status, "conversation_id": GoalFixture.chatID, "locale": "es", "question": "Should we address the reader with tú or usted?",
            "source_path": "locales/en/welcome.json", "output_path": "locales/es/welcome.json",
            "source_excerpt": "Welcome back!", "translation_excerpt": "¡Bienvenido de nuevo!",
            "inserted_at": "2026-10-25T10:00:00Z"]
        if status == "answered" {
            row["answer"] = "Use informal tú."
            row["guidance"] = "Use informal tú in Spanish onboarding."
            row["context_path"] = "L10N/es.md"
            row["resumed_session_id"] = "aaa12345-802e-4f91-9112-77d8a919efc5"
        }
        return row
    }

    static func request(_ input: [String: Any], state: String) async throws -> [String: Any] {
        switch input["operation"] as? String {
        case "translation":
            var session = GlossiaPreviewApp.translation; session["status"] = "awaiting_input"
            return ["session": session]
        case "translation_live":
            if input["action"] as? String == "open" { return ["connection": "preview-review"] }
            if input["action"] as? String == "close" { return ["closed": true] }
            try await Task.sleep(for: .seconds(3600)); return ["state": "closed"]
        case "translation_reviews":
            if state == "review-loading" { try await Task.sleep(for: .seconds(3600)) }
            if state == "review-denied" { throw GlossiaFailure(kind: "forbidden", message: "Permission denied") }
            if state == "review-error" { throw GlossiaFailure(kind: "network", message: "Offline. Your translation is still available.") }
            if input["action"] as? String == "answer" { return ["review": row("answered")] }
            return ["reviews": [row(state == "review-answered" ? "answered" : state == "review-stale" ? "stale" : "open")]]
        default: return [:]
        }
    }
}
