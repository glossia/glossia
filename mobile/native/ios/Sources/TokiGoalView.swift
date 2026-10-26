import SwiftUI

struct TokiGoalView: View {
    @ObservedObject var model: TokiModel
    var openTranslation: ((String) -> Void)?
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let goal = model.goal {
                let language = goal["locale"] as? String ?? ""
                HStack(alignment: .firstTextBaseline) {
                    Label {
                        Text(verbatim: locale.localizedString(forIdentifier: language) ?? language)
                    } icon: { Image(systemName: "globe") }
                    Spacer(minLength: 8)
                    switch goal["status"] as? String {
                    case "answered": Label("Resolved", systemImage: "checkmark.circle.fill")
                    case "stale": Label("No longer current", systemImage: "clock")
                    default: Label("Needs input", systemImage: "bubble.left.and.bubble.right")
                    }
                }.font(.subheadline).foregroundStyle(.secondary)
                DisclosureGroup("Context") {
                    VStack(alignment: .leading, spacing: 12) {
                        if let participants = goal["participants"] as? [[String: Any]], !participants.isEmpty {
                            Label {
                                Text(verbatim: participants.compactMap { $0["name"] as? String }
                                    .map { "\u{2068}\($0)\u{2069}" }.joined(separator: ", "))
                            } icon: { Image(systemName: "person.2") }
                            .font(.subheadline)
                        }
                        Text("Visible to project members · one shared conversation.")
                            .font(.caption).foregroundStyle(.secondary)
                        ForEach(["source", "translation"], id: \.self) { kind in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(kind == "source" ? String(localized: "Source") : String(localized: "Translation"))
                                    .font(.subheadline.weight(.medium))
                                Text(verbatim: "\u{2066}\(goal[kind == "source" ? "source_path" : "output_path"] as? String ?? "")\u{2069}")
                                    .font(.caption.monospaced()).foregroundStyle(.secondary)
                                    .environment(\.layoutDirection, .leftToRight)
                                Text(verbatim: String((goal["\(kind)_excerpt"] as? String ?? String(localized: "No excerpt")).prefix(1200)))
                                    .font(.callout).textSelection(.enabled)
                            }
                        }
                        if let source = goal["translation_session_id"] as? String, openTranslation != nil {
                            Button("View source translation") { openTranslation?(source) }
                        }
                    }.padding(.top, 8)
                }
                .accessibilityIdentifier("goal-context")
                if goal["status"] as? String == "stale" {
                    Text("This goal is no longer current. Chat and resolution are read-only.")
                        .font(.callout).foregroundStyle(.secondary)
                }
                if model.goalClosed && !model.draft.isEmpty {
                    Text("Unsent message retained on this device").font(.headline)
                    Text(verbatim: model.draft).textSelection(.enabled)
                    Button("Discard unsent message", role: .destructive) { model.draft = "" }
                }
            } else {
                Text("Goal unavailable. Refresh the conversation to check access.")
                Button("Refresh goal and conversation") { Task { await model.refreshDetail() } }
                    .disabled(model.resolving || model.sending || model.detailBusy)
            }
        }
    }
}

struct TokiProposalView: View {
    @ObservedObject var model: TokiModel
    let review: () -> Void

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text(verbatim: model.decision?.answer ?? (model.completedReply?["content"] as? String ?? ""))
                    .textSelection(.enabled)
                Button(action: review) {
                    Label(model.decision == nil ? String(localized: "Review decision") : String(localized: "Continue reviewing"), systemImage: "square.and.pencil")
                }
                .buttonStyle(.bordered).disabled(model.decision == nil && !model.canResolve)
                .accessibilityIdentifier("goal-resolve")
                Text(model.decision == nil
                     ? String(localized: "Only a person can approve this decision.")
                     : String(localized: "Your unsaved decision draft is kept on this device."))
                    .font(.caption).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Label(model.decision == nil ? String(localized: "Proposed decision") : String(localized: "Decision draft"), systemImage: "text.bubble")
                .font(.subheadline.weight(.semibold))
        }
    }
}

struct TokiResolvedDecisionView: View {
    let goal: [String: Any]
    var openTranslation: ((String) -> Void)?

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                if let name = (goal["answered_by"] as? [String: Any])?["name"] as? String, !name.isEmpty {
                    Text("Approved by \(name)").font(.caption).foregroundStyle(.secondary)
                }
                Text(verbatim: goal["answer"] as? String ?? "").textSelection(.enabled)
                if let guidance = goal["guidance"] as? String, !guidance.isEmpty {
                    DisclosureGroup("Guidance proposed for PR review") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(verbatim: guidance).textSelection(.enabled)
                            if let path = goal["context_path"] as? String {
                                Text(verbatim: "\u{2066}\(path)\u{2069}")
                                    .font(.caption.monospaced()).foregroundStyle(.secondary)
                                    .environment(\.layoutDirection, .leftToRight)
                            }
                            Text("Guidance is not applied automatically. Review it in the translation PR.")
                                .font(.caption).foregroundStyle(.secondary)
                        }.padding(.top, 8)
                    }.font(.callout)
                }
                if let resumed = goal["resumed_session_id"] as? String {
                    Button("View translation") { openTranslation?(resumed) }
                        .buttonStyle(.bordered).disabled(openTranslation == nil)
                        .accessibilityIdentifier("goal-resumed")
                } else {
                    Text("Translation resumes after all open questions are resolved.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Label("Approved decision", systemImage: "checkmark.circle.fill")
                .font(.subheadline.weight(.semibold))
        }
    }
}

struct TokiDecisionView: View {
    @ObservedObject var model: TokiModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.glossiaTokens) private var tokens
    @State private var confirmingDiscard = false

    private func field<T>(_ key: WritableKeyPath<ReviewDraft, T>) -> Binding<T> {
        Binding(get: { (model.decision ?? ReviewDraft())[keyPath: key] }, set: { model.decision?[keyPath: key] = $0 })
    }

    var body: some View {
        NavigationStack {
            Form {
                if model.goalClosed {
                    Section("Goal closed") {
                        Text("Another participant may have resolved or superseded this goal. Your unsaved decision and guidance remain editable below for copying. They cannot be saved to this closed goal.")
                        if let saved = model.goal?["answer"] as? String { Text(saved).textSelection(.enabled) }
                    }
                }
                Section {
                    TextField("Decision summary", text: field(\.answer), axis: .vertical).lineLimit(3...6)
                        .accessibilityIdentifier("goal-decision")
                } header: { Text("Decision") } footer: {
                    Text("\(model.decision?.answer.unicodeScalars.count ?? 0) / 8000 characters")
                }
                .listRowBackground(tokens.surface)
                Section {
                    Toggle("Propose reusable guidance", isOn: field(\.reusable)).accessibilityIdentifier("goal-reusable")
                    if model.decision?.reusable == true {
                        TextField("Independent reusable rule", text: field(\.guidance), axis: .vertical).lineLimit(2...5)
                            .accessibilityIdentifier("goal-guidance")
                        Picker("Applies to", selection: field(\.scope)) {
                            Text("This locale").tag("locale"); Text("Whole project").tag("project")
                        }
                    }
                } header: { Text("Optional guidance") } footer: {
                    if model.decision?.reusable == true {
                        Text("\(model.decision?.guidance.unicodeScalars.count ?? 0) / 8000 characters")
                    }
                    Text("Guidance is proposed in the translation PR for review, never applied automatically.")
                }
                .listRowBackground(tokens.surface)
                if let error = model.resolutionError { Section { Text(error).foregroundStyle(.red) } }
                if !model.canSaveDecision && !model.resolving {
                    Section { Text("A current completed reply and an independently reviewed decision are required. If the conversation changed, refresh and discard this proposal before resolving the latest reply.") }
                }
                Section {
                    Button("Refresh goal and conversation") { Task { await model.refreshDetail() } }.disabled(model.resolving)
                    Button("Discard decision draft", role: .destructive) { confirmingDiscard = true }.disabled(model.resolving)
                } footer: {
                    Text("Saving approves this decision and resumes translation when all open questions are resolved. Closing keeps your unsaved draft.")
                }
                .listRowBackground(tokens.surface)
            }
            .disabled(model.resolving)
            .scrollContentBackground(.hidden).background(tokens.canvas)
            .navigationTitle("Review decision").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("Close review, keeping draft").disabled(model.resolving)
                        .accessibilityIdentifier("goal-close")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(model.resolving ? String(localized: "Saving…") : String(localized: "Save")) { Task { await model.saveDecision() } }
                        .disabled(!model.canSaveDecision).accessibilityLabel("Save decision and resume")
                        .accessibilityIdentifier("goal-save")
                }
            }
            .confirmationDialog("Discard decision draft?", isPresented: $confirmingDiscard, titleVisibility: .visible) {
                Button("Discard draft", role: .destructive) { model.discardDecision() }
                Button("Keep editing", role: .cancel) { }
            } message: { Text("This removes your unsaved decision and guidance. Nothing is sent to the server.") }
        }
        .presentationDetents([.large]).presentationDragIndicator(.visible)
        .interactiveDismissDisabled(model.resolving)
    }
}
