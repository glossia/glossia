import SwiftUI

struct WorkspacePicker: View {
    @ObservedObject var session: GlossiaSession
    let request: GlossiaRequest?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.glossiaTokens) private var tokens
    @State private var organization: String
    @State private var search = ""
    @State private var options: [String: Any]?
    @State private var busy = false
    @State private var error: String?
    @State private var revision = 0

    init(session: GlossiaSession, request: GlossiaRequest? = nil) {
        self.session = session
        self.request = request
        _organization = State(initialValue: session.organization ?? session.organizations.first?["handle"] as? String ?? "")
    }

    private var projects: [[String: Any]] {
        (options?["projects"] as? [[String: Any]] ?? []).filter {
            search.isEmpty || ($0["name"] as? String ?? "").localizedCaseInsensitiveContains(search)
                || ($0["handle"] as? String ?? "").localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Organization", selection: $organization) {
                        ForEach(session.organizations.indices, id: \.self) { index in
                            let row = session.organizations[index]
                            Text(row["name"] as? String ?? row["handle"] as? String ?? "")
                                .tag(row["handle"] as? String ?? "")
                        }
                    }.pickerStyle(.menu).accessibilityIdentifier("workspace-organization")
                } footer: { Text("Current: \(session.organization ?? "None") / \(session.project ?? "None"). Your workspace changes only when you choose a project.") }
                .listRowBackground(tokens.surface)
                Section("Projects") {
                    if busy { ProgressView("Loading projects…") }
                    if let error { GlossiaErrorView(message: error) { Task { await load() } } }
                    if !busy && error == nil && projects.isEmpty {
                        ContentUnavailableView(search.isEmpty ? "No projects" : "No matching projects", systemImage: "folder",
                                               description: Text(search.isEmpty ? "This organization has no accessible projects." : "Try a different name or handle."))
                    }
                    ForEach(projects.indices, id: \.self) { index in
                        let project = projects[index]
                        if let handle = project["handle"] as? String {
                            Button {
                                if let options { session.selectWorkspace(options, project: handle) }
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(project["name"] as? String ?? handle).foregroundStyle(tokens.ink)
                                        Text("\(organization) / \(handle)").font(.caption).foregroundStyle(tokens.muted)
                                    }
                                    Spacer()
                                    if organization == session.organization && handle == session.project {
                                        Image(systemName: "checkmark").foregroundStyle(tokens.tint)
                                            .accessibilityLabel("Selected")
                                    }
                                }.padding(.vertical, 4)
                            }.disabled(busy).accessibilityIdentifier("workspace-project-\(handle)")
                        }
                    }
                }.listRowBackground(tokens.surface)
                Section {
                    Text("Toki, translations and analytics use this project. Switching projects clears unsent Toki drafts.")
                        .font(.footnote).foregroundStyle(tokens.muted)
                }.listRowBackground(tokens.surface)
            }
            .scrollContentBackground(.hidden).background(tokens.canvas)
            .searchable(text: $search, prompt: "Find a project")
            .navigationTitle("Switch workspace").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .task(id: organization) { await load() }
        }
        .presentationDetents([.large])
    }

    private func load() async {
        guard !organization.isEmpty else { return }
        revision += 1
        let ticket = revision
        let context = session.projectContext
        busy = true; error = nil; options = nil
        defer { if ticket == revision { busy = false } }
        do {
            let result: [String: Any]
            if let request {
                result = try await request(["operation": "workspace", "selection": ["organization": organization]])
            } else { result = try await session.workspaceOptions(organization: organization, context: context) }
            try Task.checkCancellation()
            if ticket == revision { options = result }
        } catch is CancellationError { }
        catch { if ticket == revision { self.error = error.localizedDescription } }
    }
}
