import AuthenticationServices
import Foundation
import GlossiaCoreFFI
import Security
import SwiftUI

struct GlossiaFailure: LocalizedError {
    let kind: String
    let message: String
    var errorDescription: String? { message }
}

enum Keychain {
    static func query(_ name: String) -> [CFString: Any] {
        [kSecClass: kSecClassGenericPassword, kSecAttrService: "ai.glossia.mobile.oauth", kSecAttrAccount: name]
    }

    static func load(_ name: String) throws -> Data? {
        var query = query(name)
        query[kSecReturnData] = true
        query[kSecMatchLimit] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else { throw failure() }
        return data
    }

    static func save(_ name: String, _ value: Any) throws {
        let data = try JSONSerialization.data(withJSONObject: value)
        let status = SecItemUpdate(query(name) as CFDictionary, [kSecValueData: data] as CFDictionary)
        if status == errSecItemNotFound {
            var item = query(name)
            item[kSecValueData] = data
            item[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else { throw failure() }
        } else if status != errSecSuccess { throw failure() }
    }

    static func delete(_ name: String) throws {
        let status = SecItemDelete(query(name) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw failure() }
    }

    private static func failure() -> GlossiaFailure {
        GlossiaFailure(kind: "storage", message: String(localized: "Could not access secure storage. Try again."))
    }
}

private actor FeatureSlots {
    private var active = 0
    private var waiting: [CheckedContinuation<Void, Never>] = []

    func acquire() async throws {
        try Task.checkCancellation()
        if active < 4 { active += 1 }
        else { await withCheckedContinuation { waiting.append($0) } }
        if Task.isCancelled {
            release()
            throw CancellationError()
        }
    }

    func release() {
        if waiting.isEmpty { active -= 1 }
        else { waiting.removeFirst().resume() }
    }
}

// Only credential rotation and persistence are serialized. Feature networking uses
// independent tasks after taking a durable credential snapshot.
actor GlossiaRuntime {
    private var generation = 0
    private let slots = FeatureSlots()

    func run(_ input: Data, authenticated: Bool = false) async throws -> Data {
        try Task.checkCancellation()
        var request = try JSONSerialization.jsonObject(with: input) as! [String: Any]
        let operation = request["operation"] as? String
        let ticket = generation
        var credential: Data?
        if authenticated {
            try await slots.acquire()
        }
        defer { if authenticated { Task { await slots.release() } } }
        guard ticket == generation else { throw CancellationError() }
        do {
            if operation == "sign_out" || operation == "reset_sign_in" {
                try Self.endPushSession()
                if operation == "reset_sign_in" { try Keychain.delete("registration") }
                try Keychain.delete("session")
                generation += 1
                return Data("{}".utf8)
            }
            if operation == "begin", let saved = try Keychain.load("registration") {
                request["registration"] = try JSONSerialization.jsonObject(with: saved)
            }
            if authenticated || operation == "restore" {
                guard let saved = try Keychain.load("session") else {
                    throw GlossiaFailure(kind: "sign_in_required", message: String(localized: "Sign in to Glossia."))
                }
                let session = try Self.command(["operation": "restore", "session": JSONSerialization.jsonObject(with: saved)])
                // Save refresh rotation before any following API request can fail.
                try Keychain.save("session", session)
                credential = try Keychain.load("session")
                if operation == "restore" { return try JSONSerialization.data(withJSONObject: session) }
                try Task.checkCancellation()
                request["session"] = session
            }
            if authenticated {
                let payload = try JSONSerialization.data(withJSONObject: request)
                let task = Task.detached(priority: .userInitiated) {
                    try Task.checkCancellation()
                    let request = try JSONSerialization.jsonObject(with: payload) as! [String: Any]
                    return try JSONSerialization.data(withJSONObject: Self.command(request))
                }
                let result = try await withTaskCancellationHandler {
                    try await task.value
                } onCancel: { task.cancel() }
                guard !Task.isCancelled, ticket == generation else {
                    if operation == "translation_live", request["action"] as? String == "open",
                       let opened = try JSONSerialization.jsonObject(with: result) as? [String: Any],
                       let connection = opened["connection"] as? String {
                        _ = try? Self.command(["operation": "translation_live", "action": "close", "connection": connection])
                    }
                    throw CancellationError()
                }
                return result
            }
            let result = try Self.command(request)
            if operation == "begin", let registration = result["registration"] {
                try Keychain.save("registration", registration)
            }
            if operation == "complete" {
                try Keychain.save("session", result)
                generation += 1
            }
            return try JSONSerialization.data(withJSONObject: result)
        } catch let failure as GlossiaFailure {
            guard ticket == generation else { throw CancellationError() }
            // A late 401 from an older token must not delete a newer rotation.
            if authenticated, let credential, credential != (try Keychain.load("session")) {
                throw GlossiaFailure(kind: "retry", message: String(localized: "Your session changed. Retry this request."))
            }
            if failure.kind == "rejected" || failure.kind == "sign_in_required" {
                try Self.endPushSession()
                try Keychain.delete("session")
                if failure.kind == "rejected" { try Keychain.delete("registration") }
                generation += 1
            }
            throw failure
        }
    }

    private nonisolated static func endPushSession() throws {
        guard let data = try Keychain.load("session"),
              let session = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let registration = session["registration"] as? [String: Any],
              let origin = registration["server"] as? String,
              let saved = try GlossiaPushStore().disable(origin) else { return }
        let payload = try JSONSerialization.data(withJSONObject: ["operation": "push", "action": "unregister",
            "installation_id": saved.installationID, "session": session])
        // Logout never waits for provider/server networking. Keep the tombstone
        // even after success, so next sign-in reconciles before creating a new ID.
        Task.detached {
            if let input = try? JSONSerialization.jsonObject(with: payload) as? [String: Any] {
                _ = try? command(input)
            }
        }
    }

    // These commands only wait on or close a Rust-owned local socket handle.
    // They must never occupy the credential actor or a feature-network slot.
    nonisolated static func localLive(_ input: Data) async throws -> Data {
        try await Task.detached {
            let request = try JSONSerialization.jsonObject(with: input) as! [String: Any]
            return try JSONSerialization.data(withJSONObject: command(request))
        }.value
    }

    private nonisolated static func command(_ request: [String: Any]) throws -> [String: Any] {
        let input = String(decoding: try JSONSerialization.data(withJSONObject: request), as: UTF8.self)
        return try input.withCString { pointer in
            guard let output = glossia_core_execute(pointer) else {
                throw GlossiaFailure(kind: "internal", message: String(localized: "Could not complete the request."))
            }
            defer { glossia_core_free(output) }
            let result = try JSONSerialization.jsonObject(with: Data(String(cString: output).utf8)) as! [String: Any]
            if let failure = result["error"] as? [String: String] {
                throw GlossiaFailure(kind: failure["kind"] ?? "internal", message: failure["message"] ?? "Request failed.")
            }
            guard let value = result["ok"] as? [String: Any] else {
                throw GlossiaFailure(kind: "invalid_response", message: String(localized: "Glossia returned an invalid response."))
            }
            return value
        }
    }
}

@MainActor
final class GlossiaSession: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    @Published var server: String?
    @Published var appearanceServer = "https://glossia.ai"
    @Published var busy = false
    @Published var restoring = true
    @Published var errorMessage: String?
    @Published var organizations: [[String: Any]] = []
    @Published var projects: [[String: Any]] = []
    @Published var organization: String?
    @Published var project: String?
    @Published var tab = "toki"

    let navigation = GlossiaNavigation()
    let push: GlossiaPushNotifications
    private let runtime = GlossiaRuntime()
    private var browser: ASWebAuthenticationSession?
    private var identity = UUID()
    var selection: [String: Any] { ["organization": organization as Any? ?? NSNull(), "project": project as Any? ?? NSNull()] }
    var projectContext: String { "\(identity)/\(organization ?? "")/\(project ?? "")" }
    var selectedProject: [String: Any]? { projects.first { $0["handle"] as? String == project } }

    init(push: GlossiaPushNotifications? = nil) {
        self.push = push ?? GlossiaPushNotifications()
        super.init()
    }

    func configurePush() async {
        guard server != nil else { await push.configure(origin: nil, request: nil); return }
        let identity = identity
        let request: GlossiaRequest = { [weak self] input in
            guard let self, self.identity == identity, self.server != nil else { throw CancellationError() }
            do {
                let response = try await self.run(input, authenticated: true)
                guard self.identity == identity, self.server != nil else { throw CancellationError() }
                return response
            } catch {
                if self.identity == identity { self.reportCredentialFailure(error) }
                throw error
            }
        }
        await push.configure(origin: server, request: request)
    }

    func request(_ value: [String: Any], context: String) async throws -> [String: Any] {
        let live = value["operation"] as? String == "translation_live"
        let action = value["action"] as? String
        if live && ["next", "close"].contains(action ?? "") {
            if action != "close" { guard context == projectContext, server != nil else { throw CancellationError() } }
            let input = try JSONSerialization.data(withJSONObject: value)
            let result = try await GlossiaRuntime.localLive(input)
            if action != "close" {
                try Task.checkCancellation()
                guard context == projectContext, server != nil else { throw CancellationError() }
            }
            return try JSONSerialization.jsonObject(with: result) as! [String: Any]
        }
        guard context == projectContext, server != nil else { throw CancellationError() }
        var value = value
        value["selection"] = selection
        do {
            let response = try await run(value, authenticated: true)
            if live, action == "open", (Task.isCancelled || context != projectContext || server == nil),
               let connection = response["connection"] as? String {
                let input = try JSONSerialization.data(withJSONObject: ["operation": "translation_live", "action": "close", "connection": connection])
                _ = try? await GlossiaRuntime.localLive(input)
            }
            try Task.checkCancellation()
            guard context == projectContext, server != nil else { throw CancellationError() }
            return response
        } catch {
            guard context == projectContext else { throw CancellationError() }
            reportCredentialFailure(error)
            throw error
        }
    }

    private func run(_ value: [String: Any], authenticated: Bool = false) async throws -> [String: Any] {
        let data = try JSONSerialization.data(withJSONObject: value)
        let result = try await runtime.run(data, authenticated: authenticated)
        return try JSONSerialization.jsonObject(with: result) as! [String: Any]
    }

    func restore() async {
        guard restoring else { return }
        defer { restoring = false; Task { await resolveNavigation() } }
        let identity = identity
        do {
            let session = try await run(["operation": "restore"])
            guard identity == self.identity else { return }
            server = (session["registration"] as? [String: Any])?["server"] as? String
            appearanceServer = server ?? "https://glossia.ai"
            if let data = UserDefaults.standard.data(forKey: "glossia.selection"),
               let selection = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                organization = selection["organization"] as? String
                project = selection["project"] as? String
            }
            await reload()
        } catch let failure as GlossiaFailure where failure.kind == "sign_in_required" {
            // A first launch has no session.
        } catch { report(error) }
    }

    func signIn(address: String) async {
        guard !busy else { return }
        appearanceServer = address
        busy = true
        errorMessage = nil
        defer { busy = false; browser = nil; Task { await resolveNavigation() } }
        let identity = identity
        do {
            let login = try await run(["operation": "begin", "server": address])
            guard let urlString = login["authorization_url"] as? String, let url = URL(string: urlString),
                  let pending = login["pending"] else { throw GlossiaFailure(kind: "invalid_response", message: String(localized: "Invalid sign-in response.")) }
            guard let callback = try await authenticate(url) else { return }
            let session = try await run(["operation": "complete", "pending": pending, "callback": callback.absoluteString])
            guard identity == self.identity else { return }
            server = (session["registration"] as? [String: Any])?["server"] as? String
            appearanceServer = server ?? "https://glossia.ai"
            busy = false
            await reload()
        } catch { report(error) }
    }

    func reload() async {
        guard !busy, server != nil else { return }
        busy = true
        errorMessage = nil
        let identity = identity
        defer {
            if identity == self.identity {
                busy = false
                Task { await resolveNavigation() }
            }
        }
        do {
            let value = try await run(["operation": "workspace", "selection": selection], authenticated: true)
            guard identity == self.identity else { return }
            organizations = value["organizations"] as? [[String: Any]] ?? []
            projects = value["projects"] as? [[String: Any]] ?? []
            let selection = value["selection"] as? [String: Any] ?? [:]
            organization = selection["organization"] as? String
            project = selection["project"] as? String
            UserDefaults.standard.set(try JSONSerialization.data(withJSONObject: self.selection), forKey: "glossia.selection")
        } catch { if identity == self.identity { report(error) } }
    }

    func workspaceOptions(organization: String, context: String) async throws -> [String: Any] {
        guard context == projectContext else { throw CancellationError() }
        do {
            let result = try await run(["operation": "workspace", "selection": ["organization": organization]], authenticated: true)
            try Task.checkCancellation()
            guard context == projectContext else { throw CancellationError() }
            return result
        } catch {
            if context == projectContext { reportCredentialFailure(error) }
            throw error
        }
    }

    func selectWorkspace(_ value: [String: Any], project: String, fromNavigation: Bool = false) {
        let options = value["projects"] as? [[String: Any]] ?? []
        guard options.contains(where: { $0["handle"] as? String == project }),
              let selection = value["selection"] as? [String: Any],
              let organization = selection["organization"] as? String else { return }
        if !fromNavigation { navigation.reset() }
        else if self.organization != organization || self.project != project { navigation.workspaceChanged() }
        projects = options
        self.organization = organization
        self.project = project
        UserDefaults.standard.set(try? JSONSerialization.data(withJSONObject: self.selection), forKey: "glossia.selection")
    }

    func destination(_ screen: GlossiaDestination.Screen, id: String? = nil, translationID: String? = nil) -> GlossiaDestination? {
        guard let server else { return nil }
        return GlossiaDestination(screen: screen, server: server,
                                  organization: screen == .profile ? nil : organization,
                                  project: screen == .profile ? nil : project, id: id, translationID: translationID)
    }

    func receive(_ url: URL, request: GlossiaRequest? = nil) async {
        // The browser's PKCE session owns OAuth callbacks. They are never intents.
        if url.scheme == "glossia", url.host == "oauth", url.path == "/callback" { return }
        do { await navigate(try GlossiaDestination.parse(url), request: request) }
        catch { navigation.message = error.localizedDescription }
    }

    func navigate(_ destination: GlossiaDestination, request: GlossiaRequest? = nil) async {
        do { navigation.queue(try destination.validated()) }
        catch { navigation.message = error.localizedDescription; return }
        await resolveNavigation(request: request)
    }

    func resolveNavigation(request: GlossiaRequest? = nil) async {
        guard !restoring, !busy, let server,
              let (destination, revision) = navigation.begin() else { return }
        defer { navigation.finish(revision) }
        let context = projectContext
        guard let origin = try? GlossiaDestination(screen: .profile, server: server).validated().server,
              destination.server == origin else {
            navigation.reject(String(localized: "This link belongs to a different Glossia server. Sign in to that server and open the link again."))
            return
        }
        guard !navigation.hasProtectedWork else {
            navigation.reject(String(localized: "Finish or discard your conversation draft before opening another destination."))
            return
        }
        do {
            if destination.screen != .profile {
                let input: [String: Any] = ["operation": "workspace", "selection": [
                    "organization": destination.organization!, "project": destination.project!
                ]]
                let value: [String: Any]
                if let request { value = try await request(input) }
                else { value = try await run(input, authenticated: true) }
                try Task.checkCancellation()
                guard context == projectContext, navigation.isCurrent(revision) else { return }
                let selected = value["selection"] as? [String: Any]
                let options = value["projects"] as? [[String: Any]] ?? []
                guard selected?["organization"] as? String == destination.organization,
                      selected?["project"] as? String == destination.project,
                      options.contains(where: { $0["handle"] as? String == destination.project }) else {
                    navigation.reject(String(localized: "This workspace is unavailable or you no longer have access to it."))
                    return
                }
                // A draft may have appeared while workspace authorization was loading.
                guard !navigation.hasProtectedWork else {
                    navigation.reject(String(localized: "Finish or discard your conversation draft before opening another destination."))
                    return
                }
                organizations = value["organizations"] as? [[String: Any]] ?? []
                selectWorkspace(value, project: destination.project!, fromNavigation: true)
            }
            guard navigation.isCurrent(revision) else { return }
            navigation.activate(destination)
            tab = destination.screen.tab
        } catch is CancellationError { }
        catch {
            guard context == projectContext, navigation.isCurrent(revision) else { return }
            reportCredentialFailure(error)
            if self.server != nil { navigation.reject(error.localizedDescription, discard: false) }
        }
    }

    func signOut(resetRegistration: Bool = false) async {
        guard !busy else { return }
        push.prepareForSessionEnd()
        navigation.reset()
        busy = true
        defer { busy = false }
        do { _ = try await run(["operation": resetRegistration ? "reset_sign_in" : "sign_out"]) }
        catch { report(error); return }
        // Keep sign-out retryable if secure storage refuses to remove the session.
        identity = UUID()
        server = nil
        appearanceServer = "https://glossia.ai"
        organizations = []; projects = []; organization = nil; project = nil
        errorMessage = nil; tab = "toki"
        UserDefaults.standard.removeObject(forKey: "glossia.selection")
    }

    private func report(_ error: Error) {
        errorMessage = error.localizedDescription
        reportCredentialFailure(error)
    }

    private func reportCredentialFailure(_ error: Error) {
        if let failure = error as? GlossiaFailure, ["rejected", "sign_in_required"].contains(failure.kind) {
            push.prepareForSessionEnd()
            identity = UUID(); server = nil
            navigation.reset()
            appearanceServer = "https://glossia.ai"
            organizations = []; projects = []; organization = nil; project = nil; busy = false
            UserDefaults.standard.removeObject(forKey: "glossia.selection")
        }
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows).first(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }

    private func authenticate(_ url: URL) async throws -> URL? {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "glossia") { callback, error in
                if let error = error as? ASWebAuthenticationSessionError, error.code == .canceledLogin {
                    continuation.resume(returning: nil)
                } else if error != nil {
                    continuation.resume(throwing: GlossiaFailure(kind: "browser", message: String(localized: "Could not open secure sign-in.")))
                } else { continuation.resume(returning: callback) }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = true
            browser = session
            if !session.start() { continuation.resume(throwing: GlossiaFailure(kind: "browser", message: String(localized: "Could not open secure sign-in."))) }
        }
    }
}
