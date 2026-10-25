import Foundation
import Security
import SwiftUI
import UIKit
import UserNotifications

struct GlossiaPushRegistration: Codable {
    var installationID: String
    var origin: String
    var enabled: Bool
    var registrationID: String?
}

struct GlossiaPushStore {
    var read: (String) throws -> Data? = Keychain.load
    var write: (String, Any) throws -> Void = Keychain.save
    var remove: (String) throws -> Void = Keychain.delete

    func load(_ origin: String) throws -> GlossiaPushRegistration? {
        guard let data = try read("push:" + origin) else { return nil }
        let saved = try JSONDecoder().decode(GlossiaPushRegistration.self, from: data)
        guard saved.origin == origin else { throw CocoaError(.coderReadCorrupt) }
        return saved
    }

    func save(_ saved: GlossiaPushRegistration) throws {
        try write("push:" + saved.origin, JSONSerialization.jsonObject(with: JSONEncoder().encode(saved)))
    }

    func delete(_ origin: String) throws { try remove("push:" + origin) }

    // This durable tombstone is written before removing OAuth credentials.
    func disable(_ origin: String) throws -> GlossiaPushRegistration? {
        guard var saved = try load(origin) else { return nil }
        saved.enabled = false
        try save(saved)
        return saved
    }
}

enum GlossiaPushPayload {
    static func destination(_ payload: [AnyHashable: Any], origin: String,
                            saved: GlossiaPushRegistration?) -> URL? {
        guard payload["v"] as? String == "1", let saved, saved.enabled,
              saved.origin == origin, saved.registrationID == saved.installationID,
              payload["registration_id"] as? String == saved.installationID,
              let value = payload["url"] as? String, value.utf8.count <= 2048,
              let url = URL(string: value), let target = try? GlossiaDestination.parse(url),
              [.translation, .conversation].contains(target.screen),
              let server = try? GlossiaDestination(screen: .profile, server: origin).validated().server,
              target.server == server else { return nil }
        return url
    }

    static func destination(_ payload: [AnyHashable: Any]) -> URL? {
        guard let data = try? Keychain.load("session"),
              let session = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let registration = session["registration"] as? [String: Any],
              let origin = registration["server"] as? String else { return nil }
        return destination(payload, origin: origin, saved: try? GlossiaPushStore().load(origin))
    }
}

@MainActor
final class GlossiaPushDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, ObservableObject {
    @Published var token: String?
    @Published var destination: URL?
    @Published var registrationFailed = false

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken value: Data) {
        token = value.map { String(format: "%02x", $0) }.joined()
        registrationFailed = false
    }

    func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError _: Error) {
        registrationFailed = true
    }

    nonisolated func userNotificationCenter(_: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
        withCompletionHandler completion: @escaping () -> Void) {
        let url = response.actionIdentifier == UNNotificationDefaultActionIdentifier
            ? GlossiaPushPayload.destination(response.notification.request.content.userInfo) : nil
        Task { @MainActor in
            if let url { self.destination = url }
            completion()
        }
    }

    nonisolated func userNotificationCenter(_: UNUserNotificationCenter, willPresent _: UNNotification,
        withCompletionHandler completion: @escaping (UNNotificationPresentationOptions) -> Void) {
        completion([]) // Current foreground views already show work; never interrupt a draft.
    }
}

@MainActor
final class GlossiaPushNotifications: ObservableObject {
    @Published private(set) var enabled = false
    @Published private(set) var busy = false
    @Published private(set) var message: String?
    private var origin: String?
    private var request: GlossiaRequest?
    private var token: String?
    private var generation = UUID()
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private let store: GlossiaPushStore
    private let environment: () -> String?
    private let authorize: () async throws -> Bool
    private let allowed: () async -> Bool
    private let register: @MainActor () -> Void
    private let unregister: @MainActor () -> Void

    init(store: GlossiaPushStore = GlossiaPushStore(),
         environment: @escaping () -> String? = GlossiaPushNotifications.signedEnvironment,
         authorize: @escaping () async throws -> Bool = {
             try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
         }, allowed: @escaping () async -> Bool = {
             let settings = await UNUserNotificationCenter.current().notificationSettings()
             return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
         }, register: @escaping @MainActor () -> Void = { UIApplication.shared.registerForRemoteNotifications() },
         unregister: @escaping @MainActor () -> Void = {
             UIApplication.shared.unregisterForRemoteNotifications()
             UNUserNotificationCenter.current().removeAllDeliveredNotifications()
         }) {
        self.store = store; self.environment = environment; self.authorize = authorize; self.allowed = allowed
        self.register = register; self.unregister = unregister
    }

    // distribution/push.sh derives this value and aps-environment together from
    // the provisioning profile before signing. Unsigned/dev builds omit it.
    nonisolated static func signedEnvironment() -> String? {
        guard Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision") != nil,
              let value = Bundle.main.object(forInfoDictionaryKey: "GlossiaPushEnvironment") as? String else { return nil }
        switch value { case "development": return "sandbox"; case "production": return "production"; default: return nil }
    }

    func configure(origin: String?, request: GlossiaRequest?) async {
        guard self.origin != origin else { return }
        prepareForSessionEnd()
        self.origin = origin; self.request = request; message = nil
        guard let origin, request != nil else { return }
        do {
            if let saved = try store.load(origin) {
                enabled = saved.enabled
                if !enabled { await disable(); return }
            }
        } catch { message = String(localized: "Could not read secure notification settings.") }
        await refresh()
    }

    func enable() async {
        let queued = generation
        await acquire(); defer { release() }
        guard queued == generation else { return }
        guard let origin, request != nil else { return }
        guard environment() != nil else { message = String(localized: "Push notifications are not configured in this signed build."); return }
        let ticket = generation
        do {
            let granted = try await authorize()
            guard generation == ticket else { return }
            guard granted else { message = String(localized: "Allow Glossia notifications in iOS Settings to enable alerts."); return }
            if let saved = try store.load(origin), !saved.enabled {
                try await cleanup(saved, ticket: ticket)
                guard generation == ticket else { return }
            }
            if try store.load(origin) == nil {
                try store.save(GlossiaPushRegistration(installationID: UUID().uuidString.lowercased(), origin: origin, enabled: true))
            }
            enabled = true; message = String(localized: "Connecting this device…"); register()
        } catch { if generation == ticket { message = error.localizedDescription } }
    }

    func refresh(token: String? = nil) async {
        if let token { self.token = token } else if enabled { register() }
        let queued = generation
        await acquire(); defer { release() }
        guard queued == generation else { return }
        guard let origin, let request else { return }
        let ticket = generation
        do {
            guard var saved = try store.load(origin) else { return }
            if !saved.enabled { enabled = false; try await cleanup(saved, ticket: ticket); return }
            guard environment() != nil else { enabled = false; message = String(localized: "Push notifications are not configured in this signed build."); return }
            let permitted = await allowed()
            guard ticket == generation else { return }
            guard permitted else { await disableLocked(); return }
            enabled = true
            guard let token = self.token, let environment = environment() else { register(); return }
            do {
                try await enroll(saved, request: request, token: token, environment: environment)
            } catch let failure as GlossiaFailure where failure.kind == "conflict" {
                guard ticket == generation else { return }
                // Provider-invalidated IDs are retired forever. Preserve explicit
                // opt-in, but acknowledge cleanup before replacing the identity.
                enabled = false
                _ = try store.disable(origin)
                try await cleanup(saved, ticket: ticket)
                guard ticket == generation else { return }
                saved = GlossiaPushRegistration(installationID: UUID().uuidString.lowercased(), origin: origin, enabled: true)
                try store.save(saved)
                enabled = true
                try await enroll(saved, request: request, token: token, environment: environment)
            }
            guard ticket == generation else { return }
            saved.registrationID = saved.installationID
            try store.save(saved); message = nil
        } catch { if ticket == generation { message = String(localized: "Could not sync notifications. Retry by returning to Glossia. \(error.localizedDescription)") } }
    }

    private func enroll(_ saved: GlossiaPushRegistration, request: GlossiaRequest, token: String, environment: String) async throws {
        let response = try await request(["operation": "push", "action": "register", "installation_id": saved.installationID,
                                          "platform": "ios", "token": token, "environment": environment])
        guard response["registration_id"] as? String == saved.installationID else { throw CocoaError(.coderReadCorrupt) }
    }

    func disable() async {
        let queued = generation
        await acquire(); defer { release() }
        guard queued == generation else { return }
        await disableLocked()
    }

    private func disableLocked() async {
        enabled = false; unregister()
        guard let origin else { return }
        let ticket = generation
        do {
            if let saved = try store.disable(origin) { try await cleanup(saved, ticket: ticket) }
        } catch { if ticket == generation { message = String(localized: "Notifications are off locally. Server cleanup will retry when connected.") } }
    }

    private func cleanup(_ saved: GlossiaPushRegistration, ticket: UUID) async throws {
        guard let request else { return }
        _ = try await request(["operation": "push", "action": "unregister", "installation_id": saved.installationID])
        guard generation == ticket else { return }
        try store.delete(saved.origin); message = nil
    }

    // Fence callbacks and repeat the tombstone on MainActor, covering a reply
    // already delivered by the runtime before another request invalidated it.
    // The credential runtime also requires this write before deleting credentials.
    func prepareForSessionEnd() {
        generation = UUID(); enabled = false
        if let origin { _ = try? store.disable(origin) }
        origin = nil; request = nil; token = nil
        unregister()
    }

    func registrationFailed() { if enabled { message = String(localized: "iOS could not register. Check your connection and signed build.") } }

    private func acquire() async {
        if busy { await withCheckedContinuation { waiters.append($0) } } else { busy = true }
    }
    private func release() {
        if waiters.isEmpty { busy = false } else { waiters.removeFirst().resume() }
    }
}

struct GlossiaPushSettingsView: View {
    @ObservedObject var notifications: GlossiaPushNotifications
    var body: some View {
        Section {
            Toggle("Push notifications", isOn: Binding(get: { notifications.enabled }, set: { enabled in
                Task { if enabled { await notifications.enable() } else { await notifications.disable() } }
            })).disabled(notifications.busy)
            if let message = notifications.message { Text(message).font(.footnote).foregroundStyle(.secondary) }
        } header: { Text("Notifications") } footer: {
            Text("Get an alert when translations or Toki need your attention. Alerts never include private content. Optional; turn off anytime.")
        }
    }
}
