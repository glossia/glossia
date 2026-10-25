import Foundation
import GlossiaCoreFFI
import SwiftUI

struct GlossiaThemeCatalog: Decodable {
    let revision: String
    let defaultThemeId: String
    let themes: [GlossiaTheme]

    var theme: GlossiaTheme? { themes.first { $0.id == defaultThemeId } }
}

struct GlossiaTheme: Decodable {
    struct Palette: Decodable {
        let background, surface, subtle, text, secondaryText, border, accent, onAccent, tint: String
    }
    let id: String
    let buttonRadius, cardRadius: Double
    let light, dark: Palette
}

// Appearance is public instance metadata. It never enters the credential actor
// and a theme failure cannot reject a login or delay authenticated requests.
@MainActor
final class GlossiaAppearance: ObservableObject {
    @Published private(set) var catalog: GlossiaThemeCatalog?
    private(set) var server: String?
    private let preferences: UserDefaults
    private let request: ([String: Any]) async throws -> Data
    private var generation = UUID()
    private var refreshedAt: Date?
    private var loading = false

    init(preferences: UserDefaults = .standard,
         request: @escaping ([String: Any]) async throws -> Data = GlossiaAppearance.bridge) {
        self.preferences = preferences
        self.request = request
    }

    func configure(server address: String) async {
        let origin = Self.origin(address)
        if server == origin, catalog != nil || loading { await refresh(); return }
        generation = UUID()
        let ticket = generation
        server = origin
        catalog = nil // Never display the previous server's appearance while loading.
        refreshedAt = nil
        loading = true
        guard let origin else { loading = false; return }
        if let cached = preferences.data(forKey: key(origin)), cached.count <= 65_536,
           let value = try? JSONSerialization.jsonObject(with: cached),
           let validated = try? await request(["operation": "validate_themes", "catalog": value]),
           ticket == generation, let catalog = try? Self.decode(validated) {
            self.catalog = catalog
        }
        guard ticket == generation else { return }
        loading = false
        await refresh()
    }

    func refresh() async {
        guard let server, !loading, refreshedAt.map({ Date().timeIntervalSince($0) >= 300 }) ?? true else { return }
        let ticket = generation
        loading = true
        defer { if ticket == generation { loading = false; refreshedAt = .now } }
        guard let data = try? await request(["operation": "themes", "server": server]),
              ticket == generation, let catalog = try? Self.decode(data) else { return }
        self.catalog = catalog
        preferences.set(data, forKey: key(server))
    }

    static func origin(_ address: String) -> String? {
        guard var parts = URLComponents(string: address.trimmingCharacters(in: .whitespacesAndNewlines)),
              parts.scheme?.lowercased() == "https", let host = parts.host, !host.isEmpty,
              parts.user == nil, parts.password == nil, parts.query == nil, parts.fragment == nil,
              parts.path.isEmpty || parts.path == "/" else { return nil }
        parts.scheme = "https"; parts.host = host.lowercased(); parts.path = "/"
        if parts.port == 443 { parts.port = nil }
        return parts.url?.absoluteString
    }

    private func key(_ origin: String) -> String { "glossia.appearance.\(origin).catalog" }

    private static func decode(_ data: Data) throws -> GlossiaThemeCatalog {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(GlossiaThemeCatalog.self, from: data)
    }

    nonisolated static func bridge(_ action: [String: Any]) async throws -> Data {
        let data = try JSONSerialization.data(withJSONObject: action)
        return try await Task.detached(priority: .utility) {
            try Task.checkCancellation()
            return try String(decoding: data, as: UTF8.self).withCString { input in
                guard let output = glossia_core_execute(input) else { throw CancellationError() }
                defer { glossia_core_free(output) }
                let envelope = try JSONSerialization.jsonObject(with: Data(String(cString: output).utf8)) as? [String: Any]
                guard let value = envelope?["ok"] else { throw CancellationError() }
                return try JSONSerialization.data(withJSONObject: value)
            }
        }.value
    }
}

private struct GlossiaTokensKey: EnvironmentKey {
    static let defaultValue = GlossiaBrand()
}

extension EnvironmentValues {
    var glossiaTokens: GlossiaBrand {
        get { self[GlossiaTokensKey.self] }
        set { self[GlossiaTokensKey.self] = newValue }
    }
}

struct GlossiaThemeScope: ViewModifier {
    @ObservedObject var appearance: GlossiaAppearance
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        let tokens = GlossiaBrand(theme: contrast == .increased ? nil : appearance.catalog?.theme, scheme: scheme)
        content.environment(\.glossiaTokens, tokens)
            .tint(tokens.tint)
            .foregroundStyle(tokens.ink, tokens.muted, tokens.muted)
            .buttonBorderShape(.roundedRectangle(radius: tokens.buttonRadius))
    }
}

struct GlossiaPrimaryAction: ViewModifier {
    @Environment(\.glossiaTokens) private var tokens
    @Environment(\.isEnabled) private var enabled

    func body(content: Content) -> some View {
        content.tint(tokens.accent)
            .foregroundStyle(enabled ? tokens.onAccent : tokens.muted)
            .buttonBorderShape(.roundedRectangle(radius: tokens.buttonRadius))
    }
}
