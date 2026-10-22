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

private enum Keychain {
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
        GlossiaFailure(kind: "storage", message: "Could not access secure storage. Try again.")
    }
}

// Synchronous actor methods serialize refresh, persistence and requests off the UI thread.
// Data, not untyped dictionaries or pointers, crosses the actor boundary.
actor GlossiaRuntime {
    func run(_ input: Data, authenticated: Bool = false) throws -> Data {
        try Task.checkCancellation()
        var request = try JSONSerialization.jsonObject(with: input) as! [String: Any]
        let operation = request["operation"] as? String
        do {
            if operation == "sign_out" || operation == "reset_sign_in" {
                if operation == "reset_sign_in" { try Keychain.delete("registration") }
                try Keychain.delete("session")
                return Data("{}".utf8)
            }
            if operation == "begin", let saved = try Keychain.load("registration") {
                request["registration"] = try JSONSerialization.jsonObject(with: saved)
            }
            if authenticated || operation == "restore" {
                guard let saved = try Keychain.load("session") else {
                    throw GlossiaFailure(kind: "sign_in_required", message: "Sign in to Glossia.")
                }
                let session = try command(["operation": "restore", "session": JSONSerialization.jsonObject(with: saved)])
                // Save refresh rotation before any following API request can fail.
                try Keychain.save("session", session)
                if operation == "restore" { return try JSONSerialization.data(withJSONObject: session) }
                try Task.checkCancellation()
                request["session"] = session
            }
            let result = try command(request)
            if operation == "begin", let registration = result["registration"] {
                try Keychain.save("registration", registration)
            }
            if operation == "complete" { try Keychain.save("session", result) }
            return try JSONSerialization.data(withJSONObject: result)
        } catch let failure as GlossiaFailure {
            if failure.kind == "rejected" || failure.kind == "sign_in_required" {
                try Keychain.delete("session")
                if failure.kind == "rejected" { try Keychain.delete("registration") }
            }
            throw failure
        }
    }

    private func command(_ request: [String: Any]) throws -> [String: Any] {
        let input = String(decoding: try JSONSerialization.data(withJSONObject: request), as: UTF8.self)
        return try input.withCString { pointer in
            guard let output = glossia_core_execute(pointer) else {
                throw GlossiaFailure(kind: "internal", message: "Could not complete the request.")
            }
            defer { glossia_core_free(output) }
            let result = try JSONSerialization.jsonObject(with: Data(String(cString: output).utf8)) as! [String: Any]
            if let failure = result["error"] as? [String: String] {
                throw GlossiaFailure(kind: failure["kind"] ?? "internal", message: failure["message"] ?? "Request failed.")
            }
            guard let value = result["ok"] as? [String: Any] else {
                throw GlossiaFailure(kind: "invalid_response", message: "Glossia returned an invalid response.")
            }
            return value
        }
    }
}

@MainActor
final class GlossiaSession: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    @Published var server: String?
    @Published var busy = false
    @Published var restoring = true
    @Published var errorMessage: String?
    @Published var organizations: [[String: Any]] = []
    @Published var projects: [[String: Any]] = []
    @Published var organization: String?
    @Published var project: String?
    @Published var resource: [String: Any]?
    @Published var resourceError: String?
    @Published var resourceBusy = false
    @Published var tab = "Overview"

    private let runtime = GlossiaRuntime()
    private var browser: ASWebAuthenticationSession?
    private var identity = UUID()
    private var resourceIdentity = UUID()
    private var resourceTask: Task<Data, Error>?
    var selection: [String: Any] { ["organization": organization as Any? ?? NSNull(), "project": project as Any? ?? NSNull()] }
    var contextID: String { "\(organization ?? "")/\(project ?? "")/\(tab)" }
    var selectedProject: [String: Any]? { projects.first { $0["handle"] as? String == project } }

    private func run(_ value: [String: Any], authenticated: Bool = false) async throws -> [String: Any] {
        let data = try JSONSerialization.data(withJSONObject: value)
        let result = try await runtime.run(data, authenticated: authenticated)
        return try JSONSerialization.jsonObject(with: result) as! [String: Any]
    }

    func restore() async {
        guard restoring else { return }
        defer { restoring = false }
        let identity = identity
        do {
            let session = try await run(["operation": "restore"])
            guard identity == self.identity else { return }
            server = (session["registration"] as? [String: Any])?["server"] as? String
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
        busy = true
        errorMessage = nil
        defer { busy = false; browser = nil }
        let identity = identity
        do {
            let login = try await run(["operation": "begin", "server": address])
            guard let urlString = login["authorization_url"] as? String, let url = URL(string: urlString),
                  let pending = login["pending"] else { throw GlossiaFailure(kind: "invalid_response", message: "Invalid sign-in response.") }
            guard let callback = try await authenticate(url) else { return }
            let session = try await run(["operation": "complete", "pending": pending, "callback": callback.absoluteString])
            guard identity == self.identity else { return }
            server = (session["registration"] as? [String: Any])?["server"] as? String
            busy = false
            await reload()
        } catch { report(error) }
    }

    func reload() async {
        guard !busy, server != nil else { return }
        busy = true
        errorMessage = nil
        cancelResource()
        resource = nil
        let identity = identity
        defer { if identity == self.identity { busy = false } }
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

    func selectOrganization(_ handle: String) async {
        guard !busy else { return }
        organization = handle
        project = nil
        projects = []
        await reload()
    }

    func selectProject(_ handle: String) {
        project = handle
        cancelResource()
        resource = nil
        UserDefaults.standard.set(try? JSONSerialization.data(withJSONObject: selection), forKey: "glossia.selection")
    }

    private func cancelResource() {
        resourceTask?.cancel()
        resourceTask = nil
        resourceIdentity = UUID()
        resourceBusy = false
    }

    func loadResource() async {
        guard !Task.isCancelled, !busy, organization != nil, tab == "Voice" || tab == "Glossary" else { return }
        cancelResource()
        let ticket = resourceIdentity
        resourceBusy = true
        resourceError = nil
        resource = nil
        let name = tab.lowercased()
        defer {
            if resourceIdentity == ticket { resourceTask = nil; resourceBusy = false }
        }
        do {
            let input = try JSONSerialization.data(withJSONObject: ["operation": "resource", "selection": selection, "resource": name])
            let task = Task { [runtime] in try await runtime.run(input, authenticated: true) }
            resourceTask = task
            let data = try await withTaskCancellationHandler {
                try await task.value
            } onCancel: { task.cancel() }
            try Task.checkCancellation()
            guard resourceIdentity == ticket else { return }
            let value = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            resource = value[name] as? [String: Any]
        } catch is CancellationError {
            // Superseded and signed-out requests must not become visible errors.
        } catch {
            guard resourceIdentity == ticket else { return }
            resourceError = error.localizedDescription
            reportCredentialFailure(error)
        }
    }

    func signOut(resetRegistration: Bool = false) async {
        guard !busy else { return }
        cancelResource()
        busy = true
        defer { busy = false }
        do { _ = try await run(["operation": resetRegistration ? "reset_sign_in" : "sign_out"]) }
        catch { report(error); return }
        // Keep sign-out retryable if secure storage refuses to remove the session.
        identity = UUID()
        resourceIdentity = UUID()
        server = nil
        organizations = []; projects = []; organization = nil; project = nil
        resource = nil; resourceError = nil; resourceBusy = false; errorMessage = nil; tab = "Overview"
        UserDefaults.standard.removeObject(forKey: "glossia.selection")
    }

    private func report(_ error: Error) {
        errorMessage = error.localizedDescription
        reportCredentialFailure(error)
    }

    private func reportCredentialFailure(_ error: Error) {
        if let failure = error as? GlossiaFailure, ["rejected", "sign_in_required"].contains(failure.kind) {
            identity = UUID(); cancelResource(); server = nil; resource = nil
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
                    continuation.resume(throwing: GlossiaFailure(kind: "browser", message: "Could not open secure sign-in."))
                } else { continuation.resume(returning: callback) }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = true
            browser = session
            if !session.start() { continuation.resume(throwing: GlossiaFailure(kind: "browser", message: "Could not open secure sign-in.")) }
        }
    }
}
