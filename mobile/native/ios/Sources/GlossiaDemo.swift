import Foundation

// Signed-out demo for people without a Glossia account, including App Review.
// It answers the same commands as the Rust core with local sample data, so the
// production views run unchanged. Nothing is sent over the network or stored.
@MainActor
final class GlossiaDemo {
    static let server = "https://demo.glossia.ai"
    static let organizations: [[String: Any]] = [["handle": "acme", "name": "Acme"]]
    static let projects: [[String: Any]] = [["handle": "website", "name": "Website"], ["handle": "docs", "name": "Documentation"]]

    private static let completedID = "5f0c8a52-6a3e-4b1f-9a0d-1c2b3d4e5f60"
    private static let runningID = "6a1d9b63-7b4f-4c20-8b1e-2d3c4e5f6071"
    private static let reviewSessionID = "7b2eac74-8c50-4d31-9c2f-3e4d5f607182"
    private static let reviewID = "8c3fbd85-9d61-4e42-8d30-4f5e60718293"
    private static let chatID = "93cf36a3-802e-4f91-9112-77d8a919efc5"
    private static let goalID = "a4d0ce96-ae72-4f53-9e41-506f718293a4"

    private var conversations: [String: [String: Any]] = [:]
    private var messages: [String: [[String: Any]]] = [:]
    private var replies: [String: (due: Date, to: String)] = [:]
    private var order: [String] = []
    private var answer: [String: Any]?
    private var fluentLanguages = ["en", "es"]
    private var runningDone = 1
    private var connections: Set<String> = []

    init() {
        add(["id": Self.chatID, "title": "Our next language", "status": "completed", "updated_at": "2026-11-02T09:30:00Z"], [
            Self.message("user", "We’re launching in Japan. Where should we start?"),
            Self.message("assistant", "Start with your welcome flow and pricing page.\n\nYour project already supports English, Spanish and German. Japanese would be a new target language.\n\nBefore translating, agree on a glossary for your product names and a voice that feels natural to your Japanese readers."),
        ])
        let question = Self.message("assistant", "Should we address Spanish readers with **tú** or **usted** in onboarding?")
        let reply = Self.message("user", "Our onboarding should feel friendly.", author: "Sam")
        var proposal = Self.message("assistant", "Use informal tú in Spanish onboarding.")
        proposal["status"] = "completed"; proposal["reply_to_id"] = reply["id"]
        add(["id": Self.goalID, "title": "Spanish onboarding", "status": "completed", "updated_at": "2026-11-02T10:00:00Z"],
            [question, reply, proposal])
    }

    func request(_ input: [String: Any]) async throws -> [String: Any] {
        switch input["operation"] as? String {
        case "workspace":
            let project = (input["selection"] as? [String: Any])?["project"] as? String
            return ["organizations": Self.organizations, "projects": Self.projects,
                    "selection": ["organization": "acme", "project": Self.projects.contains { $0["handle"] as? String == project } ? project! : "website"]]
        case "conversation": return try conversation(input)
        case "translation": return try snapshot(input["id"] as? String)
        case "translation_live": return try await live(input)
        case "translation_reviews":
            guard input["id"] as? String == Self.reviewSessionID else { return ["reviews": []] }
            if input["action"] as? String == "answer" {
                answer = ["answer": input["answer"] as? String ?? "", "guidance": input["guidance"] as Any? ?? NSNull()]
            }
            return input["action"] as? String == "answer" ? ["review": review] : ["reviews": [review]]
        case "fluent_languages":
            fluentLanguages = input["fluent_languages"] as? [String] ?? []
            return ["user": user]
        default: break
        }
        switch input["resource"] as? String {
        case "conversations":
            order.forEach(deliverReply)
            return ["conversations": order.reversed().compactMap { conversations[$0] }, "meta": ["has_next_page?": false]]
        case "translations":
            return ["sessions": [Self.completedID, Self.runningID, Self.reviewSessionID].map(session), "meta": ["has_next_page?": false]]
        case "analytics": return analytics(days: input["days"] as? Int ?? 30)
        case "profile": return ["user": user, "server_version": String(localized: "Demo")]
        default: throw GlossiaFailure(kind: "not_found", message: String(localized: "This is not available in the demo."))
        }
    }

    private var user: [String: Any] {
        ["id": "demo", "name": "Alex Rivera", "email": "alex@example.com", "handle": "alex", "fluent_languages": fluentLanguages]
    }

    private static func message(_ role: String, _ content: String, author: String? = nil) -> [String: Any] {
        var message: [String: Any] = ["id": UUID().uuidString.lowercased(), "role": role, "content": content]
        if let author { message["author"] = author }
        return message
    }

    private func add(_ conversation: [String: Any], _ history: [[String: Any]]) {
        let id = conversation["id"] as! String
        conversations[id] = conversation; messages[id] = history
        order.removeAll { $0 == id }; order.append(id)
    }

    private func thread(_ id: String) -> [String: Any] {
        deliverReply(id)
        var conversation = conversations[id]!
        if id == Self.goalID { conversation["linguistic_review"] = review }
        return ["conversation": conversation, "messages": messages[id] ?? []]
    }

    private func conversation(_ input: [String: Any]) throws -> [String: Any] {
        guard let id = input["id"] as? String else { throw GlossiaFailure(kind: "not_found", message: String(localized: "This conversation is no longer available.")) }
        switch input["action"] as? String {
        case "create":
            add(["id": id, "title": String(localized: "New conversation"), "status": "idle",
                 "translation_session_id": input["translation_session_id"] as Any? ?? NSNull()], [])
        case "send":
            guard conversations[id] != nil, let content = input["content"] as? String, let messageID = input["message_id"] as? String else { break }
            messages[id, default: []].append(["id": messageID, "role": "user", "content": content])
            if conversations[id]?["status"] as? String == "idle" { conversations[id]?["title"] = String(content.prefix(60)) }
            conversations[id]?["status"] = "running"
            replies[id] = (Date().addingTimeInterval(3), messageID)
            add(conversations[id]!, messages[id]!)
        default: break
        }
        guard conversations[id] != nil else { throw GlossiaFailure(kind: "not_found", message: String(localized: "This conversation is no longer available.")) }
        return thread(id)
    }

    private func deliverReply(_ id: String) {
        guard let reply = replies[id], reply.due <= Date() else { return }
        replies[id] = nil
        var message = Self.message("assistant", id == Self.goalID
            ? String(localized: "Thanks. Based on this conversation, I suggest informal tú for Spanish onboarding. Tap Review decision to save it for future translations.")
            : String(localized: "This is a demo reply with sample content. In your own workspace, Toki answers using your project’s glossary, voice, translations and analytics."))
        message["status"] = "completed"; message["reply_to_id"] = reply.to
        messages[id, default: []].append(message)
        conversations[id]?["status"] = "completed"
    }

    private var review: [String: Any] {
        var row: [String: Any] = ["id": Self.reviewID, "conversation_id": Self.goalID, "translation_session_id": Self.reviewSessionID,
            "status": answer == nil ? "open" : "answered", "locale": "es",
            "question": "Should we address the reader with tú or usted?",
            "source_path": "locales/en/welcome.json", "output_path": "locales/es/welcome.json",
            "source_excerpt": "Welcome back!", "translation_excerpt": "¡Bienvenido de nuevo!",
            "inserted_at": "2026-11-02T10:00:00Z",
            "participants": [["name": "Alex", "fluent_languages": ["es"]], ["name": "Sam", "fluent_languages": ["es-MX"]]]]
        if let answer {
            row["answer"] = answer["answer"]
            row["answered_by"] = ["id": "demo", "name": "Alex Rivera"]
            if let guidance = answer["guidance"] as? String { row["guidance"] = guidance; row["context_path"] = "L10N/es.md" }
        }
        return row
    }

    private func session(_ id: String) -> [String: Any] {
        switch id {
        case Self.completedID:
            return ["id": id, "commit_message": "Refresh the welcome experience", "status": "completed",
                    "source_language": "en", "target_languages": ["es", "de"], "translated_content_count": 24,
                    "summary": "Updated onboarding copy across two languages.", "commit_sha": "a1b2c3d4e5f6"]
        case Self.runningID:
            let done = runningDone >= 3
            return ["id": id, "commit_message": "Introduce team workspaces", "status": done ? "completed" : "running",
                    "source_language": "en", "target_languages": ["es", "de"], "translated_content_count": runningDone * 4,
                    "summary": done ? "Translated the team workspace pages." : "", "commit_sha": "b2c3d4e5f6a1"]
        default:
            return ["id": id, "commit_message": "Spanish onboarding tone", "status": answer == nil ? "awaiting_input" : "completed",
                    "source_language": "en", "target_languages": ["es"], "translated_content_count": 6, "commit_sha": "c3d4e5f6a1b2"]
        }
    }

    private func snapshot(_ id: String?) throws -> [String: Any] {
        guard let id, [Self.completedID, Self.runningID, Self.reviewSessionID].contains(id) else {
            throw GlossiaFailure(kind: "not_found", message: String(localized: "This translation is no longer available."))
        }
        let paths = id == Self.reviewSessionID ? [("locales/es/welcome.json", "es")]
            : [("locales/es/welcome.json", "es"), ("locales/de/welcome.json", "de"), ("locales/de/pricing.json", "de")]
        let done = id == Self.runningID ? runningDone : paths.count
        let items: [[String: Any]] = paths.enumerated().map { index, item in
            ["output_path": item.0, "locale": item.1, "status": index < done ? "done" : index == done ? "running" : "queued"]
        }
        return ["session": session(id),
                "progress": ["seq": done, "summary": ["total": paths.count, "checked": paths.count, "needs_translation": paths.count,
                                                      "assessed?": true, "done": done, "skipped": 0, "failed": 0, "cancelled": 0],
                             "items": items, "omitted_items": 0]]
    }

    private func live(_ input: [String: Any]) async throws -> [String: Any] {
        switch input["action"] as? String {
        case "open":
            let handle = UUID().uuidString
            connections.insert(handle)
            return ["connection": "\(handle)|\(input["id"] as? String ?? "")"]
        case "next":
            let connection = input["connection"] as? String ?? ""
            let parts = connection.split(separator: "|").map(String.init)
            guard parts.count == 2, connections.contains(parts[0]) else { return ["state": "closed"] }
            let after = (input["after"] as? NSNumber)?.intValue ?? 0
            if after > 0 { try await Task.sleep(for: .seconds(parts[1] == Self.runningID && runningDone < 3 ? 4 : 3600)) }
            guard connections.contains(parts[0]) else { return ["state": "closed"] }
            if after > 0, parts[1] == Self.runningID, runningDone < 3 { runningDone += 1 }
            return ["sequence": after + 1, "state": "live", "snapshot": try snapshot(parts[1])]
        default:
            if let connection = (input["connection"] as? String)?.split(separator: "|").first { connections.remove(String(connection)) }
            return ["closed": true]
        }
    }

    private func analytics(days: Int) -> [String: Any] {
        let formatter = ISO8601DateFormatter()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let today = calendar.startOfDay(for: Date())
        let points: [[String: Any]] = (0..<days).reversed().map { age in
            let wave = 900 + (age * 37 % 11) * 120 + (age % 7 < 5 ? 600 : 0)
            return ["bucket": formatter.string(from: today.addingTimeInterval(-Double(age) * 86_400)),
                    "pageviews": wave, "unique_visitors": wave * 2 / 5]
        }
        let pageviews = points.reduce(0) { $0 + ($1["pageviews"] as! Int) }
        return ["summary": ["pageviews": pageviews, "unique_visitors": pageviews / 3, "locale_gap_visits": pageviews / 9,
                            "top_country": "DE", "top_browser_language": "de"],
                "top_pages": [["pathname": "/", "pageviews": pageviews / 2], ["pathname": "/pricing", "pageviews": pageviews / 5],
                              ["pathname": "/docs", "pageviews": pageviews / 7]],
                "traffic": ["granularity": "day", "points": points], "days": days]
    }
}
