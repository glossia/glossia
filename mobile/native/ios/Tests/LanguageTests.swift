import Foundation
import SwiftUI
import Testing

@Suite
struct LanguageTests {
    @Test func choicesFollowBundledCatalogsAndOverrideFixedCopyWithoutChangingFluency() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("bundle")
        let preferencesName = "glossia.language.test.\(UUID())"
        let preferences = try #require(UserDefaults(suiteName: preferencesName))
        defer {
            try? FileManager.default.removeItem(at: directory)
            preferences.removePersistentDomain(forName: preferencesName)
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let info = ["CFBundleIdentifier": preferencesName, "CFBundleDevelopmentRegion": "en"]
        try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
            .write(to: directory.appendingPathComponent("Info.plist"))
        let suggestion = "Which languages does this project support?"
        for (language, text, translatedSuggestion) in [
            ("en", "Review", suggestion),
            ("ar", "مراجعة", "ما اللغات التي يدعمها هذا المشروع؟"),
            ("pt-BR", "Revisão", "Quais idiomas este projeto suporta?")
        ] {
            let resource = directory.appendingPathComponent("\(language).lproj")
            try FileManager.default.createDirectory(at: resource, withIntermediateDirectories: true)
            let strings = "\"Review\" = \"\(text)\";\n\"\(suggestion)\" = \"\(translatedSuggestion)\";"
            try strings.write(to: resource.appendingPathComponent("Localizable.strings"), atomically: true, encoding: .utf8)
        }
        let bundle = try #require(Bundle(url: directory))
        #expect(GlossiaLanguage.available(in: bundle) == ["ar", "en", "pt-BR"])
        #expect(GlossiaLanguage.selected(preferences: preferences, bundle: bundle).isEmpty)
        preferences.set(["ja", "fr"], forKey: "fluent_languages")
        preferences.set("ar", forKey: GlossiaLanguage.preferenceKey)
        #expect(GlossiaLanguage.localized("Review", preferences: preferences, bundle: bundle) == "مراجعة")
        #expect(GlossiaLanguage.localized(key: suggestion, preferences: preferences, bundle: bundle) == "ما اللغات التي يدعمها هذا المشروع؟")
        preferences.set("pt-BR", forKey: GlossiaLanguage.preferenceKey)
        #expect(GlossiaLanguage.localized("Review", preferences: preferences, bundle: bundle) == "Revisão")
        #expect(GlossiaLanguage.localized(key: suggestion, preferences: preferences, bundle: bundle) == "Quais idiomas este projeto suporta?")
        #expect(GlossiaLanguage.selected(preferences: try #require(UserDefaults(suiteName: preferencesName)), bundle: bundle) == "pt-BR")
        preferences.set("en", forKey: GlossiaLanguage.preferenceKey)
        #expect(GlossiaLanguage.localized(key: suggestion, preferences: preferences, bundle: bundle) == suggestion)
        #expect(GlossiaLanguage.localized(key: "Missing translation", preferences: preferences, bundle: bundle) == "Missing translation")
        preferences.set("de", forKey: GlossiaLanguage.preferenceKey)
        #expect(GlossiaLanguage.selected(preferences: preferences, bundle: bundle).isEmpty)
        preferences.removeObject(forKey: GlossiaLanguage.preferenceKey)
        #expect(GlossiaLanguage.selected(preferences: preferences, bundle: bundle).isEmpty)
        #expect(preferences.stringArray(forKey: "fluent_languages") == ["ja", "fr"])
    }

    @Test func anOverrideControlsDirectionWhileSystemDefaultPreservesIt() {
        #expect(GlossiaLanguage.direction(for: "", system: .rightToLeft) == .rightToLeft)
        #expect(GlossiaLanguage.direction(for: "", system: .leftToRight) == .leftToRight)
        #expect(GlossiaLanguage.direction(for: "en", system: .rightToLeft) == .leftToRight)
        #expect(GlossiaLanguage.direction(for: "pt-BR", system: .rightToLeft) == .leftToRight)
        #expect(GlossiaLanguage.direction(for: "ar", system: .leftToRight) == .rightToLeft)
        #expect(GlossiaLanguage.direction(for: "he", system: .leftToRight) == .rightToLeft)
    }
}
