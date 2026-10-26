import SwiftUI

@MainActor
final class FluentLanguagesModel: ObservableObject {
    @Published var draft = ""
    @Published private(set) var saved: [String] = []
    @Published private(set) var loaded = false
    @Published private(set) var busy = false
    @Published private(set) var error: String?
    private var revision = 0
    private let request: GlossiaRequest
    init(request: @escaping GlossiaRequest) { self.request = request }
    var languages: [String] { draft.split(whereSeparator: { $0 == "," || $0.isWhitespace }).map(String.init) }
    var dirty: Bool { languages != saved }
    func discard() { guard !busy else { return }; draft = saved.joined(separator: ", ") }
    func invalidate() { revision += 1; busy = false }
    func load() async {
        guard !busy, !dirty else { return }
        let ticket = revision; busy = true; error = nil
        defer { if ticket == revision { busy = false } }
        do {
            let result = try await request(["operation": "resource", "resource": "profile"])
            guard ticket == revision, !Task.isCancelled else { return }
            saved = (result["user"] as? [String: Any])?["fluent_languages"] as? [String] ?? []
            draft = saved.joined(separator: ", "); loaded = true
        } catch { if ticket == revision { self.error = error.localizedDescription } }
    }
    func save() async {
        guard loaded, dirty, !busy else { return }
        let ticket = revision; busy = true; error = nil
        defer { if ticket == revision { busy = false } }
        do {
            let result = try await request(["operation": "fluent_languages", "fluent_languages": languages])
            guard ticket == revision, !Task.isCancelled else { return }
            guard let languages = (result["user"] as? [String: Any])?["fluent_languages"] as? [String] else {
                throw GlossiaFailure(kind: "invalid_response", message: String(localized: "Could not confirm fluent languages. Your draft is unchanged."))
            }
            saved = languages; draft = languages.joined(separator: ", ")
        } catch { if ticket == revision { self.error = error.localizedDescription } }
    }
}

struct FluentLanguagesView: View {
    @StateObject private var model: FluentLanguagesModel
    @Environment(\.glossiaNavigation) private var navigation
    @State private var protection = UUID()
    init(request: @escaping GlossiaRequest) { _model = StateObject(wrappedValue: FluentLanguagesModel(request: request)) }
    var body: some View {
        Form {
            Section("Languages you speak fluently") {
                Text("These languages help invite authorized linguists into the same shared review conversation. They do not change the app language or grant project access.")
                TextField("BCP47 tags, for example es, ar, zh-Hant", text: $model.draft)
                    .textInputAutocapitalization(.never).autocorrectionDisabled().accessibilityIdentifier("fluent-languages")
                    .environment(\.layoutDirection, .leftToRight)
                    .disabled(!model.loaded || model.busy)
                Text("Separate language tags with commas. Leave empty to remove your fluent languages.").font(.caption)
            }
            if let error = model.error { Section { Text(error).foregroundStyle(.red) } }
            if model.busy { ProgressView("Saving or loading languages…") }
            Section {
                Button("Save fluent languages") { Task { await model.save() } }.disabled(!model.dirty || model.busy || !model.loaded)
                Button("Discard changes", role: .destructive) { model.discard() }.disabled(model.busy || !model.dirty)
                if !model.loaded { Button("Retry") { Task { await model.load() } }.disabled(model.busy) }
            }
        }
        .navigationTitle("Fluent languages").navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(model.dirty || model.busy)
        .onAppear { navigation?.protect(protection) { [weak model] in model?.dirty == true || model?.busy == true } }
        .task { await model.load() }
        .onDisappear { model.invalidate() }
    }
}
