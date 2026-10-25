package ai.glossia.mobile

import android.Manifest
import android.app.Application
import android.app.NotificationManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.os.Looper
import android.view.View
import android.widget.FrameLayout
import android.widget.TextView
import com.google.android.material.appbar.MaterialToolbar
import com.google.android.material.bottomnavigation.BottomNavigationView
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.io.File

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35], application = Application::class, qualifiers = "w411dp-h891dp-420dpi")
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class PushNotificationsTest {
    private val context get() = RuntimeEnvironment.getApplication()
    private val origin = "https://glossia.ai/"
    private val id = "01922cc0-0000-7000-8000-000000000001"
    private class Memory : CredentialStorage {
        val values = java.util.concurrent.ConcurrentHashMap<String, String>()
        var beforeDelete: ((String) -> Unit)? = null
        override fun load(name: String) = values[name]?.let(::JSONObject)
        override fun save(name: String, value: JSONObject) { values[name] = value.toString() }
        override fun delete(name: String) { beforeDelete?.invoke(name); values.remove(name) }
    }
    private class Tokens(override val available: Boolean = true) : PushTokenProvider {
        var latest = "firebase-token-value-123"
        var pending: ((Result<String>) -> Unit)? = null
        var delay = false
        override fun token(completion: (Result<String>) -> Unit) {
            if (delay) pending = completion else completion(Result.success(latest))
        }
    }
    private fun grant() {
        shadowOf(context).grantPermissions(Manifest.permission.POST_NOTIFICATIONS)
        shadowOf(context.getSystemService(NotificationManager::class.java)).setNotificationsEnabled(true)
    }
    private fun idle() { shadowOf(Looper.getMainLooper()).idle() }
    private fun saved(enabled: Boolean = true) = JSONObject().put("origin", origin).put("enabled", enabled)
        .put("installation_id", id).put("registration_id", id)

    @Test fun optInDenialAndUnavailableBuildNeverEnroll() {
        val storage = Memory()
        var calls = 0
        val denied = GlossiaPushNotifications(context, storage, { _, _ -> calls++ }, Tokens())
        denied.configure(origin); denied.setForeground(true)
        assertEquals(0, calls); assertFalse(denied.enabled)
        shadowOf(context).denyPermissions(Manifest.permission.POST_NOTIFICATIONS)
        denied.enable(); assertTrue(denied.takePermissionRequest())
        denied.permissionResult(false)
        assertEquals(0, calls); assertFalse(denied.enabled); assertTrue(storage.values.isEmpty())
        assertTrue(denied.message!!.contains("Settings"))
        val missing = GlossiaPushNotifications(context, storage, { _, _ -> calls++ }, Tokens(false))
        missing.configure(origin); missing.enable()
        assertFalse(missing.takePermissionRequest()); assertTrue(missing.message!!.contains("not configured"))
        assertEquals(0, calls)
    }

    @Test fun rotationUsesTheSameInstallationAndRevocationWritesTombstoneBeforeDelete() {
        grant()
        val storage = Memory(); val tokens = Tokens(); val calls = mutableListOf<JSONObject>()
        val push = GlossiaPushNotifications(context, storage, { input, completion ->
            calls.add(JSONObject(input.toString()))
            if (input.getString("action") == "register") completion(Result.success(JSONObject().put("registration_id", input.getString("installation_id"))))
            else {
                assertFalse(storage.load(GlossiaPushStorage.key(origin))!!.getBoolean("enabled"))
                completion(Result.failure(Exception("Offline")))
            }
        }, tokens)
        push.configure(origin); push.setForeground(true); push.enable(); idle()
        assertTrue(push.enabled); assertEquals(1, calls.size)
        tokens.latest = "firebase-rotated-value-456"; push.refresh(force = true); idle()
        assertEquals(2, calls.size)
        assertEquals(calls[0].getString("installation_id"), calls[1].getString("installation_id"))
        assertEquals(tokens.latest, calls[1].getString("token"))
        shadowOf(context.getSystemService(NotificationManager::class.java)).setNotificationsEnabled(false)
        push.refresh(force = true); idle()
        assertFalse(push.enabled); assertEquals("unregister", calls.last().getString("action"))
        assertFalse(storage.load(GlossiaPushStorage.key(origin))!!.getBoolean("enabled"))
    }

    @Test fun disablingOnlyThePushChannelRevokesEnrollment() {
        grant()
        val storage = Memory(); val calls = mutableListOf<String>()
        val push = GlossiaPushNotifications(context, storage, { input, completion ->
            calls.add(input.getString("action"))
            completion(Result.success(JSONObject().put("registration_id", input.optString("installation_id")).put("deleted", true)))
        }, Tokens())
        push.configure(origin); push.setForeground(true); push.enable(); idle()
        assertTrue(push.enabled); assertEquals(listOf("register"), calls)
        val manager = context.getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(android.app.NotificationChannel(GlossiaMessagingService.CHANNEL,
            "Glossia notifications", NotificationManager.IMPORTANCE_NONE))
        assertTrue(manager.areNotificationsEnabled())
        push.refresh(force = true); idle()
        assertFalse(push.enabled); assertEquals(listOf("register", "unregister"), calls)
        assertNull(storage.load(GlossiaPushStorage.key(origin)))
        push.enable(); idle()
        assertFalse(push.enabled); assertTrue(push.message!!.contains("Settings"))
        assertEquals(listOf("register", "unregister"), calls)
    }

    @Test fun lateTokenAndRegisterRepliesCannotReenableEndedSessions() {
        grant()
        for (stage in listOf("token", "register")) {
            val storage = Memory(); val tokens = Tokens().apply { delay = stage == "token" }
            var reply: ((Result<JSONObject>) -> Unit)? = null
            var writes = 0
            val push = GlossiaPushNotifications(context, storage, { _, completion -> writes++; reply = completion }, tokens)
            push.configure(origin); push.setForeground(true); push.enable(); idle()
            push.prepareForSessionEnd()
            if (stage == "token") tokens.pending?.invoke(Result.success(tokens.latest))
            else reply?.invoke(Result.success(JSONObject().put("registration_id", storage.load(GlossiaPushStorage.key(origin))!!.getString("installation_id"))))
            idle()
            assertFalse(push.enabled); assertFalse(storage.load(GlossiaPushStorage.key(origin))!!.getBoolean("enabled"))
            assertEquals(if (stage == "token") 0 else 1, writes)
        }
    }

    @Test fun offlineTombstonesRetryDeletionAndDoNotInheritOptIn() {
        grant()
        val storage = Memory().apply { save(GlossiaPushStorage.key(origin), saved(false)) }
        val calls = mutableListOf<String>()
        val push = GlossiaPushNotifications(context, storage, { input, completion ->
            calls.add(input.getString("action")); completion(Result.failure(Exception("Offline")))
        }, Tokens())
        push.configure(origin); assertFalse(push.enabled); assertEquals(listOf("unregister"), calls)
        push.enable(); assertFalse(push.enabled); assertEquals(listOf("unregister", "unregister"), calls)
        push.configure("https://other.example/"); assertFalse(push.enabled)
        assertFalse(storage.load(GlossiaPushStorage.key(origin))!!.getBoolean("enabled"))
    }

    @Test fun permissionResultFromAnEndedSessionCannotEnrollANewSession() {
        shadowOf(context).denyPermissions(Manifest.permission.POST_NOTIFICATIONS)
        val memory = Memory()
        var calls = 0
        val push = GlossiaPushNotifications(context, memory, { _, _ -> calls++ }, Tokens())
        push.configure(origin); push.enable(); assertTrue(push.takePermissionRequest())
        push.prepareForSessionEnd(); push.configure("https://other.example/")
        grant(); push.permissionResult(true); idle()
        assertFalse(push.enabled); assertEquals(0, calls); assertTrue(memory.values.isEmpty())
    }

    @Test fun retiredRegistrationsAreDeletedBeforeOneBoundedRenewal() {
        grant()
        val calls = mutableListOf<JSONObject>()
        val push = GlossiaPushNotifications(context, Memory(), { input, completion ->
            calls.add(JSONObject(input.toString()))
            if (input.getString("action") == "register") completion(Result.failure(Failure("conflict", "Retired")))
            else completion(Result.success(JSONObject().put("deleted", true)))
        }, Tokens())
        push.configure(origin); push.setForeground(true); push.enable(); idle()
        assertEquals(listOf("register", "unregister", "register"), calls.map { it.getString("action") })
        assertEquals(calls[0].getString("installation_id"), calls[1].getString("installation_id"))
        assertNotEquals(calls[0].getString("installation_id"), calls[2].getString("installation_id"))
        assertFalse(push.busy); assertNotNull(push.message)
    }

    @Test fun receiptsAreVersionedRegistrationBoundSameOriginReadOnlyReferences() {
        val url = "glossia://navigate/acme/website/translations/$id?server=https%3A%2F%2Fglossia.ai%2F"
        val data = mapOf("v" to "1", "url" to url, "registration_id" to id)
        val target = GlossiaDestination(GlossiaScreen.TRANSLATION, origin, "acme", "website", id)
        assertEquals(url, GlossiaPushPayload.destination(data, origin, saved()) { target })
        assertNull(GlossiaPushPayload.destination(data + ("v" to "2"), origin, saved()) { target })
        assertNull(GlossiaPushPayload.destination(data + ("registration_id" to "old"), origin, saved()) { target })
        assertNull(GlossiaPushPayload.destination(data, origin, saved(false)) { target })
        assertNull(GlossiaPushPayload.destination(data, origin, saved()) { target.copy(server = "https://other.example/") })
        assertNull(GlossiaPushPayload.destination(data, origin, saved()) { target.copy(screen = GlossiaScreen.NEW_CONVERSATION) })
        assertNull(GlossiaPushPayload.destination(data + ("url" to "x".repeat(2049)), origin, saved()) { target })
    }

    @Test fun coldTapQueuesTypedNavigationAndLogoutDisablesBeforeDeletingCredentials() {
        val storage = Memory().apply {
            save("session", JSONObject().put("registration", JSONObject().put("server", origin)).put("access_token", "private-access"))
            save(GlossiaPushStorage.key(origin), saved())
        }
        val target = GlossiaDestination(GlossiaScreen.TRANSLATION, origin, "acme", "website", id)
        val calls = java.util.concurrent.CopyOnWriteArrayList<JSONObject>()
        val disabledBeforeDeletion = java.util.concurrent.atomic.AtomicBoolean()
        storage.beforeDelete = { name -> if (name == "session") {
            disabledBeforeDeletion.set(storage.load(GlossiaPushStorage.key(origin))?.optBoolean("enabled") == false)
        } }
        val session = GlossiaSession(context, storage) { raw ->
            val input = JSONObject(raw); calls.add(input)
            val result = when (input.getString("operation")) {
                "navigation" -> JSONObject().put("destination", target.json()).put("url", "fixture")
                "push" -> JSONObject().put("deleted", true)
                "themes" -> return@GlossiaSession """{"error":{"kind":"network","message":"Offline"}}"""
                else -> error("Unexpected request $input")
            }
            JSONObject().put("ok", result).toString()
        }
        fun pump(predicate: () -> Boolean) {
            val until = System.nanoTime() + java.util.concurrent.TimeUnit.SECONDS.toNanos(5)
            while (!predicate() && System.nanoTime() < until) { idle(); Thread.sleep(5) }
            idle(); assertTrue(predicate())
        }
        fun intent() = android.content.Intent(android.content.Intent.ACTION_VIEW).putExtra("glossia.push",
            JSONObject().put("v", "1").put("registration_id", id).put("url", "glossia://navigate/fixture").toString())
        try {
            val cold = intent()
            assertTrue(session.consumePushIntent(cold))
            pump { session.pendingDestination == target }
            assertNull(session.server)
            assertTrue(calls.all { it.getString("operation") == "navigation" })
            assertFalse(session.consumePushIntent(cold)) // Consumed once.
            session.signOut()
            pump { !session.busy && storage.load("session") == null && calls.any { it.optString("action") == "unregister" } }
            assertTrue(disabledBeforeDeletion.get())
            assertFalse(storage.load(GlossiaPushStorage.key(origin))!!.getBoolean("enabled"))
            assertTrue(session.consumePushIntent(intent()))
            assertNull(session.pendingDestination)
        } finally {
            session.setForeground(false); session.appearance.close()
            for (name in listOf("credentials", "requests", "translationLive")) {
                val field = GlossiaSession::class.java.getDeclaredField(name).apply { isAccessible = true }
                (field.get(session) as java.util.concurrent.ExecutorService).shutdownNow()
            }
        }
    }

    @Test fun profilePushEnabledDeniedUnavailableRenderInBothThemes() {
        for (night in listOf(false, true)) for (state in listOf("enabled", "denied", "unavailable")) {
            RuntimeEnvironment.setQualifiers("w411dp-h891dp-${if (night) "night" else "notnight"}-420dpi")
            grant()
            val controller = Robolectric.buildActivity(RenderActivity::class.java).setup()
            val activity = controller.get()
            val tokens = Tokens(state != "unavailable")
            val push = GlossiaPushNotifications(activity, Memory(), { input, completion ->
                completion(Result.success(JSONObject().put("registration_id", input.optString("installation_id"))))
            }, tokens)
            push.configure(origin); push.setForeground(true)
            if (state == "denied") {
                shadowOf(context).denyPermissions(Manifest.permission.POST_NOTIFICATIONS)
                push.enable(); assertTrue(push.takePermissionRequest()); push.permissionResult(false)
            }
            else push.enable()
            idle()
            assertEquals(state == "enabled", push.enabled)
            val root = activity.layoutInflater.inflate(R.layout.activity_main, null)
            activity.setContentView(root)
            root.findViewById<MaterialToolbar>(R.id.toolbar).apply { title = "Profile"; menu.clear() }
            root.findViewById<BottomNavigationView>(R.id.navigation).selectedItemId = R.id.profile
            val model = FeatureModel().apply { loaded = true; data = JSONObject("""{"user":{"name":"Alex Morgan","email":"alex@example.com","handle":"alex"},"server_version":"2026.10.1"}""") }
            val view = FeatureViews(activity).profile(model, origin, "acme", "website", {}, {}, push)
            root.findViewById<FrameLayout>(R.id.screen).addView(view)
            activity.appearance.apply(activity, root)
            root.measure(View.MeasureSpec.makeMeasureSpec(1080, View.MeasureSpec.EXACTLY), View.MeasureSpec.makeMeasureSpec(2340, View.MeasureSpec.EXACTLY))
            root.layout(0, 0, 1080, 2340); idle()
            val bitmap = Bitmap.createBitmap(1080, 2340, Bitmap.Config.ARGB_8888)
            root.draw(Canvas(bitmap))
            val directory = File(requireNotNull(System.getProperty("artifacts"))).apply { mkdirs() }
            File(directory, "android-profile-push-$state-${if (night) "dark" else "light"}.png").outputStream().use {
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
            }
            bitmap.recycle(); push.setForeground(false); controller.pause().stop().destroy()
        }
    }
}
