import SwiftUI

struct GlossiaWorkspaceView: View {
    @ObservedObject var session: GlossiaSession
    @State private var showingWorkspace = false

    var body: some View {
        TabView(selection: $session.tab) {
            page("Overview") { overview }
                .tabItem { Label("Overview", systemImage: "square.grid.2x2") }.tag("Overview")
            page("Voice") { resource("Voice") }
                .tabItem { Label("Voice", systemImage: "waveform") }.tag("Voice")
            page("Glossary") { resource("Glossary") }
                .tabItem { Label("Glossary", systemImage: "character.book.closed") }.tag("Glossary")
            page("Settings") { settings }
                .tabItem { Label("Settings", systemImage: "gearshape") }.tag("Settings")
        }
        .sheet(isPresented: $showingWorkspace) { workspacePicker }
        .task(id: "\(session.contextID)/\(session.busy)") {
            if !session.busy { await session.loadResource() }
        }
    }

    private func page<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        NavigationStack {
            List {
                if let message = session.errorMessage {
                    Section {
                        Text(message).foregroundStyle(.red)
                        Button("Retry") { Task { await session.reload() } }
                    }
                }
                if session.busy { Section { ProgressView("Loading workspace…") } }
                else { content() }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingWorkspace = true } label: {
                        Label(session.organization ?? "Workspace", systemImage: "building.2")
                    }
                    .accessibilityLabel("Choose workspace. Organization: \(session.organization ?? "none"), project: \(session.project ?? "none")")
                }
            }
            .refreshable { await session.reload() }
        }
    }

    private var workspacePicker: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Organization", selection: Binding(
                        get: { session.organization ?? "" },
                        set: { handle in Task { await session.selectOrganization(handle) } }
                    )) {
                        if session.organizations.isEmpty { Text("No organizations").tag("") }
                        ForEach(session.organizations.indices, id: \.self) { index in
                            let org = session.organizations[index]
                            if let handle = org["handle"] as? String {
                                Text(org["name"] as? String ?? handle).tag(handle)
                            }
                        }
                    }.pickerStyle(.navigationLink).disabled(session.busy || session.organizations.isEmpty)
                    Picker("Project", selection: Binding(
                        get: { session.project ?? "" }, set: { session.selectProject($0) }
                    )) {
                        if session.projects.isEmpty { Text("No projects").tag("") }
                        ForEach(session.projects.indices, id: \.self) { index in
                            let project = session.projects[index]
                            if let handle = project["handle"] as? String {
                                Text(project["name"] as? String ?? handle).tag(handle)
                            }
                        }
                    }.pickerStyle(.navigationLink).disabled(session.busy || session.projects.isEmpty)
                } footer: { Text("Your workspace selection applies to every tab. Voice and glossary are shared by the organization.") }
                if session.busy { Section { ProgressView("Loading workspace…") } }
                if let message = session.errorMessage {
                    Section {
                        Text(message).foregroundStyle(.red)
                        Button("Retry") { Task { await session.reload() } }
                    }
                }
            }
            .navigationTitle("Workspace").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showingWorkspace = false } } }
        }
    }

    @ViewBuilder private var overview: some View {
        if session.organization == nil {
            ContentUnavailableView("No organizations yet", systemImage: "building.2",
                                   description: Text("Create or join an organization on Glossia to get started."))
        } else if let project = session.selectedProject {
            Section("Project") {
                LabeledContent("Name", value: project["name"] as? String ?? session.project ?? "Project")
                LabeledContent("Organization", value: session.organization ?? "")
                LabeledContent("Handle", value: session.project ?? "")
                if let status = project["setup_status"] as? String { LabeledContent("Setup", value: status) }
                if let repository = project["github_repo_full_name"] as? String { LabeledContent("Repository", value: repository) }
            }
        } else {
            ContentUnavailableView("No projects yet", systemImage: "folder",
                                   description: Text("This organization has no projects. Voice and glossary are still available."))
        }
    }

    @ViewBuilder private func resource(_ title: String) -> some View {
        Section {
            LabeledContent("Organization", value: session.organization ?? "None")
            if let version = session.resource?["version"] as? Int { LabeledContent("Version", value: String(version)) }
        } footer: { Text("Shared by every project in this organization.") }
        if session.organization == nil {
            ContentUnavailableView("Choose an organization", systemImage: "building.2")
        } else if session.resourceBusy {
            Section { ProgressView("Loading \(title.lowercased())…") }
        } else if let error = session.resourceError {
            Section {
                Text(error).foregroundStyle(.red)
                Button("Retry") { Task { await session.loadResource() } }
            }
        } else if let resource = session.resource {
            if title == "Voice" {
                ForEach(["tone", "formality", "target_audience", "guidelines"], id: \.self) { key in
                    if let value = resource[key] as? String, !value.isEmpty {
                        Section(key.replacingOccurrences(of: "_", with: " ").capitalized) {
                            Text(value).textSelection(.enabled)
                        }
                    }
                }
            } else if let entries = resource["entries"] as? [[String: Any]], !entries.isEmpty {
                Section("Terms") {
                    ForEach(entries.indices, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entries[index]["term"] as? String ?? "Term").font(.headline)
                            Text(entries[index]["definition"] as? String ?? "").foregroundStyle(.secondary)
                        }.textSelection(.enabled)
                    }
                }
            } else { Text("No glossary entries yet.").foregroundStyle(.secondary) }
        } else {
            ContentUnavailableView("No \(title.lowercased()) configured", systemImage: title == "Voice" ? "waveform" : "character.book.closed",
                                   description: Text("Configure your organization’s \(title.lowercased()) on Glossia."))
        }
    }

    private var settings: some View {
        Group {
            Section("Connection") {
                LabeledContent("Server", value: session.server ?? "").textSelection(.enabled)
                LabeledContent("Organization", value: session.organization ?? "None")
                LabeledContent("Project", value: session.project ?? "None")
            }
            Section {
                Button("Sign out", role: .destructive) { Task { await session.signOut() } }
            } footer: { Text("Your credentials are protected by the iOS Keychain.") }
        }
    }
}
