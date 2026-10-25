import SwiftUI

struct ProfileView: View {
    @ObservedObject var session: GlossiaSession
    @Environment(\.glossiaTokens) private var tokens
    let request: GlossiaRequest
    @State private var value: [String: Any]?
    @State private var error: String?
    @State private var busy = false
    @State private var confirmingSignOut = false

    var body: some View {
        List {
            if busy { ProgressView("Loading profile…") }
            if let error { GlossiaErrorView(message: error) { Task { await load() } } }
            if let user = value?["user"] as? [String: Any] {
                Section {
                    Label(user["name"] as? String ?? user["handle"] as? String ?? "Your profile", systemImage: "person.crop.circle.fill")
                        .font(.headline)
                    LabeledContent("Email", value: user["email"] as? String ?? "")
                    LabeledContent("Handle", value: user["handle"] as? String ?? "")
                }.listRowBackground(tokens.surface)
            }
            Section("Connection") {
                LabeledContent("Server", value: session.server ?? "").textSelection(.enabled)
                LabeledContent("Server version", value: value?["server_version"] as? String ?? "Not available")
                LabeledContent("Organization", value: session.organization ?? "None")
                LabeledContent("Project", value: session.project ?? "None")
            }.listRowBackground(tokens.surface)
            Section("Glossia") {
                LabeledContent("App version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")
                Text("Your credentials are protected by the iOS Keychain. Toki conversations are private to you and your selected project.")
                    .font(.footnote).foregroundStyle(tokens.muted)
            }.listRowBackground(tokens.surface)
            Section {
                Button("Sign out", role: .destructive) { confirmingSignOut = true }.disabled(session.busy)
            }.listRowBackground(tokens.surface)
            if let message = session.errorMessage { Text(message).foregroundStyle(.red) }
        }
        .scrollContentBackground(.hidden).background(tokens.canvas)
        .task { await load() }.refreshable { await load() }
        .confirmationDialog("Sign out of Glossia? Unsaved Toki drafts will be removed.", isPresented: $confirmingSignOut, titleVisibility: .visible) {
            Button("Sign out", role: .destructive) { Task { await session.signOut() } }
        }
    }

    private func load() async {
        guard !busy else { return }
        busy = true; error = nil
        defer { busy = false }
        do { value = try await request(["operation": "resource", "resource": "profile"]) }
        catch is CancellationError { }
        catch { self.error = error.localizedDescription }
    }
}
