import SwiftUI

// Separate bundle and source list: these fixtures cannot authenticate and never
// enter the production app. They render the same production views.
@main
struct GlossiaPreviewApp: App {
    @StateObject private var session: GlossiaSession
    @StateObject private var chat: TokiModel
    @StateObject private var appearance = GlossiaAppearance(request: themeRequest)
    private let screen: String

    init() {
        screen = ProcessInfo.processInfo.arguments.dropFirst().first ?? "login"
        let session = GlossiaSession()
        session.restoring = false
        if screen != "login" {
            session.server = "https://glossia.example.com"
            session.organization = "acme"; session.project = "website"
            session.organizations = [["handle": "acme", "name": "Acme"], ["handle": "other", "name": "Other team"]]
            session.projects = [["handle": "website", "name": "Website"]]
            session.tab = screen == "empty" ? "toki" : screen
            if ["translations-empty", "translation-detail"].contains(screen) { session.tab = "translations" }
            if screen == "analytics-empty" { session.tab = "analytics" }
            if screen == "source-chat" { session.tab = "toki" }
        }
        _session = StateObject(wrappedValue: session)
        let state = screen
        let chat = TokiModel { input in
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
        _chat = StateObject(wrappedValue: chat)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if screen == "login" { GlossiaLoginView(session: session) }
                else if ["chat", "thinking", "failed", "empty-chat"].contains(screen) {
                    NavigationStack { TokiConversationView(model: chat) }
                } else if screen == "workspace" {
                    WorkspacePicker(session: session, request: Self.request)
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
                                                "top_country": "", "top_browser_language": ""], "top_pages": []]
                        }
                        return try await Self.request(value)
                    }.id(session.projectContext)
                }
            }
            .modifier(GlossiaThemeScope(appearance: appearance))
            .modifier(GlossiaLinkNotice(navigation: session.navigation) { Task { await session.resolveNavigation(request: Self.request) } })
            .task { await appearance.configure(server: session.server ?? "https://glossia.ai") }
            .onOpenURL { url in Task { await session.receive(url, request: Self.request) } }
            .task {
                let arguments = ProcessInfo.processInfo.arguments
                if let index = arguments.firstIndex(of: "--link"), index + 1 < arguments.count,
                   let url = URL(string: arguments[index + 1]) {
                    await session.receive(url, request: Self.request)
                } else if ["translation-detail", "source-chat"].contains(screen),
                          let destination = session.destination(screen == "source-chat" ? .newConversation : .translation,
                                                                id: screen == "source-chat" ? nil : Self.translationID,
                                                                translationID: screen == "source-chat" ? Self.translationID : nil) {
                    await session.navigate(destination, request: Self.request)
                }
            }
        }
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

    static func request(_ input: [String: Any]) async throws -> [String: Any] {
        if input["operation"] as? String == "translation" {
            guard input["id"] as? String == translationID else { throw GlossiaFailure(kind: "not_found", message: "This translation is no longer available.") }
            return ["session": translation]
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
            return ["summary": ["pageviews": 12480, "unique_visitors": 3206, "locale_gap_visits": 846, "top_country": "Germany", "top_browser_language": "de"],
                    "top_pages": [["pathname": "/", "pageviews": 6250], ["pathname": "/pricing", "pageviews": 3240], ["pathname": "/docs", "pageviews": 2990]], "days": input["days"] ?? 30]
        case "profile":
            return ["user": ["id": "person", "name": "Alex Rivera", "email": "alex@example.com", "handle": "alex"], "server_version": "0.1.0-preview"]
        default: return [:]
        }
    }
}
