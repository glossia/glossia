import SwiftUI

struct GlossiaWorkspaceView: View {
    @ObservedObject var session: GlossiaSession
    @ObservedObject private var navigation: GlossiaNavigation
    @Environment(\.glossiaTokens) private var tokens
    @State private var showingWorkspace = false
    private let requestOverride: GlossiaRequest?

    init(session: GlossiaSession, request: GlossiaRequest? = nil) {
        self.session = session
        self.navigation = session.navigation
        self.requestOverride = request
    }

    private var request: GlossiaRequest {
        if let requestOverride { return requestOverride }
        let context = session.projectContext
        return { [weak session] value in
            guard let session else { throw CancellationError() }
            return try await session.request(value, context: context)
        }
    }

    var body: some View {
        TabView(selection: $session.tab) {
            NavigationStack {
                TokiView(request: request, hasProject: session.project != nil,
                         destination: navigation.targets["toki"], revision: navigation.revisions["toki"],
                         openSource: { open(.translation, id: $0) })
                    .navigationTitle("Toki")
                    .toolbar { workspaceButton }
            }.tabItem { Label("Toki", systemImage: "bubble.left.and.bubble.right").symbolRenderingMode(.monochrome) }.tag("toki")
            NavigationStack {
                TranslationsView(request: request, hasProject: session.project != nil, open: { open(.translation, id: $0) })
                    .navigationTitle("Translations")
                    .toolbar { workspaceButton }
                    .navigationDestination(isPresented: Binding(
                        get: { navigation.targets["translations"]?.screen == .translation },
                        set: { if !$0 { navigation.clearTarget("translations") } }
                    )) {
                        if let destination = navigation.targets["translations"], destination.screen == .translation {
                            TranslationDetailView(destination: destination, request: request) {
                                open(.newConversation, translationID: destination.id)
                            }.id(destination.id)
                        }
                    }
            }.tabItem { Label("Translations", systemImage: "character.bubble").symbolRenderingMode(.monochrome) }.tag("translations")
            NavigationStack {
                AnalyticsView(request: request, hasProject: session.project != nil)
                    .navigationTitle("Analytics")
                    .toolbar { workspaceButton }
            }.tabItem { Label("Analytics", systemImage: "chart.bar.xaxis").symbolRenderingMode(.monochrome) }.tag("analytics")
            NavigationStack {
                ProfileView(session: session, request: request)
                    .navigationTitle("Profile")
            }.tabItem { Label("Profile", systemImage: "person.crop.circle").symbolRenderingMode(.monochrome) }.tag("profile")
        }
        .tint(tokens.tint)
        .environment(\.glossiaNavigation, navigation)
        .sheet(isPresented: $showingWorkspace) { WorkspacePicker(session: session, request: requestOverride) }
    }

    private func open(_ screen: GlossiaDestination.Screen, id: String? = nil, translationID: String? = nil) {
        guard let destination = session.destination(screen, id: id, translationID: translationID) else { return }
        Task { await session.navigate(destination, request: requestOverride) }
    }

    private var workspaceButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button { showingWorkspace = true } label: {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(session.organization ?? "Workspace").font(.caption).foregroundStyle(tokens.muted)
                        Text(session.selectedProject?["name"] as? String ?? session.project ?? "Choose project")
                            .font(.subheadline.weight(.medium)).lineLimit(1)
                    }
                    Image(systemName: "chevron.down").font(.caption)
                }
            }
            .accessibilityLabel("Choose workspace. Organization: \(session.organization ?? "none"), project: \(session.project ?? "none")")
            .accessibilityIdentifier("workspace-switcher")
        }
    }
}
