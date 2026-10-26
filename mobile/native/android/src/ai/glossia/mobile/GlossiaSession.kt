package ai.glossia.mobile

import android.app.Application
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import android.util.JsonReader
import org.json.JSONArray
import org.json.JSONObject
import java.math.BigInteger
import java.security.KeyStore
import java.util.concurrent.ArrayBlockingQueue
import java.util.concurrent.Executors
import java.util.concurrent.ThreadPoolExecutor
import java.util.concurrent.TimeUnit
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

object GlossiaCore {
    init { System.loadLibrary("glossia_core") }
    external fun execute(input: String): String
}

class GlossiaApplication : Application() {
    val session by lazy { GlossiaSession(applicationContext) }
    override fun onCreate() { super.onCreate(); GlossiaFirebase.initialize(this) }
}

internal class Failure(val kind: String, message: String) : Exception(message)

internal interface CredentialStorage {
    fun load(name: String): JSONObject?
    fun save(name: String, value: JSONObject)
    fun delete(name: String)
}

internal class SecureStorage(context: Context) : CredentialStorage {
    private val preferences = context.getSharedPreferences("glossia.oauth", Context.MODE_PRIVATE)
    private val alias = "ai.glossia.mobile.oauth"

    private fun key(): SecretKey = synchronized(keyLock) {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (store.getKey(alias, null) as? SecretKey)?.let { return it }
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore").run {
            init(KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM).setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE).build())
            generateKey()
        }
    }

    override fun load(name: String): JSONObject? {
        val stored = preferences.getString(name, null) ?: return null
        val envelope = JSONObject(stored)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, Base64.decode(envelope.getString("iv"), Base64.NO_WRAP)))
        cipher.updateAAD(name.toByteArray(Charsets.UTF_8))
        return JSONObject(String(cipher.doFinal(Base64.decode(envelope.getString("data"), Base64.NO_WRAP)), Charsets.UTF_8))
    }

    override fun save(name: String, value: JSONObject) {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key())
        cipher.updateAAD(name.toByteArray(Charsets.UTF_8))
        val envelope = JSONObject().put("iv", Base64.encodeToString(cipher.iv, Base64.NO_WRAP))
            .put("data", Base64.encodeToString(cipher.doFinal(value.toString().toByteArray(Charsets.UTF_8)), Base64.NO_WRAP))
        check(preferences.edit().putString(name, envelope.toString()).commit())
    }

    override fun delete(name: String) { check(preferences.edit().remove(name).commit()) }

    companion object { private val keyLock = Any() }
}

// Application-owned models survive rotation. Only credential rotation and durable
// storage use the serial executor; feature network requests run on a bounded pool.
class GlossiaSession internal constructor(context: Context,
    private val storage: CredentialStorage = SecureStorage(context.applicationContext),
    private val bridge: (String) -> String = { GlossiaCore.execute(it) }) {
    private val context = context.applicationContext
    val appearance = GlossiaAppearance(context, bridge)
    val push = GlossiaPushNotifications(context.applicationContext, storage, ::pushRequest).apply {
        listener = { this@GlossiaSession.listener?.invoke() }
    }
    private val preferences = context.getSharedPreferences("glossia.workspace", Context.MODE_PRIVATE)
    private val credentials = Executors.newSingleThreadExecutor()
    private val requests = ThreadPoolExecutor(4, 4, 30, TimeUnit.SECONDS, ArrayBlockingQueue(32))
    // Local next waits can last 30 seconds. Neither they nor close may queue
    // behind credential rotation, feature traffic, or another connection's wait.
    private val translationLive = Executors.newCachedThreadPool()
    private val main = Handler(Looper.getMainLooper())
    @Volatile
    private var generation = 0
    @Volatile
    private var scopeGeneration = 0
    private var credentialRevision = 0L // Accessed only on the credential executor.
    private var workspaceTicket = 0
    private var started = false
    var listener: (() -> Unit)? = null
    var authorizationURL: String? = null
    var server: String? = null
        private set
    var busy = false
        private set
    var error: String? = null
        private set
    var organizations = JSONArray()
        private set
    var projects = JSONArray()
        private set
    var organization: String? = null
        private set
    var project: String? = null
        private set
    var tab = "Toki"
        private set
    val translations = PageModel("translations", "sessions")
    val translation = TranslationModel()
    @Volatile
    private var liveTicket = 0
    private var liveId: String? = null
    private var liveConnection: Any? = null
    private var liveOpening = false
    private var liveAfter = BigInteger.ZERO
    private var liveReauthenticated = false
    private var liveRetry: Runnable? = null
    private val unavailableTranslations = mutableSetOf<String>()
    val analytics = AnalyticsModel()
    val profile = FeatureModel()
    val fluentLanguages = FluentLanguagesModel()
    val toki = TokiModel { context.nativeText(it).toString() }
    private val tokiNotifications = TokiNotifications(context.applicationContext,
        { appearance.color(context, R.color.glossia_primary) ?: context.token(R.color.glossia_primary) }, ::tokiNotificationLink)
    val workspacePicker = WorkspacePickerModel()
    private var foreground = false
    private val poll = Runnable { pollConversation() }
    private var deferredCallback: String? = null
    private var workspaceReady = false
    private var navigationTicket = 0
    private var resolvingNavigation = false
    var pendingDestination: GlossiaDestination? = null
        private set
    var navigationNotice: String? = null
        private set
    val selection: JSONObject
        get() = JSONObject().put("organization", organization ?: JSONObject.NULL).put("project", project ?: JSONObject.NULL)

    private fun command(value: JSONObject): JSONObject {
        val envelope = JSONObject(bridge(value.toString()))
        envelope.optJSONObject("error")?.let { throw Failure(it.getString("kind"), it.getString("message")) }
        return envelope.getJSONObject("ok")
    }

    private fun snapshot(ticket: Int): JSONObject {
        check(ticket == generation)
        val saved = storage.load("session") ?: throw Failure("sign_in_required", context.nativeText("Sign in to Glossia again.").toString())
        val session = command(JSONObject().put("operation", "restore").put("session", saved))
        check(ticket == generation)
        storage.save("session", session) // Commit rotated credentials even if the API fails.
        if (saved.toString() != session.toString()) credentialRevision += 1
        return session
    }

    private fun message(error: Throwable): String = when (error) {
        is Failure -> error.message ?: context.nativeText("Request failed.").toString()
        is java.util.concurrent.RejectedExecutionException -> context.nativeText("Too many requests. Please try again.").toString()
        else -> context.nativeText("Could not complete the request securely. Please try again.").toString()
    }

    // Executed on the credential executor. A late response may never delete a
    // replacement session, or credentials rotated after that response's snapshot.
    private fun reject(error: Throwable, ticket: Int, revision: Long = credentialRevision): Boolean {
        if (ticket != generation || revision != credentialRevision || error !is Failure ||
            error.kind !in listOf("rejected", "sign_in_required")) return false
        endPushSession()
        storage.delete("session")
        storage.delete("pending")
        if (error.kind == "rejected") storage.delete("registration")
        return true
    }

    private fun credentialWork(action: () -> JSONObject?, completion: (JSONObject?) -> Unit) {
        if (busy) return
        busy = true; error = null
        val ticket = generation
        listener?.invoke()
        credentials.execute {
            val result = runCatching { action() }
            val invalid = result.exceptionOrNull()?.let { runCatching { reject(it, ticket) }.getOrDefault(false) } ?: false
            main.post {
                if (ticket == generation) {
                    if (invalid) reset()
                    busy = false
                    if (result.isSuccess) completion(result.getOrNull()) else error = message(result.exceptionOrNull()!!)
                    listener?.invoke()
                    deferredCallback?.let { deferredCallback = null; callback(it) }
                    resolveNavigation()
                }
            }
        }
    }

    fun restore() {
        if (started) return
        started = true
        appearance.configure(server ?: "https://glossia.ai")
        val ticket = generation
        credentialWork({
            if (storage.load("session") == null) null else snapshot(ticket)
        }) { session ->
            if (session != null) {
                clearFeatures()
                server = session.getJSONObject("registration").getString("server")
                val saved = JSONObject(preferences.getString("selection", "{}") ?: "{}")
                organization = saved.optionalString("organization"); project = saved.optionalString("project")
                appearance.configure(server!!)
                push.configure(server)
                reload()
            }
        }
    }

    fun retryRestore() { started = false; restore() }

    fun signIn(address: String) {
        if (busy) return
        appearance.configure(address)
        val ticket = generation
        credentialWork({
            val request = JSONObject().put("operation", "begin").put("server", address)
            storage.load("registration")?.let { request.put("registration", it) }
            command(request).also {
                check(ticket == generation)
                storage.save("registration", it.getJSONObject("registration"))
                storage.save("pending", it.getJSONObject("pending"))
            }
        }) { login -> authorizationURL = login?.getString("authorization_url") }
    }

    fun callback(url: String) {
        if (busy) { deferredCallback = url; return }
        val ticket = generation
        credentialWork({
            val pending = storage.load("pending") ?: throw Failure("callback", context.nativeText("No sign-in is waiting. Start a new sign-in.").toString())
            try {
                command(JSONObject().put("operation", "validate_callback").put("pending", pending).put("callback", url))
            } catch (failure: Failure) {
                if (failure.kind == "denied") storage.delete("pending")
                throw failure
            }
            // Only a matching callback may consume this grant, before exchanging its code.
            storage.delete("pending") // A callback is consumed once, including across process death.
            command(JSONObject().put("operation", "complete").put("pending", pending).put("callback", url))
                .also { check(ticket == generation); storage.save("session", it); credentialRevision += 1 }
        }) { session ->
            clearFeatures()
            server = session?.getJSONObject("registration")?.getString("server")
            server?.let(appearance::configure)
            push.configure(server)
            reload()
        }
    }

    fun reload() {
        if (server == null) return
        workspaceTicket += 1
        val ticket = workspaceTicket
        val desired = selection
        busy = true; error = null; workspaceReady = false
        request(JSONObject().put("operation", "workspace").put("selection", desired)) { result, failure ->
            if (ticket != workspaceTicket) return@request
            busy = false
            error = failure?.let(::message)
            if (result != null) {
                organizations = result.getJSONArray("organizations"); projects = result.getJSONArray("projects")
                val resolved = result.getJSONObject("selection")
                if (organization != resolved.optionalString("organization") || project != resolved.optionalString("project")) {
                    if (protectWork()) {
                        error = context.nativeText("The workspace changed. Finish your Toki draft or unconfirmed message before reloading.").toString()
                        return@request
                    }
                    clearFeatures()
                }
                organization = resolved.optionalString("organization")
                project = resolved.optionalString("project")
                preferences.edit().putString("selection", selection.toString()).apply()
                workspaceReady = true
                loadCurrent()
                resolveNavigation()
            }
        }
        changed()
    }

    fun openWorkspacePicker() {
        if (server == null) return
        cancelNavigation()
        workspacePicker.clear()
        workspacePicker.open = true
        workspacePicker.organization = organization
        workspacePicker.projects = projects
        workspacePicker.loaded = true
        changed()
    }

    fun closeWorkspacePicker() { workspacePicker.clear(); changed() }

    fun browseOrganization(handle: String) {
        if (!workspacePicker.open || server == null) return
        val ticket = ++workspacePicker.ticket
        workspacePicker.organization = handle
        workspacePicker.projects = JSONArray(); workspacePicker.search = ""
        workspacePicker.busy = true; workspacePicker.error = null
        // This is a preview, not a global selection mutation. The explicit
        // candidate selection must pass through unchanged to Rust.
        val candidate = JSONObject().put("organization", handle).put("project", JSONObject.NULL)
        request(JSONObject().put("operation", "workspace").put("selection", candidate)) { result, failure ->
            if (!workspacePicker.open || ticket != workspacePicker.ticket) return@request
            workspacePicker.busy = false; workspacePicker.error = failure?.let(::message)
            if (result != null) {
                if (result.optJSONObject("selection")?.optionalString("organization") == handle) {
                    workspacePicker.projects = result.getJSONArray("projects")
                    workspacePicker.loaded = true
                } else workspacePicker.error = context.nativeText("This organization is no longer available. Choose another organization.").toString()
            }
        }
        changed()
    }

    fun selectWorkspaceProject(handle: String) {
        val candidate = workspacePicker.organization ?: return
        if (!workspacePicker.open || workspacePicker.busy || workspacePicker.error != null ||
            (0 until workspacePicker.projects.length()).none { workspacePicker.projects.getJSONObject(it).optString("handle") == handle }) return
        val candidateProjects = workspacePicker.projects
        if (organization == candidate && project == handle) { closeWorkspacePicker(); return }
        cancelNavigation()
        if (protectWork()) { closeWorkspacePicker(); return }
        // Commit organization + project together, only after an explicit project
        // choice. Cancellation and organization browsing never discard drafts.
        workspaceTicket += 1; busy = false; error = null
        clearFeatures()
        organization = candidate; project = handle; projects = candidateProjects; workspaceReady = true
        preferences.edit().putString("selection", selection.toString()).apply()
        loadCurrent()
        changed()
    }

    fun selectTab(value: String) {
        if (toki.active?.protectsDecision == true && protectWork()) { changed(); return }
        cancelNavigation()
        if (value == "Toki") toki.activeId = null
        tab = value
        loadCurrent()
        changed()
    }

    // Snapshot acquisition, including refresh, is serial. No API request occupies
    // that executor, so a slow chat does not block analytics, selection or sign-out.
    private fun request(value: JSONObject, completion: (JSONObject?, Throwable?) -> Unit) {
        val sessionTicket = generation
        val scopeTicket = scopeGeneration
        fun current() = sessionTicket == generation && scopeTicket == scopeGeneration
        fun finish(result: Result<JSONObject>, revision: Long) {
            credentials.execute {
                if (!current()) return@execute
                val invalid = result.exceptionOrNull()?.let { runCatching { reject(it, sessionTicket, revision) }.getOrDefault(false) } ?: false
                main.post {
                    if (!current()) return@post
                    if (invalid) { reset(); error = message(result.exceptionOrNull()!!); changed(); return@post }
                    completion(result.getOrNull(), result.exceptionOrNull())
                    changed()
                }
            }
        }
        credentials.execute {
            if (!current()) return@execute
            val saved = runCatching { snapshot(sessionTicket) }
            val revision = credentialRevision
            if (!current()) return@execute
            if (saved.isFailure) { finish(Result.failure(saved.exceptionOrNull()!!), revision); return@execute }
            try {
                requests.execute {
                    if (current()) {
                        val result = runCatching { command(value.put("session", saved.getOrThrow())) }
                        if (current()) finish(result, revision)
                    }
                }
            } catch (failure: java.util.concurrent.RejectedExecutionException) {
                finish(Result.failure(failure), revision)
            }
        }
    }

    // Installation enrollment is account-wide, not tied to a project generation.
    private fun pushRequest(value: JSONObject, completion: (Result<JSONObject>) -> Unit) {
        val ticket = generation
        fun finish(result: Result<JSONObject>, revision: Long) {
            credentials.execute {
                if (ticket != generation) return@execute
                val invalid = result.exceptionOrNull()?.let { runCatching { reject(it, ticket, revision) }.getOrDefault(false) } ?: false
                main.post {
                    if (ticket != generation) return@post
                    if (invalid) { reset(); error = context.nativeText("Sign in to Glossia again.").toString() }
                    completion(result); listener?.invoke()
                }
            }
        }
        credentials.execute {
            if (ticket != generation) return@execute
            val saved = runCatching { snapshot(ticket) }
            val revision = credentialRevision
            if (saved.isFailure) { finish(Result.failure(saved.exceptionOrNull()!!), revision); return@execute }
            try {
                requests.execute {
                    if (ticket == generation) finish(runCatching {
                        command(value.put("operation", "push").put("session", saved.getOrThrow()))
                    }, revision)
                }
            } catch (failure: java.util.concurrent.RejectedExecutionException) { finish(Result.failure(failure), revision) }
        }
    }

    private fun endPushSession() {
        val session = storage.load("session") ?: return
        val origin = session.optJSONObject("registration")?.optionalString("server") ?: return
        val saved = GlossiaPushStorage.disable(storage, origin) ?: return
        val payload = JSONObject().put("operation", "push").put("action", "unregister")
            .put("installation_id", saved.getString("installation_id")).put("session", session)
        // Independent from logout and project networking. The server tombstones
        // DELETEs so a late PUT from the old session cannot enroll again.
        runCatching { requests.execute { runCatching { command(payload) } } }
    }

    internal fun consumePushIntent(intent: android.content.Intent): Boolean {
        val raw = intent.getStringExtra("glossia.push") ?: return false
        intent.removeExtra("glossia.push"); intent.data = null
        if (intent.action != android.content.Intent.ACTION_VIEW ||
            intent.flags and android.content.Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0) return true
        runCatching {
            val session = storage.load("session") ?: return true
            val origin = session.getJSONObject("registration").getString("server")
            val saved = storage.load(GlossiaPushStorage.key(origin)) ?: return true
            val payload = JSONObject(raw)
            val data = payload.keys().asSequence().associateWith { payload.getString(it) }
            GlossiaPushPayload.destination(data, origin, saved) { url ->
                command(JSONObject().put("operation", "navigation").put("action", "parse").put("url", url))
                    .getJSONObject("destination").let(GlossiaDestination::fromCore)
            }?.let(::receiveLink)
        }
        return true
    }

    fun signOut(resetRegistration: Boolean = false) {
        try { server?.let { GlossiaPushStorage.disable(storage, it) } }
        catch (_: Exception) { error = context.nativeText("Could not securely disable notifications. Try signing out again.").toString(); listener?.invoke(); return }
        reset() // Fence in-flight requests immediately, not after their network calls.
        busy = true; error = null
        val ticket = generation
        credentials.execute {
            val result = runCatching {
                endPushSession()
                if (resetRegistration) storage.delete("registration")
                storage.delete("pending"); storage.delete("session")
                credentialRevision += 1
            }
            main.post {
                if (ticket == generation) {
                    busy = false; error = result.exceptionOrNull()?.let(::message); changed()
                }
            }
        }
        changed()
    }

    private fun reset() {
        push.prepareForSessionEnd()
        generation += 1; workspaceTicket += 1
        clearFeatures()
        server = null; organization = null; project = null; projects = JSONArray(); organizations = JSONArray()
        tab = "Toki"; busy = false; error = null
        deferredCallback = null; authorizationURL = null
        cancelNavigation(); navigationNotice = null; workspaceReady = false
        preferences.edit().remove("selection").apply()
        appearance.configure("https://glossia.ai")
        listener?.invoke()
    }

    private fun clearFeatures() {
        stopTranslationLive()
        tokiNotifications.clear()
        scopeGeneration += 1
        resolvingNavigation = false
        translations.clear(); translation.clear(); analytics.clear(); profile.clear(); toki.clear()
        fluentLanguages.clear()
        unavailableTranslations.clear()
        workspacePicker.clear()
        main.removeCallbacks(poll)
    }

    private fun changed() {
        reconcileTranslationLive()
        if (server != null && workspaceReady && organization != null && project != null) {
            tokiNotifications.update(toki.threads.values, if (foreground && tab == "Toki") toki.activeId else null)
        } else tokiNotifications.clear()
        listener?.invoke()
        main.removeCallbacks(poll)
        val thread = toki.active
        if (foreground && tab == "Toki" && thread != null &&
            thread.shouldPollVisible && !thread.busy && !thread.resolving && thread.error == null) main.postDelayed(poll, 2500)
    }

    fun setForeground(value: Boolean) {
        foreground = value
        push.setForeground(value)
        if (!value) toki.threads.values.forEach { it.pauseWorkObservation() }
        if (value) appearance.refresh()
        if (value) loadCurrent()
        changed()
    }

    fun takeNotificationPermissionRequest() = foreground && tokiNotifications.takePermissionRequest()
    fun refreshNotifications() { changed() }

    private fun tokiNotificationLink(id: String, completion: (String?) -> Unit) {
        val address = server ?: return
        val sessionTicket = generation
        val scopeTicket = scopeGeneration
        val destination = GlossiaDestination(GlossiaScreen.CONVERSATION, address, organization, project, id)
        try {
            requests.execute {
                val result = runCatching {
                    command(JSONObject().put("operation", "navigation").put("action", "link").put("destination", destination.json()))
                }
                main.post {
                    if (sessionTicket == generation && scopeTicket == scopeGeneration) completion(result.getOrNull()?.optionalString("url"))
                }
            }
        } catch (_: java.util.concurrent.RejectedExecutionException) { completion(null) }
    }

    fun loadCurrent(force: Boolean = false) {
        if (server == null) return
        when (tab) {
            "Toki" -> if (organization != null && project != null) {
                if (force || !toki.history.loaded) loadPage(toki.history, refresh = force)
                toki.active?.let {
                    if (it.created && (force || !it.loaded || it.shouldPollVisible || it.sharedGoal || it.workStatus in listOf("queued", "running"))) fetchConversation(it.id)
                }
            }
            "Translations" -> if (organization != null && project != null) {
                if (translation.id != null) { if (force || !translation.loaded) loadTranslation() }
                else if (force || !translations.loaded) loadPage(translations, refresh = force)
            }
            "Analytics" -> if (organization != null && project != null && (force || !analytics.loaded)) loadAnalytics()
            "Profile" -> if (force || !profile.loaded) loadProfile()
        }
    }

    fun loadPage(model: PageModel, refresh: Boolean = false) {
        if (server == null || organization == null || project == null || model.busy) return
        if (!refresh && model.loaded && !model.hasMore) return
        val page = if (refresh) 1 else model.page + 1
        model.requestedPage = page
        model.busy = true; model.error = null
        request(JSONObject().put("operation", "resource").put("selection", selection).put("resource", model.resource).put("page", page)) { result, failure ->
            model.busy = false; model.error = failure?.let(::message)
            if (result != null) {
                model.accept(result, page)
                // A history request already in flight when access was revoked
                // must not restore the denied conversation's private title.
                if (model === toki.history) toki.threads.values.filter { it.unavailable }.forEach { model.remove(it.id) }
                if (model === translations) unavailableTranslations.forEach(model::remove)
            }
        }
        changed()
    }

    fun setAnalyticsDays(days: Int) {
        if (days !in listOf(7, 30, 90) || days == analytics.days) return
        analytics.days = days
        analytics.ticket += 1; analytics.busy = false; analytics.loaded = false; analytics.data = null
        loadAnalytics()
    }

    fun loadAnalytics() {
        if (server == null || project == null || organization == null || analytics.busy) return
        val ticket = ++analytics.ticket
        analytics.busy = true; analytics.error = null
        request(JSONObject().put("operation", "resource").put("selection", selection).put("resource", "analytics").put("days", analytics.days)) { result, failure ->
            if (ticket == analytics.ticket) {
                analytics.busy = false; analytics.error = failure?.let(::message)
                if (result != null) { analytics.data = result; analytics.loaded = true }
            }
        }
        changed()
    }

    fun loadProfile() {
        if (server == null || profile.busy) return
        profile.busy = true; profile.error = null
        request(JSONObject().put("operation", "resource").put("selection", selection).put("resource", "profile")) { result, failure ->
            profile.busy = false; profile.error = failure?.let(::message)
            if (result != null) { profile.data = result; profile.loaded = true }
        }
        changed()
    }

    fun editFluentLanguages() {
        if (!profile.loaded || fluentLanguages.saving) return
        fluentLanguages.draft = profile.data?.optJSONObject("user")?.optJSONArray("fluent_languages")?.let { values ->
            (0 until values.length()).joinToString(", ") { values.getString(it) }
        }.orEmpty()
        fluentLanguages.error = null; changed()
    }

    fun discardFluentLanguages() { if (!fluentLanguages.saving) { fluentLanguages.clear(); changed() } }

    fun saveFluentLanguages() {
        if (fluentLanguages.draft == null || fluentLanguages.saving) return
        fluentLanguages.saving = true; fluentLanguages.error = null
        request(JSONObject().put("operation", "fluent_languages").put("fluent_languages", JSONArray(fluentLanguages.languages))) { result, failure ->
            fluentLanguages.saving = false
            if (result?.optJSONObject("user")?.optJSONArray("fluent_languages") != null) {
                profile.data = result; profile.loaded = true; fluentLanguages.clear()
            } else fluentLanguages.error = failure?.let(::message) ?: context.nativeText("Could not confirm fluent languages. Your draft is unchanged.").toString()
        }
        changed()
    }

    fun receiveLink(url: String) {
        beginNavigation(JSONObject().put("operation", "navigation").put("action", "parse").put("url", url))
    }

    fun navigate(destination: GlossiaDestination) {
        beginNavigation(JSONObject().put("operation", "navigation").put("action", "link").put("destination", destination.json()))
    }

    private fun beginNavigation(command: JSONObject) {
        cancelNavigation(); navigationNotice = null
        val ticket = navigationTicket
        navigationWork(ticket, command) { result ->
            if (result == null) navigationNotice = context.nativeText("This Glossia link is invalid or unsupported.").toString()
            else {
                pendingDestination = GlossiaDestination.fromCore(result.getJSONObject("destination"))
                resolveNavigation()
            }
            changed()
        }
    }

    // Parsing/building is local core work, not an authenticated request and not
    // credential work. It can finish while restore/login is still in progress.
    private fun navigationWork(ticket: Int, value: JSONObject, completion: (JSONObject?) -> Unit) {
        val sessionTicket = generation
        try {
            requests.execute {
                val result = runCatching { command(value) }
                main.post {
                    if (ticket == navigationTicket && sessionTicket == generation) completion(result.getOrNull())
                }
            }
        } catch (_: java.util.concurrent.RejectedExecutionException) {
            completion(null)
        }
    }

    fun retryNavigation() {
        if (pendingDestination == null) return
        if (!workspaceReady) reload() else resolveNavigation()
    }

    fun dismissNavigationNotice() { navigationNotice = null; changed() }

    private fun cancelNavigation() {
        navigationTicket += 1; pendingDestination = null; resolvingNavigation = false
    }

    private fun protectedThreads() = toki.threads.values.filter { it.protectsDecision || it.draft.isNotEmpty() || it.pending != null || it.busy && !it.created }
    val hasProtectedWork get() = protectedThreads().isNotEmpty() || fluentLanguages.protectsDraft

    fun resumeUnsentWork() {
        if (fluentLanguages.protectsDraft) { cancelNavigation(); tab = "Profile"; navigationNotice = null; changed(); return }
        val thread = protectedThreads().firstOrNull() ?: return
        cancelNavigation(); navigationNotice = null
        tab = "Toki"; toki.activeId = thread.id
        changed()
    }

    // Explicitly discard only local work. An ambiguous send might already have
    // reached the server; this is not a cancellation or a server-side deletion.
    fun discardUnsentWork() {
        if (fluentLanguages.saving || toki.threads.values.any { it.resolving }) {
            navigationNotice = context.nativeText("A decision is being saved. Wait for the result before leaving.").toString(); changed(); return
        }
        cancelNavigation()
        fluentLanguages.clear()
        protectedThreads().forEach { thread ->
            val hadPending = thread.pending != null
            thread.writeTicket += 1; thread.draft = ""; thread.pending = null; thread.discardDecision()
            if (!thread.created) {
                thread.clear(); toki.threads.remove(thread.id)
                if (toki.activeId == thread.id) toki.activeId = null
            } else if (hadPending) {
                thread.busy = false; thread.error = null; thread.loaded = false
            }
        }
        navigationNotice = context.nativeText("Local unsent work discarded. A message already received by the server may still complete. Open the link again when ready.").toString()
        changed()
    }

    private fun protectWork(): Boolean {
        if (!hasProtectedWork) return false
        workspacePicker.clear() // A blocking notice must not sit behind a modal.
        navigationNotice = context.nativeText("Your draft or unconfirmed reply is safe. Return to finish it, or explicitly discard local unsent work, then open the link again.").toString()
        return true
    }

    private fun resolveNavigation() {
        val destination = pendingDestination ?: return
        val address = server ?: return
        if (!workspaceReady || busy || resolvingNavigation) return
        resolvingNavigation = true
        val ticket = navigationTicket
        val scopeTicket = scopeGeneration
        // Normalize the authenticated origin through the same Rust contract as
        // the destination. Theme-origin formatting is deliberately not reused.
        navigationWork(ticket, JSONObject().put("operation", "navigation").put("action", "link")
            .put("destination", GlossiaDestination(GlossiaScreen.PROFILE, address).json())) { result ->
            if (scopeTicket != scopeGeneration) return@navigationWork
            if (server != address || !workspaceReady || busy) {
                resolvingNavigation = false
                return@navigationWork // Restore/login or reload will resolve again when ready.
            }
            if (result == null || result.getJSONObject("destination").getString("server") != destination.server) {
                cancelNavigation()
                navigationNotice = context.nativeFormat("This link belongs to a different Glossia server. Sign out, sign in to %1\$s, then open the link again.", destination.server)
                changed()
            } else if (protectWork()) {
                cancelNavigation(); changed()
            } else if (destination.screen == GlossiaScreen.PROFILE) {
                applyDestination(destination)
            } else {
                val candidate = JSONObject().put("organization", destination.organization).put("project", destination.project)
                request(JSONObject().put("operation", "workspace").put("selection", candidate)) { workspace, failure ->
                    if (ticket != navigationTicket) return@request
                    resolvingNavigation = false
                    if (!workspaceReady || busy || server != address) return@request
                    if (workspace == null) {
                        navigationNotice = context.nativeFormat("Could not open the linked workspace. %1\$s", failure?.let(::message) ?: context.nativeText("Try again."))
                    } else {
                        val resolved = workspace.getJSONObject("selection")
                        fun contains(items: JSONArray, handle: String?) = (0 until items.length()).any { items.getJSONObject(it).optionalString("handle") == handle }
                        if (resolved.optionalString("organization") != destination.organization || resolved.optionalString("project") != destination.project ||
                            !contains(workspace.getJSONArray("organizations"), destination.organization) || !contains(workspace.getJSONArray("projects"), destination.project)) {
                            cancelNavigation()
                            navigationNotice = context.nativeText("The linked organization or project is not accessible. Ask a workspace administrator for access, then open the link again.").toString()
                        } else if (protectWork()) {
                            cancelNavigation()
                        } else {
                            if (organization != destination.organization || project != destination.project) {
                                workspaceTicket += 1
                                clearFeatures()
                                organization = destination.organization; project = destination.project
                                organizations = workspace.getJSONArray("organizations"); projects = workspace.getJSONArray("projects")
                                preferences.edit().putString("selection", selection.toString()).apply()
                            }
                            applyDestination(destination)
                        }
                    }
                }
            }
        }
    }

    private fun applyDestination(destination: GlossiaDestination) {
        pendingDestination = null; resolvingNavigation = false; navigationNotice = null
        workspacePicker.clear()
        tab = destination.screen.tab
        when (destination.screen) {
            GlossiaScreen.TRANSLATION -> openTranslationRecord(requireNotNull(destination.id))
            GlossiaScreen.TRANSLATIONS -> translation.clear()
            GlossiaScreen.CONVERSATION -> fetchConversation(requireNotNull(destination.id))
            GlossiaScreen.NEW_CONVERSATION -> {
                val thread = toki.newConversation(destination.translationId)
                loadSource(thread)
            }
            GlossiaScreen.TOKI -> toki.activeId = null
            else -> Unit
        }
        loadCurrent(); changed()
    }

    fun showTranslation(id: String) {
        val address = server ?: return
        navigate(GlossiaDestination(GlossiaScreen.TRANSLATION, address, organization, project, id))
    }

    fun openReviewConversation(id: String) {
        val address = server ?: return
        navigate(GlossiaDestination(GlossiaScreen.CONVERSATION, address, organization, project, id))
    }

    fun shareTranslation(share: (String) -> Unit) {
        val address = server ?: return
        val id = translation.id ?: return
        if (!translation.loaded || translation.busy || translation.error != null || translation.data == null) return
        val scopeTicket = scopeGeneration
        val recordTicket = translation.ticket
        val destination = GlossiaDestination(GlossiaScreen.TRANSLATION, address, organization, project, id)
        navigationWork(navigationTicket, JSONObject().put("operation", "navigation").put("action", "link")
            .put("destination", destination.json())) { result ->
            if (scopeTicket != scopeGeneration || recordTicket != translation.ticket || tab != "Translations") return@navigationWork
            if (result == null) {
                navigationNotice = context.nativeText("Could not create a translation link. Try sharing again.").toString()
                changed()
            } else share(result.getString("url")) // Only Rust's canonical URL, never credentials or API payloads.
        }
    }

    fun discussTranslation() {
        val address = server ?: return
        val id = translation.id ?: return
        if (!translation.loaded || translation.data == null) return
        navigate(GlossiaDestination(GlossiaScreen.NEW_CONVERSATION, address, organization, project, translationId = id))
    }

    private fun openTranslationRecord(id: String) {
        stopTranslationLive()
        translation.clear(); translation.id = id
        loadTranslation()
    }

    fun loadTranslation() {
        val id = translation.id ?: return
        if (translation.busy) return
        if (translation.liveState == "unavailable") {
            stopTranslationLive()
            liveReauthenticated = false
        }
        val ticket = ++translation.ticket
        val liveRevision = translation.liveSnapshotRevision
        translation.busy = true; translation.error = null
        request(JSONObject().put("operation", "translation").put("selection", selection).put("id", id)) { result, failure ->
            if (ticket != translation.ticket) return@request
            translation.busy = false
            if (failure is Failure && failure.kind in listOf("forbidden", "not_found")) {
                denyTranslation(id)
            }
            translation.error = when {
                failure is Failure && failure.kind in listOf("forbidden", "not_found") ->
                    context.nativeText("This translation is not available or you do not have access. Retry to check access.").toString()
                translation.liveSnapshotRevision != liveRevision -> null
                else -> failure?.let(::message)
            }
            if (result != null) {
                unavailableTranslations.remove(id)
                // Suppress an HTTP response only when a live projection arrived
                // during this request; later manual refreshes can still reconcile.
                if (translation.liveSnapshotRevision == liveRevision) {
                    translation.data = result.getJSONObject("session")
                    translation.progress = result.optJSONObject("progress")
                    translation.loaded = true
                }
                loadTranslationReviews()
            }
        }
        changed()
    }

    fun loadTranslationReviews() {
        val id = translation.id ?: return
        val model = translation.reviews
        if (model.busy || translation.data == null) return
        val ticket = ++model.ticket
        model.busy = true; model.error = null
        request(JSONObject().put("operation", "translation_reviews").put("action", "list")
            .put("selection", selection).put("id", id)) { result, failure ->
            if (ticket != model.ticket || translation.id != id) return@request
            model.busy = false
            if (failure is Failure && failure.kind in listOf("forbidden", "not_found")) {
                model.clear()
                model.error = context.nativeText("You do not have permission to view linguistic reviews.").toString()
            } else if (result != null) {
                runCatching { model.accept(result, id) }.onFailure { model.error = message(it) }
            } else model.error = failure?.let(::message)
        }
        changed()
    }

    fun saveGoalDecision() {
        val thread = toki.active ?: return
        if (!thread.canSaveDecision) return
        val goal = thread.goal ?: return
        val draft = thread.decision ?: return
        val ticket = ++thread.writeTicket
        thread.resolving = true; thread.resolutionError = null
        val payload = JSONObject().put("operation", "translation_reviews").put("action", "answer")
            .put("selection", selection).put("id", goal.getString("translation_session_id"))
            .put("review_id", goal.getString("id")).put("answer", draft.answer)
            .put("resolution_message_id", thread.resolutionMessageId)
        if (draft.reusable) payload.put("guidance", draft.guidance).put("context_scope", draft.scope)
        request(payload) { result, failure ->
            if (ticket != thread.writeTicket) return@request
            thread.resolving = false; thread.resolutionNeedsRefresh = true
            if (failure == null && result != null) {
                thread.resolutionAcknowledged = true
                fetchConversation(thread.id)
            } else {
                thread.resolutionError = context.nativeFormat("%1\$s Refresh the conversation before explicitly retrying; the decision may already be saved.", failure?.let(::message) ?: context.nativeText("Could not confirm the saved decision."))
            }
        }
        changed()
    }

    private fun liveEligible() = foreground && tab == "Translations" && translation.id != null &&
        server != null && organization != null && project != null

    private fun reconcileTranslationLive() {
        if (!liveEligible() || liveId != null && liveId != translation.id) {
            if (liveId != null || liveRetry != null) stopTranslationLive()
            return
        }
        if (!liveOpening && liveConnection == null && liveRetry == null && translation.liveState != "unavailable") {
            openTranslationLive()
        }
    }

    private fun closeTranslationHandle(connection: Any) {
        translationLive.execute {
            runCatching { command(JSONObject().put("operation", "translation_live").put("action", "close").put("connection", connection)) }
        }
    }

    private fun stopTranslationLive() {
        liveTicket += 1
        liveConnection?.let(::closeTranslationHandle)
        liveConnection = null; liveId = null; liveOpening = false
        liveRetry?.let(main::removeCallbacks); liveRetry = null
        liveAfter = BigInteger.ZERO; liveReauthenticated = false
        translation.liveState = "closed"
    }

    private fun openTranslationLive() {
        val id = translation.id ?: return
        val chosen = selection
        val ticket = ++liveTicket
        val sessionTicket = generation
        val scopeTicket = scopeGeneration
        liveId = id; liveOpening = true; liveAfter = BigInteger.ZERO
        translation.liveState = if (translation.loaded) "reconnecting" else "connecting"
        fun current() = ticket == liveTicket && sessionTicket == generation && scopeTicket == scopeGeneration && liveEligible()
        fun finish(result: Result<JSONObject>, revision: Long) {
            // Open uses the same refreshed/persisted snapshot and auth-rejection
            // protection as ordinary requests. Always account for late handles.
            val handle = result.getOrNull()?.opt("connection")?.takeUnless { it === JSONObject.NULL }
            if (!current()) { handle?.let(::closeTranslationHandle); return }
            fun complete(invalid: Boolean) {
                main.post {
                    if (!current()) { handle?.let(::closeTranslationHandle); return@post }
                    liveOpening = false
                    if (invalid) { reset(); error = context.nativeText("Sign in to Glossia again.").toString(); changed(); return@post }
                    if (handle != null) {
                        liveConnection = handle
                        nextTranslationLive(handle, ticket)
                    } else liveFailure(result.exceptionOrNull())
                    changed()
                }
            }
            if (result.isSuccess) complete(false)
            else credentials.execute {
                val invalid = if (current()) result.exceptionOrNull()?.let {
                    runCatching { reject(it, sessionTicket, revision) }.getOrDefault(false)
                } ?: false else false
                complete(invalid)
            }
        }
        credentials.execute {
            if (!current()) return@execute
            val saved = runCatching { snapshot(sessionTicket) }
            val revision = credentialRevision
            if (saved.isFailure) { finish(Result.failure(saved.exceptionOrNull()!!), revision); return@execute }
            try {
                requests.execute {
                    if (!current()) return@execute
                    val result = runCatching {
                        command(JSONObject().put("operation", "translation_live").put("action", "open")
                            .put("session", saved.getOrThrow()).put("selection", chosen).put("id", id))
                    }
                    finish(result, revision)
                }
            } catch (failure: java.util.concurrent.RejectedExecutionException) {
                finish(Result.failure(failure), revision)
            }
        }
    }

    private fun nextTranslationLive(connection: Any, ticket: Int) {
        val after = liveAfter
        translationLive.execute {
            val result = runCatching {
                translationDelivery(JSONObject().put("operation", "translation_live").put("action", "next")
                    .put("connection", connection).put("after", after))
            }
            main.post {
                if (ticket != liveTicket || !liveEligible()) return@post
                val delivery = result.getOrNull()
                if (delivery == null) {
                    liveFailure(result.exceptionOrNull()); changed(); return@post
                }
                val sequence = delivery.opt("sequence")?.toString()?.toBigIntegerOrNull()
                // Delivery sequence, not progress.seq: status-only changes may
                // legitimately carry exactly the same progress sequence.
                if (sequence != null && sequence > liveAfter) {
                    liveAfter = sequence
                    val previousStatus = translation.data?.optionalString("status")
                    delivery.optJSONObject("snapshot")?.let(translation::acceptSnapshot)
                    if (translation.data?.optionalString("status") == "awaiting_input" && previousStatus != "awaiting_input") loadTranslationReviews()
                }
                val state = delivery.optString("state", "reconnecting")
                val failure = delivery.optionalString("error")
                when {
                    failure in listOf("forbidden", "not_found") -> denyTranslation(requireNotNull(translation.id))
                    state == "needs_session" || failure == "sign_in_required" -> translationNeedsSession()
                    state in listOf("closed", "unavailable") -> liveFailure(null)
                    else -> {
                        if (state == "live") liveReauthenticated = false
                        translation.liveState = state
                        nextTranslationLive(connection, ticket)
                    }
                }
                changed()
            }
        }
    }

    private fun translationDelivery(request: JSONObject): JSONObject {
        val raw = bridge(request.toString())
        val envelope = JSONObject(raw)
        envelope.optJSONObject("error")?.let { throw Failure(it.getString("kind"), it.getString("message")) }
        val delivery = envelope.getJSONObject("ok")
        // Android's JSONObject falls back to Double above Long.MAX_VALUE.
        // Read the u64 cursor as a JSON number token without losing precision.
        JsonReader(raw.reader()).use { reader ->
            reader.beginObject()
            while (reader.hasNext()) {
                if (reader.nextName() == "ok") {
                    reader.beginObject()
                    while (reader.hasNext()) {
                        if (reader.nextName() == "sequence") delivery.put("sequence", reader.nextString())
                        else reader.skipValue()
                    }
                    reader.endObject()
                } else reader.skipValue()
            }
            reader.endObject()
        }
        return delivery
    }

    private fun translationNeedsSession() {
        if (!liveReauthenticated) {
            stopTranslationLive(); liveReauthenticated = true
            openTranslationLive()
        } else {
            denyTranslation(requireNotNull(translation.id))
            translation.error = context.nativeText("Sign in to Glossia again to view this translation.").toString()
        }
    }

    private fun liveFailure(failure: Throwable?) {
        if (failure is Failure && failure.kind in listOf("forbidden", "not_found")) {
            denyTranslation(requireNotNull(translation.id)); return
        }
        if (failure is Failure && failure.kind in listOf("sign_in_required", "rejected")) {
            translationNeedsSession(); return
        }
        val reauthenticated = liveReauthenticated
        stopTranslationLive(); liveReauthenticated = reauthenticated
        translation.liveState = "reconnecting"
        // Retry the local subscription, never poll the HTTP detail endpoint.
        val ticket = liveTicket
        liveRetry = Runnable {
            liveRetry = null
            if (ticket == liveTicket && liveEligible()) { openTranslationLive(); listener?.invoke() }
        }.also { main.postDelayed(it, 2000) }
    }

    fun retrySource() { toki.active?.let { loadSource(it, force = true) } }

    private fun loadSource(thread: ConversationModel, force: Boolean = false) {
        val id = thread.translationSessionId ?: return
        if (thread.source.busy || thread.source.loaded && !force) return
        val ticket = ++thread.source.ticket
        thread.source.busy = true; thread.source.error = null
        request(JSONObject().put("operation", "translation").put("selection", selection).put("id", id)) { result, failure ->
            // A denied conversation may have cleared the source while this was in flight.
            if (thread.translationSessionId != id || thread.unavailable || ticket != thread.source.ticket) return@request
            thread.source.busy = false; thread.source.error = failure?.let(::message)
            if (failure is Failure && failure.kind in listOf("forbidden", "not_found")) denyTranslation(id)
            if (result != null) {
                unavailableTranslations.remove(id)
                thread.source.data = result.getJSONObject("session"); thread.source.loaded = true
            }
        }
    }

    private fun denyTranslation(id: String) {
        unavailableTranslations.add(id); translations.remove(id)
        if (translation.id == id) {
            stopTranslationLive()
            translation.ticket += 1; translation.busy = false; translation.data = null; translation.loaded = false
            translation.reviews.clear()
            translation.progress = null; translation.liveState = "unavailable"
            translation.error = context.nativeText("This translation is not available or you do not have access. Retry to check access.").toString()
        }
        toki.threads.values.filter { it.translationSessionId == id }.forEach {
            it.clearWorkObservation()
            it.source.clear(); it.source.error = context.nativeText("The source translation is no longer accessible.").toString()
        }
    }

    fun back(): Boolean {
        cancelNavigation()
        if (tab == "Toki" && toki.active?.protectsDecision == true && protectWork()) { changed(); return true }
        when {
            tab == "Translations" && translation.id != null -> { translation.clear(); loadCurrent() }
            tab == "Toki" && toki.activeId != null -> { toki.activeId = null; loadCurrent() }
            else -> return false
        }
        changed(); return true
    }

    fun newConversation() {
        if (server == null || organization == null || project == null) return
        if (toki.active?.protectsDecision == true && protectWork()) { changed(); return }
        cancelNavigation()
        // Local navigation never discards other drafts or unconfirmed retries.
        // Workspace/deep-link changes still go through protectWork().
        tab = "Toki"; toki.newConversation()
        changed()
    }
    fun draft(value: String) { toki.active?.let { if (!it.unavailable) it.draft = value } }

    fun showConversation(id: String) {
        if (server == null || organization == null || project == null) return
        if (toki.active?.protectsDecision == true && toki.activeId != id && protectWork()) { changed(); return }
        cancelNavigation()
        tab = "Toki"
        fetchConversation(id)
    }

    private fun fetchConversation(id: String) {
        val thread = toki.threads.getOrPut(id) { ConversationModel(id, created = true, localize = { context.nativeText(it).toString() }) }
        toki.activeId = id
        if (thread.busy || thread.resolving || thread.pending != null || !thread.created) { changed(); return }
        thread.busy = true; thread.error = null
        request(conversationRequest(thread, "show")) { result, failure ->
            conversationFailure(thread, failure)
            if (result != null) {
                try { thread.accept(result); loadSource(thread) }
                catch (_: Exception) { thread.unavailable = true; thread.error = context.nativeText("Glossia returned an invalid shared conversation. Refresh to retry.").toString() }
            }
        }
        changed()
    }

    fun sendMessage() {
        if (server == null || organization == null || project == null) return
        val thread = toki.active ?: return
        if (thread.busy || thread.running || thread.unavailable || thread.goalClosed || thread.protectsDecision || thread.resolutionNeedsRefresh) return
        if (thread.pending == null) {
            if (thread.draft.isBlank() || thread.draft.codePointCount(0, thread.draft.length) > 4000) return
            thread.pending = PendingMessage(java.util.UUID.randomUUID().toString(), thread.draft)
        }
        thread.busy = true; thread.error = null
        val ticket = ++thread.writeTicket
        // A lost create/send response retries the exact same conversation and
        // message UUIDs and immutable content. Never manufacture a second send.
        if (!thread.created) {
            request(conversationRequest(thread, "create")) { result, failure ->
                if (ticket != thread.writeTicket) return@request
                if (result == null) conversationFailure(thread, failure)
                else { thread.accept(result); loadSource(thread); sendPending(thread, ticket) }
            }
        } else sendPending(thread, ticket)
        changed()
    }

    private fun sendPending(thread: ConversationModel, ticket: Int) {
        val pending = thread.pending ?: return
        request(conversationRequest(thread, "send").put("message_id", pending.id).put("content", pending.content)) { result, failure ->
            if (ticket != thread.writeTicket) return@request
            conversationFailure(thread, failure)
            if (result != null) {
                thread.accept(result, sentTurnId = pending.id)
                if (thread.draft == pending.content) thread.draft = ""
                thread.pending = null
                // Refresh the history independently, without clearing its rows.
                loadPage(toki.history, refresh = true)
            }
        }
    }

    private fun conversationFailure(thread: ConversationModel, failure: Throwable?) {
        if (failure is Failure && failure.kind in listOf("forbidden", "not_found")) {
            thread.clear()
            // Keep the selected identity as a retryable, read-only tombstone,
            // not a fresh conversation that might recreate a removed resource.
            thread.created = true; thread.unavailable = true
            toki.history.remove(thread.id)
        }
        thread.busy = false
        thread.error = when {
            failure == null -> null
            thread.unavailable -> context.nativeText("This conversation is no longer available. Retry to check access, or start a new conversation.").toString()
            else -> message(failure)
        }
    }

    private fun conversationRequest(thread: ConversationModel, action: String) = JSONObject()
        .put("operation", "conversation").put("selection", selection).put("action", action).put("id", thread.id)
        .apply { if (action == "create") thread.translationSessionId?.let { put("translation_session_id", it) } }

    private fun pollConversation() {
        if (!foreground || tab != "Toki") return
        val thread = toki.active ?: return
        if (thread.shouldPollVisible && !thread.busy && !thread.resolving && thread.error == null) fetchConversation(thread.id)
    }
}

fun JSONObject.optionalString(key: String): String? = if (isNull(key)) null else optString(key).takeIf { it.isNotEmpty() }
