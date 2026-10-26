package ai.glossia.mobile

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import com.google.firebase.FirebaseApp
import com.google.firebase.FirebaseOptions
import com.google.firebase.messaging.FirebaseMessaging
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import org.json.JSONObject
import java.util.UUID

internal object GlossiaFirebase {
    fun initialize(context: Context) {
        if (FirebaseApp.getApps(context).isNotEmpty()) return
        val values = listOf(BuildConfig.FIREBASE_APPLICATION_ID, BuildConfig.FIREBASE_PROJECT_ID,
            BuildConfig.FIREBASE_SENDER_ID, BuildConfig.FIREBASE_API_KEY)
        if (values.any { it.isBlank() }) return
        FirebaseApp.initializeApp(context, FirebaseOptions.Builder().setApplicationId(values[0])
            .setProjectId(values[1]).setGcmSenderId(values[2]).setApiKey(values[3]).build())
    }
}

internal interface PushTokenProvider {
    val available: Boolean
    fun token(completion: (Result<String>) -> Unit)
}

private class FirebasePushTokenProvider(private val context: Context) : PushTokenProvider {
    override val available get() = FirebaseApp.getApps(context).isNotEmpty()
    override fun token(completion: (Result<String>) -> Unit) {
        FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
            completion(if (task.isSuccessful) Result.success(task.result)
                else Result.failure(task.exception ?: IllegalStateException("Push token unavailable")))
        }
    }
}

internal object GlossiaPushStorage {
    fun key(origin: String) = "push:$origin"
    fun disable(storage: CredentialStorage, origin: String): JSONObject? {
        val saved = storage.load(key(origin)) ?: return null
        check(saved.getString("origin") == origin)
        saved.put("enabled", false)
        storage.save(key(origin), saved)
        return saved
    }
}

// Data-only FCM. The SDK never displays an unchecked notification payload for us.
class GlossiaMessagingService : FirebaseMessagingService() {
    override fun onNewToken(token: String) {
        // No OAuth refresh or enrollment in the service. Reconcile on foreground;
        // if already foreground, obtain the latest SDK token on the main thread.
        Handler(Looper.getMainLooper()).post {
            (application as? GlossiaApplication)?.session?.push?.refresh(force = true)
        }
    }

    override fun onMessageReceived(message: RemoteMessage) {
        if (message.notification != null) return
        val storage = SecureStorage(applicationContext)
        val origin = runCatching { storage.load("session")?.optJSONObject("registration")?.optionalString("server") }.getOrNull() ?: return
        val saved = runCatching { storage.load(GlossiaPushStorage.key(origin)) }.getOrNull() ?: return
        val url = GlossiaPushPayload.destination(message.data, origin, saved) { value ->
            val envelope = JSONObject(GlossiaCore.execute(JSONObject().put("operation", "navigation").put("action", "parse").put("url", value).toString()))
            envelope.optJSONObject("ok")?.optJSONObject("destination")?.let(GlossiaDestination::fromCore)
        } ?: return
        val manager = getSystemService(NotificationManager::class.java)
        if (!GlossiaPushNotifications.notificationsAllowed(this)) return
        manager.createNotificationChannel(NotificationChannel(CHANNEL, nativeText("Glossia notifications"), NotificationManager.IMPORTANCE_DEFAULT))
        val intent = Intent(this, MainActivity::class.java).setAction(Intent.ACTION_VIEW).setData(Uri.parse(url))
            .putExtra("glossia.push", JSONObject(message.data).toString())
            .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        val pending = PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val notification = Notification.Builder(this, CHANNEL).setSmallIcon(R.drawable.ic_toki)
            .setContentTitle("Glossia").setContentText(nativeText("An update is ready. Open Glossia to view it."))
            .setVisibility(Notification.VISIBILITY_PRIVATE).setAutoCancel(true).setContentIntent(pending).build()
        try { manager.notify(PREFIX + saved.getString("installation_id"), 1, notification) } catch (_: SecurityException) { }
    }

    companion object {
        internal const val CHANNEL = "glossia.push"
        internal const val PREFIX = "glossia.push."
    }
}

internal fun Context.pushSettings(push: GlossiaPushNotifications) = card {
    addSpaced(heading(nativeFormat("Push notifications · %1\$s", nativeText(if (push.enabled) "On" else "Off")), 18f, verbatim = true), 8)
    addSpaced(label("Get an alert when translations or Toki need your attention. Alerts never include private content. Optional; turn off anytime.", 14f, true), 12)
    val message = push.message ?: if (!push.available) nativeText("Push notifications are not configured in this build.").toString() else null
    message?.let { addSpaced(label(it, 14f, true, verbatim = true).apply { accessibilityLiveRegion = android.view.View.ACCESSIBILITY_LIVE_REGION_POLITE }, 12) }
    addView(button(if (push.enabled) "Turn off notifications" else "Enable push notifications", action = {
        if (push.enabled) push.disable() else push.enable()
    }).apply { isEnabled = !push.busy })
}

internal object GlossiaPushPayload {
    fun destination(data: Map<String, String>, origin: String, saved: JSONObject,
        parse: (String) -> GlossiaDestination?): String? = runCatching {
        val id = saved.getString("installation_id")
        val url = data["url"] ?: return null
        if (data["v"] != "1" || url.toByteArray(Charsets.UTF_8).size > 2048 || !saved.optBoolean("enabled") ||
            saved.optString("origin") != origin || saved.optString("registration_id") != id || data["registration_id"] != id) return null
        val target = parse(url) ?: return null
        if (target.screen !in listOf(GlossiaScreen.TRANSLATION, GlossiaScreen.CONVERSATION) ||
            java.net.URI(target.server) != java.net.URI(origin).resolve("/")) return null
        url
    }.getOrNull()
}

class GlossiaPushNotifications internal constructor(private val context: Context,
    private val storage: CredentialStorage,
    private val request: (JSONObject, (Result<JSONObject>) -> Unit) -> Unit,
    private val provider: PushTokenProvider = FirebasePushTokenProvider(context)) {
    var listener: (() -> Unit)? = null
    var enabled = false; private set
    var busy = false; private set
    var message: String? = null; private set
    val available get() = provider.available
    private val main = Handler(Looper.getMainLooper())
    private var origin: String? = null
    private var generation = 0
    private var lastSync = 0L
    private var permissionRequest = false
    private var permissionTicket: Int? = null
    private var foreground = false
    private var renewing = false

    fun configure(origin: String?) {
        if (this.origin == origin) return
        prepareForSessionEnd()
        this.origin = origin; message = null
        if (origin == null) return
        runCatching { storage.load(GlossiaPushStorage.key(origin)) }.fold(onSuccess = { saved ->
            enabled = saved?.optString("origin") == origin && saved.optBoolean("enabled")
            if (saved != null && !enabled) disable() else refresh(force = true)
        }, onFailure = { message = context.nativeText("Could not read secure notification settings.").toString() })
        listener?.invoke()
    }

    fun setForeground(value: Boolean) { foreground = value; if (value) { renewing = false; refresh(force = true) } }

    fun enable() {
        if (busy || origin == null) return
        if (!available) { message = context.nativeText("Push notifications are not configured in this build.").toString(); listener?.invoke(); return }
        if (!permissionGranted(context)) {
            permissionRequest = true; listener?.invoke(); return
        }
        if (!notificationsAllowed(context)) {
            message = context.nativeText("Allow Glossia notifications in Android Settings to enable alerts.").toString(); listener?.invoke(); return
        }
        val origin = origin ?: return
        try {
            val old = storage.load(GlossiaPushStorage.key(origin))
            if (old != null && !old.optBoolean("enabled")) { disable { enable() }; return }
            if (old == null) storage.save(GlossiaPushStorage.key(origin), JSONObject()
                .put("installation_id", UUID.randomUUID().toString()).put("origin", origin).put("enabled", true))
            enabled = true; message = null
            refresh(force = true)
        } catch (_: Exception) { message = context.nativeText("Could not securely save notification settings.").toString(); listener?.invoke() }
    }

    fun takePermissionRequest(): Boolean = permissionRequest.also {
        if (it) permissionTicket = generation
        permissionRequest = false
    }
    fun permissionResult(granted: Boolean) {
        if (permissionTicket != generation || origin == null) return
        permissionTicket = null
        if (granted) enable() else {
            message = context.nativeText("Notifications are off. Allow Glossia notifications in Android Settings to enable alerts.").toString()
            listener?.invoke()
        }
    }

    fun refresh(force: Boolean = false) {
        if (busy || origin == null) return
        val origin = origin ?: return
        val saved = runCatching { storage.load(GlossiaPushStorage.key(origin)) }.getOrNull() ?: return
        if (!saved.optBoolean("enabled")) { if (foreground) disable(); return }
        if (!enabled || !available || !foreground) return
        if (!notificationsAllowed(context)) { disable(); return }
        if (!force && System.currentTimeMillis() - lastSync < 300_000) return
        busy = true
        val ticket = generation
        val timeout = Runnable {
            if (generation == ticket && busy) { generation += 1; busy = false; message = context.nativeText("Obtaining a push token timed out. Return to Glossia to retry.").toString(); listener?.invoke() }
        }
        main.postDelayed(timeout, 15_000)
        listener?.invoke()
        provider.token { result -> main.post {
            if (ticket != generation) return@post
            main.removeCallbacks(timeout)
            val token = result.getOrNull()
            if (token == null) { busy = false; message = context.nativeText("Could not obtain a push token. Google Play services and a configured Firebase project are required.").toString(); listener?.invoke(); return@post }
            request(JSONObject().put("action", "register").put("installation_id", saved.getString("installation_id"))
                .put("platform", "android").put("environment", "production").put("token", token)) { response ->
                if (ticket != generation) return@request
                busy = false
                response.fold(onSuccess = {
                    runCatching {
                        check(it.optString("registration_id") == saved.getString("installation_id"))
                        saved.put("registration_id", it.getString("registration_id"))
                        storage.save(GlossiaPushStorage.key(origin), saved)
                    }.onSuccess { message = null; lastSync = System.currentTimeMillis(); renewing = false }
                        .onFailure { message = context.nativeText("Could not securely save notification registration.").toString() }
                }, onFailure = {
                    if (it is Failure && it.kind == "conflict" && !renewing) { renewing = true; disable { enable() } }
                    else message = context.nativeFormat("Could not sync notifications. Return to Glossia to retry. %1\$s", it.message.orEmpty())
                })
                listener?.invoke()
            }
        } }
    }

    fun disable(completion: () -> Unit = {}) {
        generation += 1; enabled = false; busy = false; permissionRequest = false
        permissionTicket = null
        clearDelivered()
        val origin = origin ?: return
        val saved = try { GlossiaPushStorage.disable(storage, origin) } catch (_: Exception) {
            message = context.nativeText("Could not securely disable notifications. Try again before signing out.").toString(); listener?.invoke(); return
        } ?: return
        val ticket = generation
        busy = true
        request(JSONObject().put("action", "unregister").put("installation_id", saved.getString("installation_id"))) { result ->
            if (ticket != generation) return@request
            busy = false
            result.fold(onSuccess = {
                runCatching { storage.delete(GlossiaPushStorage.key(origin)) }
                    .onSuccess { message = null; completion() }.onFailure { message = context.nativeText("Could not securely clear notification registration.").toString() }
            }, onFailure = { message = context.nativeText("Notifications are off locally. Server cleanup will retry at your next sign-in.").toString() })
            listener?.invoke()
        }
        listener?.invoke()
    }

    fun prepareForSessionEnd() {
        generation += 1; enabled = false; busy = false; permissionRequest = false
        permissionTicket = null
        // Repeat on the main thread after credential invalidation, so a reply
        // already queued before that invalidation cannot leave opt-in enabled.
        runCatching { origin?.let { GlossiaPushStorage.disable(storage, it) } }
        origin = null; lastSync = 0; clearDelivered()
    }

    private fun clearDelivered() {
        val manager = context.getSystemService(NotificationManager::class.java)
        manager.activeNotifications.filter { it.tag?.startsWith(GlossiaMessagingService.PREFIX) == true }
            .forEach { manager.cancel(it.tag, it.id) }
    }

    companion object {
        internal fun permissionGranted(context: Context) = Build.VERSION.SDK_INT < 33 || ContextCompat.checkSelfPermission(context,
            Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED

        internal fun notificationsAllowed(context: Context): Boolean {
            val manager = context.getSystemService(NotificationManager::class.java)
            return permissionGranted(context) && manager.areNotificationsEnabled() &&
                manager.getNotificationChannel(GlossiaMessagingService.CHANNEL)?.importance != NotificationManager.IMPORTANCE_NONE
        }
    }
}
