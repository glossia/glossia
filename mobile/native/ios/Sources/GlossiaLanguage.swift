import Foundation
import SwiftUI

enum GlossiaLanguage {
    static let preferenceKey = "glossia.app-language"

    static func available(in bundle: Bundle = .main) -> [String] {
        bundle.localizations.filter { $0 != "Base" }.sorted()
    }

    static func selected(preferences: UserDefaults = .standard, bundle: Bundle = .main) -> String {
        let value = preferences.string(forKey: preferenceKey) ?? ""
        return available(in: bundle).contains(value) ? value : ""
    }

    static func direction(for language: String, system: LayoutDirection) -> LayoutDirection {
        guard !language.isEmpty else { return system }
        return Locale.Language(identifier: language).characterDirection == .rightToLeft ? .rightToLeft : .leftToRight
    }

    static func localized(key: String, preferences: UserDefaults = .standard, bundle: Bundle = .main) -> String {
        resourceBundle(preferences: preferences, bundle: bundle).localizedString(forKey: key, value: nil, table: nil)
    }

    static func localized(_ value: String.LocalizationValue, preferences: UserDefaults = .standard,
                          bundle: Bundle = .main) -> String {
        let language = selected(preferences: preferences, bundle: bundle)
        return String(localized: value, bundle: resourceBundle(preferences: preferences, bundle: bundle),
                      locale: language.isEmpty ? .current : Locale(identifier: language))
    }

    private static func resourceBundle(preferences: UserDefaults, bundle: Bundle) -> Bundle {
        let language = selected(preferences: preferences, bundle: bundle)
        return bundle.url(forResource: language, withExtension: "lproj").flatMap(Bundle.init(url:)) ?? bundle
    }
}

extension String {
    // Model errors and UIKit copy must use the same choice as SwiftUI. The
    // explicit-bundle Foundation initializer above remains unchanged.
    init(localized value: String.LocalizationValue) {
        self = GlossiaLanguage.localized(value)
    }
}

struct GlossiaLanguageScope: ViewModifier {
    @AppStorage(GlossiaLanguage.preferenceKey) private var storedLanguage = ""
    @Environment(\.layoutDirection) private var systemDirection

    func body(content: Content) -> some View {
        let language = GlossiaLanguage.available().contains(storedLanguage) ? storedLanguage : ""
        content
            .environment(\.locale, language.isEmpty ? .current : Locale(identifier: language))
            .environment(\.layoutDirection, GlossiaLanguage.direction(for: language, system: systemDirection))
    }
}

struct GlossiaLanguagePicker: View {
    @AppStorage(GlossiaLanguage.preferenceKey) private var language = ""

    var body: some View {
        Picker("App language", selection: Binding(
            get: { GlossiaLanguage.available().contains(language) ? language : "" },
            set: { language = $0 }
        )) {
            Text("System default").tag("")
            ForEach(GlossiaLanguage.available(), id: \.self) { identifier in
                Text(verbatim: Locale(identifier: identifier).localizedString(forIdentifier: identifier) ?? identifier)
                    .tag(identifier)
            }
        }
        .accessibilityIdentifier("app-language")
    }
}
