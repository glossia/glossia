import Combine
import SwiftUI

@MainActor
final class TokiModel: ObservableObject {
    @Published var conversations: [[String: Any]] = []
    @Published var selectedID: String? {
        didSet { if oldValue != selectedID { acceptedTurnID = nil; workState = nil } }
    }
    @Published var detail: [String: Any]? { didSet { observeWork() } }
    @Published private(set) var workState: TokiActivityAttributes.ContentState?
    @Published var drafts: [String: String] = [:]
    @Published var pending: [String: PendingMessage] = [:]
    @Published var busy = false
    @Published var detailBusy = false
    @Published var sending = false
    @Published var error: String?
    @Published var detailError: String?
    @Published var hasMore = false
    @Published var source: [String: Any]?
    @Published var sourceError: String?
    private var page = 0
    private var detailRevision = 0
    private var authorizationRevision = 0
    private var localConversations: Set<String> = []
    private var origins: [String: String] = [:]
    private let request: GlossiaRequest
    private let work: TokiWorkController?
    private let workContext: String?
    private var subscriptions: Set<AnyCancellable> = []
    private var acceptedTurnID: String?

    struct PendingMessage {
        let id: String
        let content: String
    }

    init(work: TokiWorkController? = nil, context: String? = nil, request: @escaping GlossiaRequest) {
        self.request = request; self.work = work; self.workContext = context
        work?.$snapshots.sink { [weak self] snapshots in
            guard let self, let id = self.selectedID, let snapshot = snapshots[id] else { return }
            self.workState = snapshot.state
        }.store(in: &subscriptions)
        work?.updates.sink { [weak self] id, value in
            guard let self, self.selectedID == id, value.isEmpty || !self.sending else { return }
            self.detailRevision += 1; self.detailBusy = false
            if value.isEmpty {
                self.authorizationRevision += 1
                self.acceptedTurnID = nil
                self.detail = nil; self.drafts[id] = nil; self.pending[id] = nil
                self.source = nil; self.sourceError = nil
                self.conversations.removeAll { $0["id"] as? String == id }
                self.detailError = "This conversation is no longer available."
            } else {
                self.detail = value; self.detailError = nil
            }
        }.store(in: &subscriptions)
    }

    private func observeWork() {
        guard let id = selectedID, detail != nil, let phase = TokiWorkPhase(rawValue: status) else {
            workState = nil
            return
        }
        if let workContext, let snapshot = work?.snapshot(id, context: workContext) {
            workState = snapshot.state
            return
        }
        // A history record's default "completed" status isn't a completed turn.
        guard phase.active || phase == .failed || workState != nil || acceptedTurnID != nil else {
            workState = nil
            return
        }
        let date = Date()
        let previous = workState
        workState = TokiActivityAttributes.ContentState(
            phase: phase, observedAt: date,
            startedAt: previous?.startedAt ?? date,
            endedAt: phase.active ? nil : date)
    }

    var draft: String {
        get { selectedID.flatMap { drafts[$0] } ?? "" }
        set { if let selectedID { drafts[selectedID] = newValue } }
    }
    var messages: [[String: Any]] { detail?["messages"] as? [[String: Any]] ?? [] }
    var status: String { (detail?["conversation"] as? [String: Any])?["status"] as? String ?? "" }
    var thinking: Bool { ["queued", "running"].contains(status) }
    var sourceID: String? { (detail?["conversation"] as? [String: Any])?["translation_session_id"] as? String }
    var hasProtectedWork: Bool {
        sending || !pending.isEmpty || drafts.values.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    // Composing or opening a link prepares a local draft. Only Send creates the
    // server conversation, and its source and UUID survive an ambiguous failure.
    func prepare(translationID: String?) async {
        let id = UUID().uuidString.lowercased()
        localConversations.insert(id)
        origins[id] = translationID
        conversations.insert(["id": id, "title": "Draft conversation", "status": "draft"], at: 0)
        detailRevision += 1; detailBusy = false
        selectedID = id; detailError = nil; source = nil; sourceError = nil
        detail = ["conversation": ["id": id, "status": "draft", "translation_session_id": translationID as Any? ?? NSNull()], "messages": []]
        await loadSource()
    }

    func discardDrafts() {
        guard !sending, !busy else { return }
        drafts = [:]; pending = [:]
        if let id = selectedID, localConversations.contains(id) {
            selectedID = nil; detail = nil; source = nil; sourceError = nil
        }
        conversations.removeAll { localConversations.contains($0["id"] as? String ?? "") }
        localConversations = []; origins = [:]
    }

    func load(reset: Bool = false) async {
        guard !busy else { return }
        busy = true; error = nil
        defer { busy = false }
        let next = reset ? 1 : page + 1
        do {
            let result = try await request(["operation": "resource", "resource": "conversations", "page": next])
            try Task.checkCancellation()
            if reset { conversations.removeAll { !localConversations.contains($0["id"] as? String ?? "") } }
            let ids = Set(conversations.compactMap { $0["id"] as? String })
            conversations += (result["conversations"] as? [[String: Any]] ?? []).filter { !ids.contains($0["id"] as? String ?? "") }
            hasMore = (result["meta"] as? [String: Any])?["has_next_page?"] as? Bool ?? false
            page = next
        } catch is CancellationError { }
        catch { self.error = error.localizedDescription }
    }

    func close() {
        if let id = selectedID, localConversations.contains(id), pending[id] == nil,
           (drafts[id] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            conversations.removeAll { $0["id"] as? String == id }
            localConversations.remove(id); origins[id] = nil; drafts[id] = nil
        }
        detailRevision += 1; detailBusy = false
        selectedID = nil; detail = nil; detailError = nil; source = nil; sourceError = nil
    }

    func open(_ id: String) async {
        guard !sending else { return }
        selectedID = id; detail = nil; detailError = nil; detailBusy = false; source = nil; sourceError = nil
        if localConversations.contains(id) {
            detail = ["conversation": ["id": id, "status": "draft", "translation_session_id": origins[id] as Any? ?? NSNull()], "messages": []]
            await loadSource()
            return
        }
        await refreshDetail()
    }

    func refreshDetail() async {
        guard let id = selectedID, !detailBusy, !sending else { return }
        detailRevision += 1
        let ticket = detailRevision
        detailBusy = true
        defer { if ticket == detailRevision { detailBusy = false } }
        do {
            let value = try await request(["operation": "conversation", "action": "show", "id": id])
            try Task.checkCancellation()
            guard selectedID == id, ticket == detailRevision else { return }
            if let workContext { work?.observe(value, id: id, context: workContext, allowNewTurn: true) }
            detail = value; detailError = nil
            await loadSource()
        } catch is CancellationError { }
        catch {
            guard selectedID == id, ticket == detailRevision else { return }
            invalidateHistory(id, for: error)
            detailError = error.localizedDescription
        }
    }

    func send() async {
        guard let id = selectedID, !sending, !detailBusy, !thinking, detail != nil else { return }
        let content = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard pending[id] != nil || (!content.isEmpty && content.unicodeScalars.count <= 4000) else { return }
        let message = pending[id] ?? PendingMessage(id: UUID().uuidString.lowercased(), content: content)
        let authorization = authorizationRevision
        pending[id] = message
        sending = true; detailError = nil
        defer { sending = false }
        do {
            if localConversations.contains(id) {
                var create: [String: Any] = ["operation": "conversation", "action": "create", "id": id]
                if let origin = origins[id] { create["translation_session_id"] = origin }
                _ = try await request(create)
                try Task.checkCancellation()
                guard selectedID == id, authorization == authorizationRevision else { return }
                localConversations.remove(id)
            }
            let result = try await request(["operation": "conversation", "action": "send", "id": id,
                                            "message_id": message.id, "content": message.content])
            try Task.checkCancellation()
            guard selectedID == id, authorization == authorizationRevision else { return }
            acceptedTurnID = message.id
            workState = nil
            if let workContext { work?.observe(result, id: id, context: workContext, sentMessageID: message.id) }
            detail = result; drafts[id] = nil; pending[id] = nil
            if let conversation = result["conversation"] as? [String: Any] {
                if let index = conversations.firstIndex(where: { $0["id"] as? String == id }) {
                    conversations[index] = conversation
                } else { conversations.insert(conversation, at: 0) }
            }
        } catch is CancellationError { }
        catch {
            if selectedID == id, authorization == authorizationRevision {
                invalidateHistory(id, for: error)
                detailError = error.localizedDescription
            }
        }
    }

    private func invalidateHistory(_ id: String, for error: Error) {
        if let failure = error as? GlossiaFailure, ["forbidden", "not_found"].contains(failure.kind) {
            authorizationRevision += 1
            acceptedTurnID = nil
            if let workContext { work?.remove(id, context: workContext) }
            detail = nil; drafts[id] = nil; pending[id] = nil; source = nil; sourceError = nil
            localConversations.remove(id)
            conversations.removeAll { $0["id"] as? String == id }
        }
    }

    func loadSource() async {
        guard let id = sourceID, source?["id"] as? String != id else { return }
        do {
            let result = try await request(["operation": "translation", "id": id])
            try Task.checkCancellation()
            guard sourceID == id else { return }
            guard let record = result["session"] as? [String: Any], record["id"] as? String == id else {
                throw GlossiaFailure(kind: "invalid_response", message: "Glossia returned a different translation.")
            }
            source = record; sourceError = nil
        } catch is CancellationError { }
        catch { if sourceID == id { source = nil; sourceError = error.localizedDescription } }
    }

    func poll() async {
        // The app-owned controller continues tracking after this view closes.
        guard work == nil else { return }
        while !Task.isCancelled {
            do { try await Task.sleep(for: .seconds(2)) }
            catch { return }
            if thinking && !sending { await refreshDetail() }
        }
    }
}

struct TokiView: View {
    @StateObject private var model: TokiModel
    @Environment(\.glossiaTokens) private var tokens
    @Environment(\.glossiaNavigation) private var navigation
    @State private var protection = UUID()
    @State private var discarding = false
    @State private var appliedRevision: UUID?
    let hasProject: Bool
    let destination: GlossiaDestination?
    let revision: UUID?
    let openSource: ((String) -> Void)?
    private let work: TokiWorkController?

    init(request: @escaping GlossiaRequest, hasProject: Bool, destination: GlossiaDestination? = nil,
         revision: UUID? = nil, work: TokiWorkController? = nil, context: String? = nil,
         openSource: ((String) -> Void)? = nil) {
        _model = StateObject(wrappedValue: TokiModel(work: work, context: context, request: request))
        self.hasProject = hasProject
        self.destination = destination
        self.revision = revision
        self.openSource = openSource
        self.work = work
    }

    var body: some View {
        List {
            if hasProject {
                if let work {
                    TokiWorkOverview(work: work) { id in Task { await model.open(id) } }
                        .listRowBackground(tokens.surface)
                }
                if let error = model.error {
                    GlossiaErrorView(message: error) { Task { await model.load(reset: true) } }
                }
                if model.busy { ProgressView("Opening conversations…") }
                ForEach(model.conversations.indices, id: \.self) { index in
                    let row = model.conversations[index]
                    Button { if let id = row["id"] as? String { Task { await model.open(id) } } } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "bubble.left").foregroundStyle(tokens.tint)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(row["title"] as? String ?? "New conversation").foregroundStyle(tokens.ink)
                                if let date = row["updated_at"] as? String,
                                   let value = ISO8601DateFormatter().date(from: date) {
                                    Text(value, style: .date).font(.caption).foregroundStyle(tokens.muted)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(tokens.muted)
                        }.padding(.vertical, 8)
                    }
                    .accessibilityIdentifier("conversation-\(row["id"] as? String ?? "")")
                }.listRowBackground(tokens.surface)
                if model.hasMore { Button("Load more") { Task { await model.load() } }.disabled(model.busy) }
            }
        }
        .scrollContentBackground(.hidden).background(tokens.canvas)
        .overlay {
            if !hasProject {
                ContentUnavailableView("Choose a project", systemImage: "folder",
                                       description: Text("Toki can help you explore your project's languages and translations."))
            } else if model.conversations.isEmpty && !model.busy && model.error == nil {
                ContentUnavailableView("No conversations yet", systemImage: "bubble.left.and.bubble.right",
                                       description: Text("Tap the compose button to start a private conversation about this project."))
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if model.selectedID == nil {
                    Button { Task { await model.prepare(translationID: nil) } } label: { Label("New conversation", systemImage: "square.and.pencil") }
                        .disabled(!hasProject || model.busy)
                        .accessibilityIdentifier("new-conversation")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if model.selectedID == nil && model.hasProtectedWork {
                    Button { discarding = true } label: { Label("Discard unsent drafts", systemImage: "trash") }
                        .disabled(model.sending || model.busy)
                }
            }
        }
        .confirmationDialog("Discard unsent drafts?", isPresented: $discarding) {
            Button("Discard drafts", role: .destructive) { model.discardDrafts() }
        } message: { Text("This clears local drafts and pending retries. Messages already accepted by the server are not deleted.") }
        .onAppear { navigation?.protect(protection) { [weak model] in model?.hasProtectedWork ?? false } }
        .task { if hasProject && model.conversations.isEmpty { await model.load(reset: true) } }
        .task(id: revision) {
            guard let revision, revision != appliedRevision, let destination else { return }
            appliedRevision = revision
            switch destination.screen {
            case .conversation: if let id = destination.id { await model.open(id) }
            case .newConversation: await model.prepare(translationID: destination.translationID)
            case .toki: model.close()
            default: break
            }
        }
        .refreshable { if hasProject { await model.load(reset: true) } }
        .navigationDestination(isPresented: Binding(get: { model.selectedID != nil }, set: { if !$0 { model.close() } })) {
            TokiConversationView(model: model, openSource: openSource)
        }
    }
}

struct TokiConversationView: View {
    @ObservedObject var model: TokiModel
    @Environment(\.glossiaTokens) private var tokens
    @Environment(\.scenePhase) private var scenePhase
    var openSource: ((String) -> Void)?

    var body: some View {
        ScrollViewReader { scroll in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if let id = model.sourceID {
                        Button { openSource?(id) } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "character.bubble")
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Translation context").font(.caption).foregroundStyle(tokens.muted)
                                    Text(model.source?["commit_message"] as? String ?? "View source translation").font(.subheadline)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption)
                            }.padding(16).background(tokens.surface, in: RoundedRectangle(cornerRadius: tokens.radius))
                        }
                        .buttonStyle(.plain).disabled(openSource == nil)
                        .accessibilityIdentifier("toki-translation-source")
                        if let error = model.sourceError {
                            GlossiaErrorView(message: error) { Task { await model.loadSource() } }
                        }
                    }
                    if model.detailBusy && model.detail == nil { ProgressView("Opening conversation…") }
                    if model.messages.isEmpty && model.detail != nil {
                        VStack(spacing: 12) {
                            TokiSprite(pose: "Curious", interactive: true).frame(height: 192)
                            Text("Tap Toki to say hello").font(.caption).foregroundStyle(tokens.muted)
                            Text("What shall we explore?").font(.title2.weight(.medium))
                            Text("Ask about this project's languages or recent translations. Replies use your organization's configured AI provider.")
                                .font(.callout).foregroundStyle(tokens.muted).multilineTextAlignment(.center)
                            ForEach(["Which languages does this project support?", "Summarize my recent translations", "Help me plan our next language"], id: \.self) { suggestion in
                                Button(suggestion) { model.draft = suggestion }
                                    .buttonStyle(.bordered).disabled(model.sending)
                            }
                        }.frame(maxWidth: .infinity).padding(.vertical, 24)
                    }
                    ForEach(model.messages.indices, id: \.self) { index in
                        let message = model.messages[index]
                        let outgoing = message["role"] as? String == "user"
                        HStack(alignment: .top, spacing: 8) {
                            if outgoing { Spacer(minLength: 32) }
                            if !outgoing { TokiSprite(pose: "Wave").frame(width: 36, height: 36) }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(outgoing ? "You" : "Toki").font(.caption.weight(.medium)).foregroundStyle(tokens.muted)
                                Text(message["content"] as? String ?? "").textSelection(.enabled)
                            }
                            .padding(16)
                            .background(outgoing ? tokens.accentSoft : tokens.surface,
                                        in: RoundedRectangle(cornerRadius: tokens.radius))
                            if !outgoing { Spacer(minLength: 24) }
                        }.id(message["id"] as? String ?? String(index))
                    }
                    if model.sending {
                        Label("Sending…", systemImage: "arrow.up.circle")
                            .font(.callout).foregroundStyle(tokens.muted)
                    } else if let state = model.workState {
                        TokiWorkStatusView(state: state) { Task { await model.refreshDetail() } }
                    }
                    if let error = model.detailError {
                        GlossiaErrorView(message: error) {
                            Task {
                                if let id = model.selectedID, model.pending[id] != nil { await model.send() }
                                else { await model.refreshDetail() }
                            }
                        }
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }.padding(GlossiaBrand.gutter)
            }
            .defaultScrollAnchor(model.messages.isEmpty ? .top : .bottom)
            .onChange(of: model.messages.count) { _, _ in scroll.scrollTo("bottom", anchor: .bottom) }
            .background(tokens.canvas)
            .safeAreaInset(edge: .bottom, spacing: 0) { composer }
        }
        .navigationTitle(model.status == "draft" ? "New conversation" : "Toki").navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .task(id: scenePhase) { if scenePhase == .active { await model.poll() } }
    }

    private var composer: some View {
        VStack(spacing: 4) {
            HStack(alignment: .bottom, spacing: 12) {
                TextField("Message Toki…", text: Binding(get: { model.draft }, set: { model.draft = $0 }),
                          prompt: Text("Message Toki…").foregroundStyle(tokens.muted), axis: .vertical)
                    .lineLimit(1...6).padding(12)
                    .background(tokens.subtle, in: RoundedRectangle(cornerRadius: tokens.radius))
                    .disabled(model.sending || model.selectedID.flatMap { model.pending[$0] } != nil || model.detail == nil)
                    .accessibilityIdentifier("toki-composer")
                Button { Task { await model.send() } } label: {
                    Image(systemName: "arrow.up").font(.headline).frame(width: 44, height: 44)
                }
                .buttonStyle(.borderedProminent).clipShape(Circle())
                .modifier(GlossiaPrimaryAction())
                .accessibilityLabel(model.selectedID.flatMap { model.pending[$0] } == nil ? "Send message" : "Retry message")
                .disabled(model.sending || model.thinking || model.detailBusy || model.detail == nil || model.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.draft.unicodeScalars.count > 4000)
            }
            if model.draft.unicodeScalars.count > 4000 { Text("Messages can contain up to 4,000 characters.").font(.caption).foregroundStyle(.red) }
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(tokens.surface)
    }
}
