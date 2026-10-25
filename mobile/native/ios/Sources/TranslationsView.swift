import SwiftUI

@MainActor
final class TranslationsModel: ObservableObject {
    @Published var sessions: [[String: Any]] = []
    @Published var busy = false
    @Published var error: String?
    @Published var hasMore = false
    private var page = 0
    private let request: GlossiaRequest

    init(request: @escaping GlossiaRequest) { self.request = request }

    func load(reset: Bool = false) async {
        guard !busy else { return }
        busy = true; error = nil
        defer { busy = false }
        let next = reset ? 1 : page + 1
        do {
            let value = try await request(["operation": "resource", "resource": "translations", "page": next])
            try Task.checkCancellation()
            let rows = value["sessions"] as? [[String: Any]] ?? []
            if reset { sessions = [] }
            let ids = Set(sessions.compactMap { $0["id"] as? String })
            sessions += rows.filter { !ids.contains($0["id"] as? String ?? "") }
            page = next
            hasMore = (value["meta"] as? [String: Any])?["has_next_page?"] as? Bool ?? false
        } catch is CancellationError { }
        catch { self.error = error.localizedDescription }
    }
}

struct TranslationsView: View {
    @StateObject private var model: TranslationsModel
    @Environment(\.glossiaTokens) private var tokens
    let hasProject: Bool
    var open: ((String) -> Void)?

    init(request: @escaping GlossiaRequest, hasProject: Bool, open: ((String) -> Void)? = nil) {
        _model = StateObject(wrappedValue: TranslationsModel(request: request))
        self.hasProject = hasProject
        self.open = open
    }

    var body: some View {
        List {
            if !hasProject {
                ContentUnavailableView("Choose a project", systemImage: "folder",
                                       description: Text("Select a workspace to see its translations."))
            } else {
                if let error = model.error {
                    GlossiaErrorView(message: error) { Task { await model.load(reset: model.sessions.isEmpty) } }
                }
                if model.busy { ProgressView("Loading translations…") }
                if model.sessions.isEmpty && !model.busy && model.error == nil {
                    VStack(spacing: 12) {
                        TokiSprite(pose: "Languages").frame(height: 144)
                        Text("Every language starts here").font(.headline)
                        Text("Translation sessions will appear when Glossia translates your project.")
                            .font(.callout).foregroundStyle(tokens.muted).multilineTextAlignment(.center)
                    }.frame(maxWidth: .infinity).padding(.vertical, 24)
                        .listRowBackground(Color.clear)
                }
                ForEach(model.sessions.indices, id: \.self) { index in
                    let row = model.sessions[index]
                    Button { if let id = row["id"] as? String { open?(id) } } label: {
                      VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(row["commit_message"] as? String ?? "Translation session").font(.headline)
                            Spacer()
                            Text(row["status"] as? String ?? "").font(.caption).foregroundStyle(tokens.muted)
                        }
                        Text("\(row["source_language"] as? String ?? "Source") → \((row["target_languages"] as? [String] ?? []).joined(separator: ", "))")
                            .font(.subheadline).foregroundStyle(tokens.muted)
                        if let summary = row["summary"] as? String, !summary.isEmpty {
                            Text(summary).font(.callout).textSelection(.enabled)
                        }
                        Text("\(row["translated_content_count"] as? Int ?? 0) items translated")
                            .font(.caption).foregroundStyle(tokens.muted)
                      }.padding(.vertical, 8).foregroundStyle(tokens.ink)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("translation-\(row["id"] as? String ?? "")")
                }.listRowBackground(tokens.surface)
                if model.hasMore { Button("Load more") { Task { await model.load() } }.disabled(model.busy) }
            }
        }
        .scrollContentBackground(.hidden).background(tokens.canvas)
        .task { if hasProject && model.sessions.isEmpty { await model.load(reset: true) } }
        .refreshable { if hasProject { await model.load(reset: true) } }
    }
}

@MainActor
final class TranslationDetailModel: ObservableObject {
    @Published private(set) var record: [String: Any]?
    @Published private(set) var busy = false
    @Published private(set) var error: String?
    let id: String
    private let request: GlossiaRequest

    init(id: String, request: @escaping GlossiaRequest) { self.id = id; self.request = request }

    func load() async {
        guard !busy else { return }
        busy = true; error = nil
        defer { busy = false }
        do {
            let value = try await request(["operation": "translation", "id": id])
            try Task.checkCancellation()
            guard let record = value["session"] as? [String: Any], record["id"] as? String == id else {
                throw GlossiaFailure(kind: "invalid_response", message: "Glossia returned a different translation.")
            }
            self.record = record
        } catch is CancellationError { }
        catch {
            if let failure = error as? GlossiaFailure, ["forbidden", "not_found", "invalid_response"].contains(failure.kind) { record = nil }
            self.error = error.localizedDescription
        }
    }
}

struct TranslationDetailView: View {
    @StateObject private var model: TranslationDetailModel
    @Environment(\.glossiaTokens) private var tokens
    let destination: GlossiaDestination
    let discuss: () -> Void

    init(destination: GlossiaDestination, request: @escaping GlossiaRequest, discuss: @escaping () -> Void) {
        self.destination = destination
        self.discuss = discuss
        _model = StateObject(wrappedValue: TranslationDetailModel(id: destination.id!, request: request))
    }

    var body: some View {
        List {
            if model.busy { ProgressView("Opening translation…") }
            if let error = model.error { GlossiaErrorView(message: error) { Task { await model.load() } } }
            if let record = model.record {
                Section {
                    Text(record["commit_message"] as? String ?? "Translation session").font(.title2.weight(.medium))
                    LabeledContent("Status", value: record["status"] as? String ?? "Unknown")
                    LabeledContent("Source language", value: record["source_language"] as? String ?? "Not available")
                    LabeledContent("Target languages", value: (record["target_languages"] as? [String] ?? []).joined(separator: ", "))
                    LabeledContent("Translated items", value: String(record["translated_content_count"] as? Int ?? 0))
                }.listRowBackground(tokens.surface)
                if let summary = record["summary"] as? String, !summary.isEmpty {
                    Section("Summary") { Text(summary).textSelection(.enabled) }.listRowBackground(tokens.surface)
                }
                if let commit = record["commit_sha"] as? String, !commit.isEmpty {
                    Section("Commit") { Text(commit).font(.footnote.monospaced()).textSelection(.enabled) }.listRowBackground(tokens.surface)
                }
                Section {
                    Button(action: discuss) { Label("Discuss with Toki", systemImage: "bubble.left.and.bubble.right") }
                        .accessibilityIdentifier("discuss-translation")
                    if let url = destination.url { ShareLink(item: url) { Label("Share translation link", systemImage: "square.and.arrow.up") } }
                } footer: {
                    Text("Start a private conversation linked to this translation. No changes are applied automatically.")
                }.listRowBackground(tokens.surface)
            }
        }
        .scrollContentBackground(.hidden).background(tokens.canvas)
        .navigationTitle("Translation").navigationBarTitleDisplayMode(.inline)
        .task { await model.load() }
        .refreshable { await model.load() }
    }
}
