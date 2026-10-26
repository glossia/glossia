import SwiftUI

struct GlossiaLoginView: View {
    @ObservedObject var session: GlossiaSession
    @Environment(\.glossiaTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingServer = false
    @State private var address = "https://"

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: 32)
                        Image("GlossiaMark")
                            .resizable().scaledToFit().padding(12)
                            .frame(width: 64, height: 64)
                            .background(tokens.surface, in: RoundedRectangle(cornerRadius: tokens.radius))
                            .accessibilityHidden(true)
                            .padding(.bottom, 32)
                        Text("Welcome to Glossia")
                            .font(.title.weight(.medium)).multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)
                            .padding(.bottom, 12)
                        Text("Your voice. Every language.\nOne workspace, wherever you are.")
                            .font(.subheadline).multilineTextAlignment(.center)
                            .foregroundStyle(tokens.muted)
                        Spacer(minLength: 32)
                        VStack(spacing: 12) {
                            if session.busy { ProgressView("Signing in…") }
                            if let message = session.errorMessage {
                                Text(message).font(.footnote).foregroundStyle(.red).multilineTextAlignment(.center)
                                Button("Retry saved session") { session.restoring = true; Task { await session.restore() } }
                            }
                            Button { Task { await session.signIn(address: "https://glossia.ai") } } label: {
                                Text("Sign in with Glossia").frame(maxWidth: .infinity, minHeight: 32)
                            }
                            .buttonStyle(.borderedProminent).controlSize(.large)
                            .modifier(GlossiaPrimaryAction())
                            HStack(spacing: 8) {
                                Rectangle().fill(tokens.border).frame(height: 1)
                                Text("or").font(.footnote).foregroundStyle(tokens.muted)
                                Rectangle().fill(tokens.border).frame(height: 1)
                            }.accessibilityHidden(true)
                            Button { showingServer = true } label: {
                                Label("Self-hosted server", systemImage: "server.rack")
                                    .frame(maxWidth: .infinity, minHeight: 32)
                            }.buttonStyle(.bordered).controlSize(.large)
                            Text("Secure sign-in opens in your browser.")
                                .font(.caption).foregroundStyle(tokens.muted)
                            Button("Reset saved sign-in") { Task { await session.signOut(resetRegistration: true) } }
                                .font(.caption).padding(.vertical, 8)
                        }
                        .disabled(session.busy)
                        .padding(GlossiaBrand.gutter).padding(.top, 8)
                        .background {
                            UnevenRoundedRectangle(topLeadingRadius: 32, topTrailingRadius: 32)
                                .fill(tokens.surface.opacity(colorScheme == .dark ? 0.8 : 0.65))
                                .overlay {
                                    UnevenRoundedRectangle(topLeadingRadius: 32, topTrailingRadius: 32)
                                        .stroke(tokens.border, lineWidth: 1)
                                }
                                .padding(.bottom, -geometry.safeAreaInsets.bottom)
                        }
                    }
                    .frame(maxWidth: 560).frame(minHeight: geometry.size.height)
                    .frame(maxWidth: .infinity)
                }
                .scrollBounceBehavior(.basedOnSize).scrollIndicators(.hidden)
            }
            .background {
                ZStack {
                    tokens.canvas
                    RadialGradient(colors: [tokens.accent.opacity(0.22), .clear],
                                   center: .topTrailing, startRadius: 0, endRadius: 520)
                    RadialGradient(colors: [tokens.accent.opacity(0.10), .clear],
                                   center: .bottomLeading, startRadius: 0, endRadius: 400)
                }.ignoresSafeArea()
            }
        }
        .sheet(isPresented: $showingServer) {
            NavigationStack {
                Form {
                    Section {
                        TextField("Server address", text: $address, prompt: Text("https://glossia.example.com"))
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                            .keyboardType(.URL).textContentType(.URL)
                    } footer: { Text("Enter your Glossia server’s HTTPS address. Sign-in opens in your browser.") }
                    .listRowBackground(tokens.surface)
                }
                .scrollContentBackground(.hidden).background(tokens.canvas)
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
