import Foundation
import SwiftUI
import Testing
import UIKit

@Suite @MainActor
struct AppearanceTests {
    static func catalog(_ revision: String) -> [String: Any] {
        ["schema_version": 1, "revision": revision, "default_theme_id": "custom", "themes": [[
            "id": "custom", "name": "Custom", "description": "Server theme fixture", "typography": "standard",
            "button_radius": 6, "card_radius": 20,
            "light": ["background": "#FAF8F5", "surface": "#FFFFFF", "subtle": "#F2EFE9", "text": "#1C1917",
                      "secondary_text": "#5C564E", "border": "#E4E0D9", "accent": "#086185", "on_accent": "#FFFFFF", "tint": "#086185"],
            "dark": ["background": "#1C1917", "surface": "#2A2621", "subtle": "#2A2621", "text": "#FAF8F5",
                     "secondary_text": "#D1CDC5", "border": "#3D3833", "accent": "#66C7E8", "on_accent": "#000000", "tint": "#66C7E8"]
        ]]]
    }

    @Test func serverThemesPersistOfflineAndNeverCrossOrigins() async throws {
        let name = "glossia.appearance.test.\(UUID())"
        let preferences = try #require(UserDefaults(suiteName: name))
        defer { preferences.removePersistentDomain(forName: name) }
        var calls = 0
        let appearance = GlossiaAppearance(preferences: preferences) { input in
            calls += 1
            return try await GlossiaAppearance.bridge(["operation": "validate_themes", "catalog": Self.catalog("remote-1")])
        }
        await appearance.configure(server: " HTTPS://ONE.EXAMPLE:443 ")
        #expect(appearance.server == "https://one.example/")
        #expect(appearance.catalog?.revision == "remote-1")
        await appearance.configure(server: "https://one.example/")
        await appearance.refresh()
        #expect(calls == 1) // Foreground refresh is throttled, including equivalent origins.
        let restored = GlossiaAppearance(preferences: preferences) { input in
            if input["operation"] as? String == "validate_themes" { return try await GlossiaAppearance.bridge(input) }
            throw GlossiaFailure(kind: "theme_unavailable", message: "Offline")
        }
        await restored.configure(server: "https://one.example")
        #expect(restored.catalog?.revision == "remote-1")
        await restored.configure(server: "https://two.example")
        #expect(restored.catalog == nil)
        await restored.configure(server: "https://one.example/path")
        #expect(restored.server == nil)
        #expect(restored.catalog == nil)

        // A cached payload must pass Rust validation again, not merely decode.
        var invalid = Self.catalog("invalid")
        invalid["schema_version"] = 99
        preferences.set(try JSONSerialization.data(withJSONObject: invalid), forKey: "glossia.appearance.https://bad.example/.catalog")
        await restored.configure(server: "https://bad.example")
        #expect(restored.catalog == nil)
    }

    @Test func aLatePreviousServerResponseCannotReplaceTheSelectedTheme() async throws {
        let name = "glossia.appearance.test.\(UUID())"
        let preferences = try #require(UserDefaults(suiteName: name))
        defer { preferences.removePersistentDomain(forName: name) }
        var delayed: CheckedContinuation<Data, Error>?
        let old = try await GlossiaAppearance.bridge(["operation": "validate_themes", "catalog": Self.catalog("old")])
        let current = try await GlossiaAppearance.bridge(["operation": "validate_themes", "catalog": Self.catalog("current")])
        let appearance = GlossiaAppearance(preferences: preferences) { input in
            if input["server"] as? String == "https://old.example/" {
                return try await withCheckedThrowingContinuation { delayed = $0 }
            }
            return current
        }
        let first = Task { await appearance.configure(server: "https://old.example") }
        for _ in 0..<1000 { if delayed != nil { break }; await Task.yield() }
        let continuation = try #require(delayed)
        await appearance.configure(server: "https://current.example")
        continuation.resume(returning: old)
        await first.value
        #expect(appearance.server == "https://current.example/")
        #expect(appearance.catalog?.revision == "current")
        #expect(preferences.data(forKey: "glossia.appearance.https://old.example/.catalog") == nil)
        let theme = try #require(appearance.catalog?.theme)
        let light = GlossiaBrand(theme: theme, scheme: .light)
        let dark = GlossiaBrand(theme: theme, scheme: .dark)
        #expect(light.buttonRadius == 6)
        #expect(dark.radius == 20)
        #expect(UIColor(light.accent).cgColor.components?.prefix(3).map { Int(($0 * 255).rounded()) } == [8, 97, 133])
        #expect(UIColor(dark.accent).cgColor.components?.prefix(3).map { Int(($0 * 255).rounded()) } == [102, 199, 232])
    }
}
