import SwiftUI

@main
struct GlossiaApp: App {
    @UIApplicationDelegateAdaptor(GlossiaPushDelegate.self) private var pushDelegate
    @StateObject private var session = GlossiaSession()
    @StateObject private var appearance = GlossiaAppearance()
    @StateObject private var tokiWork = TokiWorkController(liveActivities: true)
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if session.restoring { ProgressView("Opening Glossia…") }
                else if session.server != nil {
                    GlossiaWorkspaceView(session: session, tokiWork: tokiWork).id(session.projectContext)
                }
                else { GlossiaLoginView(session: session) }
            }
            .modifier(GlossiaThemeScope(appearance: appearance))
            .modifier(GlossiaLinkNotice(navigation: session.navigation) { Task { await session.resolveNavigation() } })
            .task { await session.restore() }
            .task(id: session.server) { await session.configurePush() }
            .task(id: session.appearanceServer) { await appearance.configure(server: session.appearanceServer) }
            .onOpenURL { url in Task { await session.receive(url) } }
            .onChange(of: pushDelegate.destination, initial: true) { _, url in
                guard let url else { return }
                pushDelegate.destination = nil
                Task { await session.receive(url) }
            }
            .onReceive(pushDelegate.$token) { token in Task { await session.push.refresh(token: token) } }
            .onChange(of: pushDelegate.registrationFailed) { _, failed in if failed { session.push.registrationFailed() } }
            .onChange(of: session.server == nil ? nil : session.projectContext, initial: true) { _, _ in configureToki() }
            .onChange(of: scenePhase, initial: true) { _, phase in
                tokiWork.setForeground(phase == .active)
                if phase == .active { Task { await appearance.refresh(); await session.push.refresh() } }
            }
        }
    }

    private func configureToki() {
        guard session.server != nil, session.project != nil else { tokiWork.clear(); return }
        let session = session, context = session.projectContext
        tokiWork.configure(context: context, request: { [weak session] input in
            guard let session else { throw CancellationError() }
            return try await session.request(input, context: context)
        }, authorized: { [weak session] in
            session?.server != nil && session?.projectContext == context
        }, destination: { [weak session] id in
            session?.destination(.conversation, id: id)?.url
        })
    }
}
