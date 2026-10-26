import SwiftUI

struct TokiGoalView: View {
    @ObservedObject var model: TokiModel
    var openTranslation: ((String) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shared linguistic goal").font(.headline)
            Text("Visible to project members · one shared conversation.").font(.caption).foregroundStyle(.secondary)
            if let goal = model.goal {
                Text(goal["question"] as? String ?? String(localized: "Linguistic review")).font(.headline).textSelection(.enabled)
                if let participants = goal["participants"] as? [[String: Any]], !participants.isEmpty {
                    Text("Participants: \(participants.compactMap { $0["name"] as? String }.joined(separator: ", "))")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Text("\u{2068}\(goal["locale"] as? String ?? "")\u{2069} · \(goal["status"] as? String == "answered" ? String(localized: "Goal resolved") : goal["status"] as? String == "stale" ? String(localized: "No longer current") : String(localized: "Open goal"))")
                    .font(.subheadline)
                DisclosureGroup("Source and translation context") {
                    ForEach(["source", "translation"], id: \.self) { kind in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\u{2066}\(goal[kind == "source" ? "source_path" : "output_path"] as? String ?? "")\u{2069}").font(.caption.monospaced())
                                .environment(\.layoutDirection, .leftToRight)
                            Text(String((goal["\(kind)_excerpt"] as? String ?? String(localized: "No excerpt")).prefix(1200))).font(.callout.monospaced()).textSelection(.enabled)
                        }.padding(.vertical, 4)
                    }
                }
                if goal["status"] as? String == "answered" {
                    Text("Saved decision").font(.headline)
                    Text(goal["answer"] as? String ?? "").textSelection(.enabled)
                    if let guidance = goal["guidance"] as? String {
                        Text("Proposed guidance · \u{2066}\(goal["context_path"] as? String ?? String(localized: "Translation PR"))\u{2069}").font(.caption)
                        Text(guidance).textSelection(.enabled)
                    }
                    if let resumed = goal["resumed_session_id"] as? String {
                        Text("Translation resumed").font(.headline)
                        Button("View resumed translation") { openTranslation?(resumed) }
                            .accessibilityIdentifier("goal-resumed")
                    } else { Text("Refresh to check for the resumed translation.").font(.caption) }
                } else if goal["status"] as? String == "stale" {
                    Text("This goal is no longer current. Chat and resolution are read-only.")
                }
                if model.goalClosed && !model.draft.isEmpty {
                    Text("Unsent message retained on this device").font(.headline)
                    Text(model.draft).textSelection(.enabled)
                    Button("Discard unsent message", role: .destructive) { model.draft = "" }
                }
            } else { Text("Goal unavailable. Refresh the conversation to check access.") }
            Button("Refresh goal and conversation") { Task { await model.refreshDetail() } }
                .disabled(model.resolving || model.sending || model.detailBusy)
        }.padding(16)
    }
}

struct TokiDecisionView: View {
    @ObservedObject var model: TokiModel
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
                Section("Review the decision before saving") {
                    Text("This is an editable proposal from Toki’s latest completed reply, not an automatic resolution.")
                    TextField("Decision summary", text: field(\.answer), axis: .vertical).lineLimit(3...10)
                        .accessibilityIdentifier("goal-decision")
                    Text("\(model.decision?.answer.unicodeScalars.count ?? 0) / 8000 characters").font(.caption)
                    Toggle("Propose reusable guidance", isOn: field(\.reusable)).accessibilityIdentifier("goal-reusable")
                    if model.decision?.reusable == true {
                        TextField("Independent reusable rule", text: field(\.guidance), axis: .vertical).lineLimit(3...8)
                            .accessibilityIdentifier("goal-guidance")
                        Text("\(model.decision?.guidance.unicodeScalars.count ?? 0) / 8000 characters").font(.caption)
                        Picker("Applies to", selection: field(\.scope)) {
                            Text("This locale").tag("locale"); Text("Whole project").tag("project")
                        }
                        Text("Glossia chooses the nearest L10N.md or L10N/<locale>.md path. Guidance becomes a reviewed diff in the normal translation PR, never a direct repository edit.")
                    }
                }
                if let error = model.resolutionError { Section { Text(error).foregroundStyle(.red) } }
                if !model.canSaveDecision && !model.resolving {
                    Section { Text("A current completed reply and an independently reviewed decision are required. If the conversation changed, refresh and discard this proposal before resolving the latest reply.") }
                }
                Section {
                    Button(model.resolving ? String(localized: "Saving decision…") : String(localized: "Save decision and resume")) { Task { await model.saveDecision() } }
                        .disabled(!model.canSaveDecision).accessibilityIdentifier("goal-save")
                    Button("Refresh goal and conversation") { Task { await model.refreshDetail() } }.disabled(model.resolving)
                    Button("Discard decision draft", role: .destructive) { model.discardDecision() }.disabled(model.resolving)
                }
            }
            .disabled(model.resolving)
            .navigationTitle("Resolve goal").navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled()
        }
    }
}
