import SwiftUI

@main
struct GlossiaApp: App {
    @StateObject private var session = GlossiaSession()

    var body: some Scene {
        WindowGroup {
            Group {
                if session.restoring { ProgressView("Opening Glossia…") }
                else if session.server != nil { GlossiaWorkspaceView(session: session) }
                else { GlossiaLoginView(session: session) }
            }
            .tint(Color("AccentColor"))
            .task { await session.restore() }
        }
    }
}

struct GlossiaLoginView: View {
    @ObservedObject var session: GlossiaSession
    @State private var showingServer = false
    @State private var address = "https://"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image("GlossiaMark")
                        .resizable().scaledToFit()
                        .frame(width: 72, height: 72)
                        .accessibilityHidden(true)
                    Text("Welcome to Glossia")
                        .font(.largeTitle.bold()).multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    Text("Your voice. Every language.")
                        .font(.title3).foregroundStyle(.secondary)
                    VStack(spacing: 16) {
                        if session.busy { ProgressView("Signing in…") }
                        if let message = session.errorMessage {
                            Text(message).font(.footnote).foregroundStyle(.red).multilineTextAlignment(.center)
                            Button("Retry saved session") { session.restoring = true; Task { await session.restore() } }
                        }
                        Button { Task { await session.signIn(address: "https://glossia.ai") } } label: {
                            Text("Sign in with Glossia").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent).controlSize(.large)
                        Button { showingServer = true } label: {
                            Label("Self-hosted server", systemImage: "server.rack")
                                .frame(maxWidth: .infinity)
                        }.buttonStyle(.bordered).controlSize(.large)
                        Button("Reset saved sign-in") { Task { await session.signOut(resetRegistration: true) } }
                        Text("Secure sign-in opens in your browser.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .disabled(session.busy)
                }
                .frame(maxWidth: 440).padding(24).padding(.top, 32)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .sheet(isPresented: $showingServer) {
            NavigationStack {
                Form {
                    Section {
                        TextField("Server address", text: $address, prompt: Text("https://glossia.example.com"))
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                            .keyboardType(.URL).textContentType(.URL)
                    } footer: { Text("Enter your Glossia server’s HTTPS address. Sign-in opens in your browser.") }
                }
                .navigationTitle("Self-hosted server").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingServer = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Sign in") {
                            showingServer = false
                            Task { await session.signIn(address: address) }
                        }.disabled(address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }.presentationDetents([.medium, .large])
        }
    }
}
