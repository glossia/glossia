import Foundation
import GlossiaCoreFFI
import SwiftUI

// A destination names a place, not an API request or permission. Rust owns the
// URL grammar and validates internal destinations through the same contract.
struct GlossiaDestination: Codable, Equatable, Hashable {
    enum Screen: String, Codable {
        case toki, conversation, translations, translation, analytics, profile
        case newConversation = "new_conversation"

        var tab: String {
            switch self {
            case .conversation, .newConversation: "toki"
            case .translation: "translations"
            default: rawValue
            }
        }
    }

    let screen: Screen
    let server: String
    var organization: String?
    var project: String?
    var id: String?
    var translationID: String?

    enum CodingKeys: String, CodingKey {
        case screen, server, organization, project, id
        case translationID = "translation_id"
    }

    static func parse(_ url: URL) throws -> GlossiaDestination {
        try command(["operation": "navigation", "action": "parse", "url": url.absoluteString]).destination
    }

    func validated() throws -> GlossiaDestination {
        try Self.command(["operation": "navigation", "action": "link", "destination": object]).destination
    }

    var url: URL? {
        (try? Self.command(["operation": "navigation", "action": "link", "destination": object])).flatMap { URL(string: $0.url) }
    }

    private var object: Any { get throws { try JSONSerialization.jsonObject(with: JSONEncoder().encode(self)) } }

    private struct Result: Decodable {
        let destination: GlossiaDestination
        let url: String
    }

    private static func command(_ request: [String: Any]) throws -> Result {
        let data = try JSONSerialization.data(withJSONObject: request)
        return try String(decoding: data, as: UTF8.self).withCString { input in
            guard let output = glossia_core_execute(input) else { throw invalid() }
            defer { glossia_core_free(output) }
            let envelope = try JSONSerialization.jsonObject(with: Data(String(cString: output).utf8)) as? [String: Any]
            guard let value = envelope?["ok"] else { throw invalid() }
            return try JSONDecoder().decode(Result.self, from: JSONSerialization.data(withJSONObject: value))
        }
    }

    private static func invalid() -> GlossiaFailure {
        GlossiaFailure(kind: "invalid_link", message: String(localized: "This Glossia link is invalid or is not supported by this app."))
    }
}

@MainActor
final class GlossiaNavigation: ObservableObject {
    @Published private(set) var targets: [String: GlossiaDestination] = [:]
    @Published private(set) var revisions: [String: UUID] = [:]
    @Published var message: String?
    private(set) var pending: GlossiaDestination?
    private(set) var pendingRevision = UUID()
    private var resolving: UUID?
    private var protections: [UUID: () -> Bool] = [:]

    var hasProtectedWork: Bool { protections.values.contains { $0() } }

    func protect(_ id: UUID, while active: @escaping () -> Bool) { protections[id] = active }
    func unprotect(_ id: UUID) { protections[id] = nil }

    func queue(_ destination: GlossiaDestination) {
        pending = destination
        pendingRevision = UUID()
        message = nil
    }

    func begin() -> (GlossiaDestination, UUID)? {
        guard let pending, resolving != pendingRevision else { return nil }
        resolving = pendingRevision
        return (pending, pendingRevision)
    }

    func finish(_ revision: UUID) { if resolving == revision { resolving = nil } }
    func isCurrent(_ revision: UUID) -> Bool { pending != nil && pendingRevision == revision }

    func reject(_ message: String, discard: Bool = true) {
        if discard { pending = nil; pendingRevision = UUID() }
        self.message = message
    }

    func activate(_ destination: GlossiaDestination) {
        pending = nil
        pendingRevision = UUID()
        message = nil
        targets[destination.screen.tab] = destination
        revisions[destination.screen.tab] = UUID()
    }

    func clearTarget(_ tab: String) { targets[tab] = nil }

    func workspaceChanged() {
        targets = [:]; revisions = [:]; protections = [:]
    }

    func reset() {
        pending = nil; pendingRevision = UUID(); resolving = nil
        message = nil
        workspaceChanged()
    }
}

private struct GlossiaNavigationKey: EnvironmentKey {
    static let defaultValue: GlossiaNavigation? = nil
}

extension EnvironmentValues {
    var glossiaNavigation: GlossiaNavigation? {
        get { self[GlossiaNavigationKey.self] }
        set { self[GlossiaNavigationKey.self] = newValue }
    }
}

struct GlossiaLinkNotice: ViewModifier {
    @ObservedObject var navigation: GlossiaNavigation
    let retry: () -> Void

    func body(content: Content) -> some View {
        content.alert("Glossia link", isPresented: Binding(
            get: { navigation.message != nil }, set: { if !$0 { navigation.message = nil } }
        )) {
            if navigation.pending != nil { Button("Retry", action: retry) }
            Button("OK", role: .cancel) { navigation.message = nil }
        } message: { Text(navigation.message ?? "") }
    }
}
