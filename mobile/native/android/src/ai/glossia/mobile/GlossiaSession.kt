package ai.glossia.mobile

import android.app.Application
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import org.json.JSONArray
import org.json.JSONObject
import java.security.KeyStore
import java.util.concurrent.Executors
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import com.google.android.material.color.DynamicColors

object GlossiaCore {
    init { System.loadLibrary("glossia_core") }
    external fun execute(input: String): String
}

class GlossiaApplication : Application() {
    val session by lazy { GlossiaSession(applicationContext) }

    override fun onCreate() {
        super.onCreate()
        DynamicColors.applyToActivitiesIfAvailable(this)
    }
}

private class Failure(val kind: String, message: String) : Exception(message)

private class SecureStorage(context: Context) {
    private val preferences = context.getSharedPreferences("glossia.oauth", Context.MODE_PRIVATE)
    private val alias = "ai.glossia.mobile.oauth"

    private fun key(): SecretKey {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (store.getKey(alias, null) as? SecretKey)?.let { return it }
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore").run {
            init(KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM).setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE).build())
            generateKey()
        }
    }

    fun load(name: String): JSONObject? {
        val stored = preferences.getString(name, null) ?: return null
        val envelope = JSONObject(stored)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, Base64.decode(envelope.getString("iv"), Base64.NO_WRAP)))
        cipher.updateAAD(name.toByteArray(Charsets.UTF_8))
        return JSONObject(String(cipher.doFinal(Base64.decode(envelope.getString("data"), Base64.NO_WRAP)), Charsets.UTF_8))
    }

    fun save(name: String, value: JSONObject) {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key())
        cipher.updateAAD(name.toByteArray(Charsets.UTF_8))
        val envelope = JSONObject().put("iv", Base64.encodeToString(cipher.iv, Base64.NO_WRAP))
            .put("data", Base64.encodeToString(cipher.doFinal(value.toString().toByteArray(Charsets.UTF_8)), Base64.NO_WRAP))
        check(preferences.edit().putString(name, envelope.toString()).commit())
    }

    fun delete(name: String) { check(preferences.edit().remove(name).commit()) }
}

// Application-owned, so rotation never drops an OAuth callback or retains an Activity.
// A single worker serializes refresh, durable rotation, and all Rust calls off main.
class GlossiaSession(context: Context) {
    private val storage = SecureStorage(context)
    private val preferences = context.getSharedPreferences("glossia.workspace", Context.MODE_PRIVATE)
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    @Volatile
    private var generation = 0
    @Volatile
    private var resourceGeneration = 0
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
    var tab = "Overview"
        private set
    var resource: JSONObject? = null
        private set
    var resourceBusy = false
        private set
    var resourceError: String? = null
        private set
    private var deferredCallback: String? = null
    val selection: JSONObject
        get() = JSONObject().put("organization", organization ?: JSONObject.NULL).put("project", project ?: JSONObject.NULL)

    private fun command(value: JSONObject): JSONObject {
        val envelope = JSONObject(GlossiaCore.execute(value.toString()))
        envelope.optJSONObject("error")?.let { throw Failure(it.getString("kind"), it.getString("message")) }
        return envelope.getJSONObject("ok")
    }

    private fun authenticated(request: JSONObject): JSONObject {
        val saved = storage.load("session") ?: throw Failure("sign_in_required", "Sign in to Glossia again.")
        val session = command(JSONObject().put("operation", "restore").put("session", saved))
        storage.save("session", session) // Commit rotated credentials even if the API fails.
        return command(request.put("session", session))
    }

    private fun failure(error: Throwable): String {
        if (error is Failure) {
            if (error.kind in listOf("rejected", "sign_in_required")) {
                storage.delete("session")
                storage.delete("pending")
                if (error.kind == "rejected") storage.delete("registration")
            }
            return error.message ?: "Request failed."
        }
        return "Could not access secure storage. Try again."
    }

    private fun work(action: () -> JSONObject?, completion: (JSONObject?) -> Unit) {
        if (busy) return
        busy = true; error = null
        val ticket = generation
        listener?.invoke()
        worker.execute {
            val result = runCatching { action() }
            val message = result.exceptionOrNull()?.let { runCatching { failure(it) }.getOrDefault("Could not clear secure credentials.") }
            main.post {
                if (ticket == generation) {
                    val failure = result.exceptionOrNull() as? Failure
                    if (failure?.kind in listOf("rejected", "sign_in_required")) reset()
                    busy = false
                    if (message == null) completion(result.getOrNull()) else error = message
                    listener?.invoke()
                    deferredCallback?.let { deferredCallback = null; callback(it) }
                }
            }
        }
    }

    fun restore() {
        if (started) return
        started = true
        work({
            val saved = storage.load("session") ?: return@work null
            command(JSONObject().put("operation", "restore").put("session", saved)).also { storage.save("session", it) }
        }) { session ->
            if (session != null) {
                server = session.getJSONObject("registration").getString("server")
                val saved = JSONObject(preferences.getString("selection", "{}") ?: "{}")
                organization = saved.optionalString("organization"); project = saved.optionalString("project")
                reload()
            }
        }
    }

    fun retryRestore() { started = false; restore() }

    fun signIn(address: String) {
        work({
            val request = JSONObject().put("operation", "begin").put("server", address)
            storage.load("registration")?.let { request.put("registration", it) }
            command(request).also {
                storage.save("registration", it.getJSONObject("registration"))
                storage.save("pending", it.getJSONObject("pending"))
            }
        }) { login -> authorizationURL = login?.getString("authorization_url") }
    }

    fun callback(url: String) {
        if (busy) { deferredCallback = url; return }
        work({
            val pending = storage.load("pending") ?: throw Failure("callback", "No sign-in is waiting. Start a new sign-in.")
            try {
                command(JSONObject().put("operation", "validate_callback").put("pending", pending).put("callback", url))
            } catch (failure: Failure) {
                if (failure.kind == "denied") storage.delete("pending")
                throw failure
            }
            // Only a matching callback may consume this grant, before exchanging its code.
            storage.delete("pending") // A callback is consumed once, including across process death.
            command(JSONObject().put("operation", "complete").put("pending", pending).put("callback", url))
                .also { storage.save("session", it) }
        }) { session ->
            server = session?.getJSONObject("registration")?.getString("server")
            reload()
        }
    }

    fun reload() {
        if (server == null || busy) return
        resourceGeneration += 1; resource = null; resourceBusy = false
        val desired = selection
        work({ authenticated(JSONObject().put("operation", "workspace").put("selection", desired)) }) { result ->
            if (result != null) {
                organizations = result.getJSONArray("organizations"); projects = result.getJSONArray("projects")
                organization = result.getJSONObject("selection").optionalString("organization")
                project = result.getJSONObject("selection").optionalString("project")
                preferences.edit().putString("selection", selection.toString()).apply()
                loadResource()
            }
        }
    }

    fun selectOrganization(handle: String) {
        if (busy) return
        organization = handle; project = null; projects = JSONArray()
        reload()
    }

    fun selectProject(handle: String) {
        project = handle
        preferences.edit().putString("selection", selection.toString()).apply()
        loadResource()
        listener?.invoke()
    }

    fun selectTab(value: String) {
        tab = value
        resourceGeneration += 1; resource = null; resourceError = null; resourceBusy = false
        loadResource()
        listener?.invoke()
    }

    fun loadResource() {
        if (busy || organization == null || tab !in listOf("Voice", "Glossary")) return
        resourceGeneration += 1
        val ticket = resourceGeneration
        val sessionTicket = generation
        val name = tab.lowercase(java.util.Locale.ROOT)
        val request = JSONObject().put("operation", "resource").put("selection", selection).put("resource", name)
        resourceBusy = true; resource = null; resourceError = null
        worker.execute {
            // Skip superseded requests before refresh, storage, or network work begins.
            if (ticket != resourceGeneration || sessionTicket != generation) return@execute
            val result = runCatching { authenticated(request) }
            val message = result.exceptionOrNull()?.let { runCatching { failure(it) }.getOrDefault("Could not clear secure credentials.") }
            main.post {
                if (ticket == resourceGeneration && sessionTicket == generation) {
                    val failure = result.exceptionOrNull() as? Failure
                    if (failure?.kind in listOf("rejected", "sign_in_required")) {
                        reset()
                        error = message
                        listener?.invoke()
                        return@post
                    }
                    resourceBusy = false; resource = result.getOrNull()?.optJSONObject(name); resourceError = message
                    listener?.invoke()
                }
            }
        }
        listener?.invoke()
    }

    fun signOut(resetRegistration: Boolean = false) {
        if (busy) return
        resourceGeneration += 1; resourceBusy = false
        work({
            if (resetRegistration) storage.delete("registration")
            storage.delete("pending")
            storage.delete("session")
            null
        }) { error = null; reset() }
    }

    private fun reset() {
        generation += 1; resourceGeneration += 1
        server = null; organization = null; project = null; projects = JSONArray(); organizations = JSONArray()
        resource = null; resourceError = null; resourceBusy = false; tab = "Overview"; busy = false
        deferredCallback = null; authorizationURL = null
        preferences.edit().remove("selection").apply()
        listener?.invoke()
    }
}

fun JSONObject.optionalString(key: String): String? = if (isNull(key)) null else optString(key).takeIf { it.isNotEmpty() }
