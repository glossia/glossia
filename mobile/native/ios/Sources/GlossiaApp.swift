import SwiftUI

@main
struct GlossiaApp: App {
    @StateObject private var session = GlossiaSession()
    @StateObject private var appearance = GlossiaAppearance()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if session.restoring { ProgressView("Opening Glossia…") }
                else if session.server != nil {
                    GlossiaWorkspaceView(session: session).id(session.projectContext)
                }
                else { GlossiaLoginView(session: session) }
            }
            .modifier(GlossiaThemeScope(appearance: appearance))
            .modifier(GlossiaLinkNotice(navigation: session.navigation) { Task { await session.resolveNavigation() } })
            .task { await session.restore() }
            .task(id: session.appearanceServer) { await appearance.configure(server: session.appearanceServer) }
            .onOpenURL { url in Task { await session.receive(url) } }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await appearance.refresh() } }
            }
        }
    }
}
