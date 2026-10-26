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
            if hasProject {
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
                            Text(row["commit_message"] as? String ?? String(localized: "Translation session")).font(.headline)
                            Spacer()
                            Text(translationStatus(row["status"] as? String ?? "")).font(.caption).foregroundStyle(tokens.muted)
                        }
                        Text("\(row["source_language"] as? String ?? String(localized: "Source")) → \((row["target_languages"] as? [String] ?? []).joined(separator: ", "))")
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
        .overlay {
            if !hasProject {
                ContentUnavailableView("Choose a project", systemImage: "folder",
                                       description: Text("Select a workspace to see its translations."))
            }
        }
        .task { if hasProject && model.sessions.isEmpty { await model.load(reset: true) } }
        .refreshable { if hasProject { await model.load(reset: true) } }
    }
}

@MainActor
final class TranslationDetailModel: ObservableObject {
    @Published private(set) var record: [String: Any]?
    @Published private(set) var progress: [String: Any]?
    @Published private(set) var busy = false
    @Published private(set) var error: String?
    @Published private(set) var liveState = "connecting"
    let id: String
    private let request: GlossiaRequest
    private var active = false
    private var generation = 0
    private var sequence: UInt64 = 0
    private var snapshotRevision = 0
    private var loadRevision = UUID()
    private var connection: String?
    private var worker: Task<Void, Never>?

    init(id: String, request: @escaping GlossiaRequest) { self.id = id; self.request = request }

    var showsLiveConnection: Bool {
        ["pending", "running"].contains(record?["status"] as? String ?? "") && liveState != "live"
    }

    func load() async {
        guard !busy else { return }
        let ticket = generation, revision = snapshotRevision
        let loadID = UUID()
        loadRevision = loadID
        busy = true; error = nil
        defer { if loadRevision == loadID { busy = false } }
        do {
            let value = try await request(["operation": "translation", "id": id])
            try Task.checkCancellation()
            guard ticket == generation, revision == snapshotRevision else { return }
            try accept(value)
        } catch is CancellationError { }
        catch {
            guard ticket == generation, revision == snapshotRevision else { return }
            if denied(error) { record = nil; progress = nil; setActive(false) }
            self.error = error.localizedDescription
        }
    }

    func setActive(_ value: Bool) {
        guard active != value || (value && worker == nil) else { return }
        active = value; generation += 1
        loadRevision = UUID(); busy = false
        worker?.cancel(); worker = nil
        if let connection { close(connection); self.connection = nil }
        if value {
            let ticket = generation
            worker = Task { await observe(ticket: ticket) }
        }
    }

    private func observe(ticket: Int) async {
        defer {
            if generation == ticket {
                worker = nil
                if let connection { close(connection); self.connection = nil }
            }
        }
        await load()
        var mayRefreshSession = true
        while current(ticket) {
            do {
                liveState = "connecting"
                let opened = try await request(["operation": "translation_live", "action": "open", "id": id])
                guard let handle = opened["connection"] as? String else {
                    throw GlossiaFailure(kind: "invalid_response", message: String(localized: "Could not open live translation progress."))
                }
                guard current(ticket) else { close(handle); return }
                connection = handle
                sequence = 0
                while current(ticket) {
                    let update = try await request(["operation": "translation_live", "action": "next",
                                                    "connection": handle, "after": sequence])
                    guard current(ticket) else { return }
                    sequence = (update["sequence"] as? NSNumber)?.uint64Value ?? sequence
                    liveState = update["state"] as? String ?? "reconnecting"
                    switch liveState {
                    case "live":
                        if let snapshot = update["snapshot"] as? [String: Any] { try accept(snapshot) }
                        error = nil; mayRefreshSession = true
                    case "needs_session":
                        close(handle); connection = nil
                        guard mayRefreshSession else {
                            snapshotRevision += 1
                            record = nil; progress = nil
                            error = String(localized: "Your session is no longer authorized. Sign in again.")
                            return
                        }
                        mayRefreshSession = false
                    case "unavailable":
                        snapshotRevision += 1
                        record = nil; progress = nil
                        error = update["error"] as? String == "not_found"
                            ? String(localized: "This translation is no longer available.")
                            : String(localized: "You no longer have access to this translation.")
                        close(handle); connection = nil
                        return
                    case "closed": return
                    default: break
                    }
                    if connection == nil { break }
                }
            } catch is CancellationError { return }
            catch {
                guard current(ticket) else { return }
                if let connection { close(connection); self.connection = nil }
                if denied(error) {
                    snapshotRevision += 1
                    record = nil; progress = nil
                    self.error = error.localizedDescription
                    liveState = "unavailable"
                    return
                }
                liveState = "reconnecting"
                do { try await Task.sleep(for: .seconds(3)) } catch { return }
            }
        }
    }

    private func current(_ ticket: Int) -> Bool { active && generation == ticket && !Task.isCancelled }

    private func accept(_ value: [String: Any]) throws {
        guard let record = value["session"] as? [String: Any], record["id"] as? String == id else {
            throw GlossiaFailure(kind: "invalid_response", message: String(localized: "Glossia returned a different translation."))
        }
        snapshotRevision += 1
        self.record = record
        progress = value["progress"] as? [String: Any]
    }

    private func denied(_ error: Error) -> Bool {
        guard let failure = error as? GlossiaFailure else { return false }
        return ["forbidden", "not_found", "sign_in_required", "invalid_response"].contains(failure.kind)
    }

    private func close(_ handle: String) {
        let request = request
        Task { _ = try? await request(["operation": "translation_live", "action": "close", "connection": handle]) }
    }
}

private func translationStatus(_ status: String) -> String {
    switch status {
    case "awaiting_input": String(localized: "Awaiting linguistic input")
    case "pending": String(localized: "Pending")
    case "running": String(localized: "Running")
    case "completed": String(localized: "Completed")
    case "done": String(localized: "Translated")
    case "queued": String(localized: "Queued")
    case "skipped": String(localized: "Already up to date")
    case "failed": String(localized: "Failed")
    case "cancelled": String(localized: "Cancelled")
    default: String(localized: "Unknown status")
    }
}

struct ReviewDraft {
    var answer = ""
    var reusable = false
    var guidance = ""
    var scope = "locale"
    var valid: Bool {
        !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && answer.unicodeScalars.count <= 8000 &&
        (!reusable || (!guidance.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && guidance.unicodeScalars.count <= 8000))
    }
}

@MainActor
final class TranslationReviewsModel: ObservableObject {
    @Published private(set) var reviews: [[String: Any]] = []
    @Published private(set) var busy = false
    @Published private(set) var loaded = false
    @Published private(set) var error: String?
    private var generation = 0
    private let id: String
    private let request: GlossiaRequest

    init(id: String, request: @escaping GlossiaRequest) { self.id = id; self.request = request }

    var allAnswered: Bool {
        loaded && reviews.contains { $0["status"] as? String == "answered" } && !reviews.contains { $0["status"] as? String == "open" }
    }

    func invalidate(clear: Bool = false) {
        generation += 1; busy = false
        if clear { reviews = []; loaded = false }
    }

    func load() async {
        guard !busy else { return }
        let ticket = generation
        busy = true; error = nil
        defer { if ticket == generation { busy = false } }
        do {
            let value = try await request(["operation": "translation_reviews", "action": "list", "id": id])
            try Task.checkCancellation()
            guard ticket == generation else { return }
            guard let rows = value["reviews"] as? [[String: Any]], rows.allSatisfy(valid) else { throw invalid() }
            reviews = rows; loaded = true
        } catch is CancellationError { }
        catch {
            guard ticket == generation else { return }
            if let failure = error as? GlossiaFailure, ["forbidden", "not_found", "sign_in_required"].contains(failure.kind) {
                invalidate(clear: true)
                self.error = String(localized: "You do not have permission to view linguistic reviews.")
            } else { self.error = error.localizedDescription }
        }
    }

    private func valid(_ row: [String: Any]) -> Bool {
        row["translation_session_id"] as? String == id && row["id"] as? String != nil &&
            ["open", "answered", "stale"].contains(row["status"] as? String ?? "")
    }
    private func invalid() -> GlossiaFailure { GlossiaFailure(kind: "invalid_response", message: String(localized: "Glossia returned an invalid linguistic review.")) }
}

struct TranslationDetailView: View {
    @StateObject private var model: TranslationDetailModel
    @StateObject private var reviews: TranslationReviewsModel
    @Environment(\.glossiaTokens) private var tokens
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.glossiaNavigation) private var navigation
    @State private var protection = UUID()
    @State private var visible = false
    let destination: GlossiaDestination
    let openResumed: (String) -> Void
    let openReview: (String) -> Void
    let discuss: () -> Void

    init(destination: GlossiaDestination, request: @escaping GlossiaRequest, reviewsModel: TranslationReviewsModel? = nil,
         openResumed: @escaping (String) -> Void = { _ in }, openReview: @escaping (String) -> Void = { _ in }, discuss: @escaping () -> Void) {
        self.destination = destination
        self.openResumed = openResumed
        self.openReview = openReview
        self.discuss = discuss
        _model = StateObject(wrappedValue: TranslationDetailModel(id: destination.id!, request: request))
        _reviews = StateObject(wrappedValue: reviewsModel ?? TranslationReviewsModel(id: destination.id!, request: request))
    }

    var body: some View {
        List {
            if model.busy { ProgressView("Opening translation…") }
            if let error = model.error {
                GlossiaErrorView(message: error) { Task { await refresh() } }
            }
            if let record = model.record {
                Section {
                    Text(record["commit_message"] as? String ?? String(localized: "Translation session")).font(.title2.weight(.medium))
                    LabeledContent("Status", value: record["status"] as? String == "awaiting_input" && reviews.allAnswered
                        ? String(localized: "Linguistic input answered") : translationStatus(record["status"] as? String ?? "Unknown"))
                        .accessibilityIdentifier("translation-status")
                }.listRowBackground(tokens.surface)
                reviewSections
                if let progress = model.progress { progressSection(progress, status: record["status"] as? String ?? "") }
                if model.showsLiveConnection {
                    Label(model.liveState == "connecting" ? String(localized: "Connecting to live progress…") : String(localized: "Reconnecting to live progress…"),
                          systemImage: "antenna.radiowaves.left.and.right")
                        .font(.caption).foregroundStyle(tokens.muted).listRowBackground(Color.clear)
                }
                Section("Languages") {
                    LabeledContent("Source language", value: record["source_language"] as? String ?? String(localized: "Not available"))
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
        .onAppear {
            visible = true; model.setActive(scenePhase == .active)
        }
        .task { await reviews.load() }
        .onChange(of: scenePhase) { _, phase in
            model.setActive(visible && phase == .active)
            if visible && phase == .active { Task { await reviews.load() } }
            else { reviews.invalidate() }
        }
        .onChange(of: model.record?["status"] as? String) { _, status in
            if status == "awaiting_input" { Task { await reviews.load() } }
        }
        .onChange(of: model.error) { _, _ in
            if model.record == nil && model.error != nil { reviews.invalidate(clear: true) }
        }
        .onDisappear { visible = false; model.setActive(false); reviews.invalidate() }
        .refreshable { await refresh() }
    }

    private func refresh() async {
        await model.load()
        if model.record != nil { await reviews.load() }
        if visible && scenePhase == .active { model.setActive(true) }
    }

    @ViewBuilder private var reviewSections: some View {
        Section {
            if reviews.busy { ProgressView("Loading linguistic reviews…") }
            if let error = reviews.error { GlossiaErrorView(message: error) { Task { await reviews.load() } } }
            if reviews.loaded && !reviews.busy && reviews.error == nil && reviews.reviews.isEmpty { Text("No linguistic questions for this translation.").foregroundStyle(tokens.muted) }
            Button("Refresh reviews") { Task { await reviews.load() } }.disabled(reviews.busy)
        } header: { Text("Linguistic review") }
          .listRowBackground(tokens.surface)
        ForEach(reviews.reviews.indices, id: \.self) { index in
            let row = reviews.reviews[index]
            let status = row["status"] as? String ?? "stale"
            Section {
                Text(row["question"] as? String ?? String(localized: "Linguistic question")).font(.headline).textSelection(.enabled)
                Text("\u{2068}\(row["locale"] as? String ?? String(localized: "Unknown locale"))\u{2069} · \(status == "answered" ? String(localized: "Goal resolved") : status == "open" ? String(localized: "Open goal") : String(localized: "No longer current"))")
                    .font(.subheadline).foregroundStyle(tokens.muted)
                Text("\u{2066}\(row["source_path"] as? String ?? "") → \(row["output_path"] as? String ?? "")\u{2069}").font(.caption.monospaced())
                    .environment(\.layoutDirection, .leftToRight)
                if let conversation = row["conversation_id"] as? String, UUID(uuidString: conversation) != nil {
                    Button("Open shared Toki conversation") { openReview(conversation) }.accessibilityIdentifier("review-conversation")
                } else {
                    Text("Shared conversation unavailable. Refresh reviews to retry.").font(.caption).foregroundStyle(tokens.muted)
                }
            }.listRowBackground(tokens.surface)
        }
        Section {
            Text("Discuss each goal with Toki in its project-shared conversation, then explicitly save the agreed decision to resume affected work in a new translation.")
                .font(.caption).foregroundStyle(tokens.muted)
        }.listRowBackground(Color.clear)
    }

    private func excerpt(_ title: String, path: String?, text: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(tokens.muted)
            if let path { Text(path).font(.caption.monospaced()).foregroundStyle(tokens.muted).textSelection(.enabled) }
            Text(text ?? "No excerpt provided").font(.callout.monospaced()).textSelection(.enabled)
        }.padding(.vertical, 4)
    }

    @ViewBuilder
    private func progressSection(_ progress: [String: Any], status: String) -> some View {
        if let summary = progress["summary"] as? [String: Any] {
            let total = summary["needs_translation"] as? Int ?? 0
            let done = summary["done"] as? Int ?? 0
            let failed = summary["failed"] as? Int ?? 0
            let cancelled = summary["cancelled"] as? Int ?? 0
            let assessed = summary["assessed?"] as? Bool ?? false
            Section("Progress") {
                VStack(alignment: .leading, spacing: 12) {
                    if assessed && total > 0 {
                        ProgressView(value: Double(done + failed + cancelled), total: Double(total))
                            .tint(tokens.accent)
                        Text("\(done) of \(total) files translated").font(.headline)
                    } else if assessed {
                        Text("All files are up to date").font(.headline)
                    } else if status == "awaiting_input" {
                        Label(reviews.allAnswered ? String(localized: "Historical run · linguistic input answered") : String(localized: "Waiting for linguistic input"), systemImage: "questionmark.bubble")
                    } else if ["pending", "running"].contains(status) {
                        ProgressView("Planning translations…")
                        Text("\(summary["checked"] as? Int ?? 0) of \(summary["total"] as? Int ?? 0) files checked")
                            .font(.callout).foregroundStyle(tokens.muted)
                    } else {
                        Text("No file progress was recorded for this run.").foregroundStyle(tokens.muted)
                    }
                    if failed > 0 { Text("\(failed) failed").foregroundStyle(tokens.muted) }
                    if cancelled > 0 { Text("\(cancelled) cancelled").foregroundStyle(tokens.muted) }
                    if let waiting = summary["awaiting_input"] as? Int, waiting > 0 {
                        Text("\(waiting) awaiting linguistic input").foregroundStyle(tokens.muted)
                    }
                    if let skipped = summary["skipped"] as? Int, skipped > 0 {
                        Text("\(skipped) already up to date").font(.caption).foregroundStyle(tokens.muted)
                    }
                }.padding(.vertical, 8)
                    .accessibilityIdentifier("translation-progress")
                if let items = progress["items"] as? [[String: Any]] {
                    ForEach(items.indices, id: \.self) { index in
                        let item = items[index]
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: item["status"] as? String == "done" ? "checkmark.circle" : "doc.text")
                                .foregroundStyle(tokens.tint)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item["output_path"] as? String ?? String(localized: "Translation file")).font(.callout).lineLimit(2)
                                Text([item["locale"] as? String, (item["status"] as? String).map(translationStatus)].compactMap { $0 }.joined(separator: " · "))
                                    .font(.caption).foregroundStyle(tokens.muted)
                            }
                        }.padding(.vertical, 4)
                    }
                }
                if let omitted = progress["omitted_items"] as? Int, omitted > 0 {
                    Text("\(omitted) more files").font(.caption).foregroundStyle(tokens.muted)
                }
            }.listRowBackground(tokens.surface)
        }
    }
}
