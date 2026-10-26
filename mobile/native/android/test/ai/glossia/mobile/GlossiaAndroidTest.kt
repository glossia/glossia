package ai.glossia.mobile

import android.Manifest
import android.app.Application
import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.net.Uri
import android.os.Bundle
import android.os.Looper
import android.provider.Settings
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.FrameLayout
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.app.AppCompatDelegate
import androidx.core.app.LocaleManagerCompat
import androidx.core.os.LocaleListCompat
import androidx.core.view.ViewCompat
import com.google.android.material.appbar.MaterialToolbar
import com.google.android.material.bottomnavigation.BottomNavigationView
import com.google.android.material.button.MaterialButton
import com.google.android.material.card.MaterialCardView
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.google.android.material.progressindicator.LinearProgressIndicator
import com.google.android.material.textfield.TextInputEditText
import org.json.JSONArray
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import org.robolectric.shadows.ShadowChoreographer
import org.robolectric.shadows.ShadowDialog
import java.io.File
import java.time.Duration
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong

class RenderActivity : AppCompatActivity(), AppearanceOwner {
    override lateinit var appearance: GlossiaAppearance
    override fun onCreate(state: Bundle?) {
        appearance = GlossiaAppearance(this, { error("No bridge configured for rendering") })
        setTheme(R.style.GlossiaTheme); super.onCreate(state)
    }
    override fun onDestroy() { appearance.close(); super.onDestroy() }
}

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35], application = Application::class, qualifiers = "w411dp-h891dp-420dpi")
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class GlossiaAndroidTest {
    private val sessions = mutableListOf<GlossiaSession>()
    private val appearances = mutableListOf<GlossiaAppearance>()
    private val releases = mutableListOf<CountDownLatch>()
    private val context get() = RuntimeEnvironment.getApplication()
    private val artifacts get() = File(requireNotNull(System.getProperty("artifacts"))).apply { mkdirs() }

    @After fun cleanup() {
        releases.forEach { it.countDown() }
        appearances.forEach { it.close() }
        sessions.forEach { session ->
            session.setForeground(false)
            session.appearance.close()
            for (name in listOf("credentials", "requests", "translationLive")) {
                val field = GlossiaSession::class.java.getDeclaredField(name).apply { isAccessible = true }
                (field.get(session) as java.util.concurrent.ExecutorService).shutdownNow()
            }
        }
    }

    private fun pump(predicate: () -> Boolean) {
        val end = System.nanoTime() + TimeUnit.SECONDS.toNanos(8)
        while (!predicate() && System.nanoTime() < end) { shadowOf(Looper.getMainLooper()).idle(); Thread.sleep(5) }
        shadowOf(Looper.getMainLooper()).idle()
        assertTrue("Timed out waiting for feature result", predicate())
    }

    private class MemoryStorage : CredentialStorage {
        val values = java.util.concurrent.ConcurrentHashMap<String, String>()
        override fun load(name: String) = values[name]?.let(::JSONObject)
        override fun save(name: String, value: JSONObject) { values[name] = value.toString() }
        override fun delete(name: String) { values.remove(name) }
    }

    private val calls = CopyOnWriteArrayList<JSONObject>()
    private val rawCalls = CopyOnWriteArrayList<String>()
    private val translationId = "123e4567-e89b-12d3-a456-426614174000"
    private val conversationId = "123e4567-e89b-12d3-a456-426614174001"
    private val navigationFixtures = java.util.concurrent.ConcurrentHashMap<String, GlossiaDestination>()
    private fun destination(screen: GlossiaScreen, org: String = "glossia", project: String = "website", id: String? = null,
        source: String? = null, server: String = "https://glossia.ai/") =
        GlossiaDestination(screen, server, if (screen == GlossiaScreen.PROFILE) null else org,
            if (screen == GlossiaScreen.PROFILE) null else project, id, source)

    // Fixed bridge fixtures, not another implementation of Rust's URL parser.
    private fun link(destination: GlossiaDestination): String {
        val path = when (destination.screen) {
            GlossiaScreen.PROFILE -> "profile"
            else -> "${destination.organization}/${destination.project}/" + when (destination.screen) {
                GlossiaScreen.CONVERSATION -> "toki/${destination.id}"
                GlossiaScreen.NEW_CONVERSATION -> "toki/new"
                GlossiaScreen.TRANSLATION -> "translations/${destination.id}"
                else -> destination.screen.wire
            }
        }
        return "glossia://navigate/$path?server=${Uri.encode(destination.server)}" +
            (destination.translationId?.let { "&translation_id=$it" } ?: "")
    }

    private fun fixtureLink(destination: GlossiaDestination) = link(destination).also { navigationFixtures[it] = destination }

    private fun navigationFixture(request: JSONObject): JSONObject {
        val target = if (request.getString("action") == "parse") navigationFixtures[request.getString("url")]
            else GlossiaDestination.fromCore(request.getJSONObject("destination")).let { value ->
                val uri = java.net.URI(value.server)
                value.copy(server = "https://${uri.host.lowercase()}${if (uri.port == -1 || uri.port == 443) "" else ":${uri.port}"}/")
            }
        return if (target == null) failure("invalid_link", "Invalid fixture link")
            else JSONObject().put("destination", target.json()).put("url", link(target))
    }

    private fun failure(kind: String, message: String = kind) = JSONObject().put("error", JSONObject().put("kind", kind).put("message", message))
    private fun translationRecord(id: String = translationId) = JSONObject("""{"status":"completed","commit_message":"A warmer welcome, in every language","source_language":"en","target_languages":["es","fr","de"],"translated_content_count":128,"summary":"Updated homepage and onboarding translations.","inserted_at":"2026-10-25T08:00:00Z"}""").put("id", id)

    private val reviewId = "def12345-802e-4f91-9112-77d8a919efc5"
    private val goalChatId = "93cf36a3-802e-4f91-9112-77d8a919efc5"
    private val goalReplyId = "aaa12345-802e-4f91-9112-77d8a919efc5"
    private fun reviewRecord(status: String = "open") = JSONObject("""{"locale":"es","question":"Should we address the reader with tú or usted?","source_path":"locales/en/welcome.json","output_path":"locales/es/welcome.json","source_excerpt":"Welcome back!","translation_excerpt":"¡Bienvenido de nuevo!","inserted_at":"2026-10-25T10:00:00Z"}""")
        .put("id", reviewId).put("translation_session_id", translationId).put("conversation_id", goalChatId).put("status", status)

    private fun goalConversation(status: String = "open", phase: String = "completed") = conversation(goalChatId, phase).apply {
        getJSONObject("conversation").put("linguistic_review", reviewRecord(status))
        put("messages", JSONArray().put(JSONObject().put("id", "bbb12345-802e-4f91-9112-77d8a919efc5").put("role", "assistant").put("content", "Should we address the reader with tú or usted?"))
            .put(JSONObject().put("id", "ccc12345-802e-4f91-9112-77d8a919efc5").put("role", "user").put("content", "Our onboarding should feel friendly."))
            .put(JSONObject().put("id", goalReplyId).put("role", "assistant").put("status", "completed").put("reply_to_id", "ccc12345-802e-4f91-9112-77d8a919efc5").put("content", "Use informal tú.")))
    }

    private fun session(signedIn: Boolean = true, restore: Boolean = true,
        custom: (JSONObject) -> JSONObject? = { null }): Pair<GlossiaSession, MemoryStorage> {
        context.getSharedPreferences("glossia.workspace", 0).edit().clear().commit()
        context.getSharedPreferences("glossia.appearance", 0).edit().clear().commit()
        context.getSharedPreferences("glossia.notifications", 0).edit().clear().commit()
        val storage = MemoryStorage().apply { if (signedIn) save("session", JSONObject("""{"registration":{"server":"https://glossia.ai"},"access_token":"private"}""")) }
        val session = GlossiaSession(context, storage) { raw ->
            rawCalls.add(raw)
            val request = JSONObject(raw); calls.add(JSONObject(raw))
            val result = custom(request) ?: when (request.getString("operation")) {
                "restore" -> request.getJSONObject("session")
                "navigation" -> navigationFixture(request)
                "translation" -> JSONObject().put("session", translationRecord(request.getString("id")))
                "translation_reviews" -> JSONObject().put("reviews", JSONArray())
                "begin" -> JSONObject().put("authorization_url", "https://glossia.ai/oauth/authorize")
                    .put("registration", JSONObject().put("server", request.getString("server"))).put("pending", JSONObject())
                "validate_callback" -> JSONObject()
                "complete" -> JSONObject("""{"registration":{"server":"https://glossia.ai"},"access_token":"private"}""")
                "themes", "validate_themes" -> JSONObject("""{"error":{"kind":"network","message":"Theme unavailable"}}""")
                "workspace" -> {
                    val org = request.getJSONObject("selection").optionalString("organization") ?: "glossia"
                    JSONObject().put("organizations", JSONArray("""[{"handle":"glossia","name":"Glossia"},{"handle":"other","name":"Other team"}]"""))
                        .put("projects", JSONArray("""[{"handle":"website","name":"Website"},{"handle":"docs","name":"Documentation"}]"""))
                        .put("selection", JSONObject().put("organization", org)
                            .put("project", request.getJSONObject("selection").optionalString("project") ?: "website"))
                }
                "resource" -> when (request.getString("resource")) {
                    "conversations" -> JSONObject("""{"conversations":[],"meta":{"has_next_page":false}}""")
                    "translations" -> JSONObject("""{"sessions":[],"meta":{"has_next_page":false}}""")
                    "analytics" -> JSONObject("""{"summary":{"pageviews":0},"top_pages":[]}""")
                    else -> JSONObject("""{"user":{"name":"Test"},"server_version":"1.0"}""")
                }
                "conversation" -> conversation(request.getString("id"), "completed")
                else -> error("Unexpected operation: $request")
            }
            if (result.optJSONObject("error") != null) result.toString() else JSONObject().put("ok", result).toString()
        }
        sessions.add(session)
        if (restore) {
            session.restore()
            pump { !session.busy && if (signedIn) session.server != null && session.toki.history.loaded else session.server == null }
        }
        return session to storage
    }

    @Test fun linguisticAnswersPreserveIndependentGuidanceAndUseTypedResumedNavigation() {
        var answered = false
        val resumedId = "aaa12345-802e-4f91-9112-77d8a919efc5"
        val (session, _) = session { request ->
            if (request.optString("operation") == "conversation") goalConversation(if (answered) "answered" else "open").apply {
                if (answered) getJSONObject("conversation").getJSONObject("linguistic_review").put("resumed_session_id", resumedId)
            }
            else if (request.optString("operation") != "translation_reviews") null
            else if (request.optString("action") == "answer") {
                answered = true
                JSONObject().put("review", reviewRecord("answered").put("answer", request.getString("answer")).put("resumed_session_id", resumedId))
            } else JSONObject().put("reviews", JSONArray().put(reviewRecord(if (answered) "answered" else "open")
                .apply { if (answered) put("resumed_session_id", resumedId) }))
        }
        session.showTranslation(translationId); pump { session.translation.reviews.loaded }
        session.openReviewConversation(goalChatId); pump { session.toki.active?.loaded == true }
        val model = session.toki.active!!
        model.beginResolution()
        assertFalse(model.decision!!.reusable)
        model.decision!!.apply { answer = "Use tú"; reusable = true; guidance = "Use informal Spanish in onboarding."; scope = "project" }
        assertTrue(session.hasProtectedWork)
        session.back(); assertEquals(goalChatId, session.toki.activeId)
        session.saveGoalDecision(); pump { answered && model.goalClosed && !model.resolving && !model.busy }
        val write = calls.single { it.optString("operation") == "translation_reviews" && it.optString("action") == "answer" }
        assertEquals("Use tú", write.getString("answer")); assertEquals("Use informal Spanish in onboarding.", write.getString("guidance"))
        assertEquals("project", write.getString("context_scope")); assertFalse(session.hasProtectedWork)
        assertEquals(goalReplyId, write.getString("resolution_message_id"))
        session.showTranslation(resumedId); pump { session.translation.id == resumedId && session.translation.loaded }
        assertTrue(calls.any { it.optString("operation") == "navigation" && it.optString("action") == "link" &&
            it.optJSONObject("destination")?.optString("screen") == GlossiaScreen.TRANSLATION.wire &&
            it.optJSONObject("destination")?.optString("id") == resumedId })
    }

    @Test fun ambiguousReviewAnswerRequiresRefreshAndStaleWorkspaceResultCannotRestoreIt() {
        val started = CountDownLatch(1); val release = CountDownLatch(1).also(releases::add)
        var fail = true
        val (session, _) = session { request ->
            if (request.optString("operation") == "conversation") goalConversation()
            else if (request.optString("operation") != "translation_reviews") null
            else if (request.optString("action") == "list") JSONObject().put("reviews", JSONArray().put(reviewRecord()))
            else if (fail) { fail = false; failure("network") }
            else { started.countDown(); release.await(5, TimeUnit.SECONDS); JSONObject().put("review", reviewRecord("answered")) }
        }
        session.showConversation(goalChatId); pump { session.toki.active?.loaded == true }
        val model = session.toki.active!!
        model.beginResolution(); model.decision!!.answer = "Use tú"
        session.saveGoalDecision(); pump { model.resolutionNeedsRefresh }
        session.saveGoalDecision()
        assertEquals(1, calls.count { it.optString("operation") == "translation_reviews" && it.optString("action") == "answer" })
        val oneOff = calls.last { it.optString("action") == "answer" }
        assertFalse(oneOff.has("guidance")); assertFalse(oneOff.has("context_scope"))
        session.showConversation(goalChatId); pump { !model.busy && !model.resolutionNeedsRefresh }
        session.saveGoalDecision(); assertTrue(started.await(2, TimeUnit.SECONDS))
        session.signOut(); release.countDown(); pump { session.server == null && !session.busy }
        assertTrue(session.translation.reviews.items.isEmpty()); assertFalse(session.hasProtectedWork)
        assertFalse(ReviewDraft().apply { answer = " "; reusable = false }.valid)
        assertFalse(ReviewDraft().apply { answer = "Use tú"; reusable = true; guidance = "" }.valid)
    }

    @Test fun parallelRequestsDoNotBlockSignOutOrRestoreStaleModels() {
        val started = CountDownLatch(1); val release = CountDownLatch(1).also(releases::add)
        val (session, storage) = session { request ->
            if (request.optString("resource") == "translations") {
                started.countDown(); release.await(5, TimeUnit.SECONDS)
                JSONObject("""{"sessions":[{"id":"private-old"}],"meta":{}}""")
            } else null
        }
        session.selectTab("Translations"); assertTrue(started.await(2, TimeUnit.SECONDS))
        session.selectTab("Analytics"); pump { session.analytics.loaded }
        assertTrue(session.translations.busy)
        session.newConversation(); session.draft("Private draft")
        session.signOut(); pump { !session.busy && storage.load("session") == null }
        assertNull(session.server); assertNull(session.toki.active); assertFalse(session.analytics.loaded)
        release.countDown(); Thread.sleep(100); shadowOf(Looper.getMainLooper()).idle()
        assertTrue(session.translations.items.isEmpty()); assertNull(session.server)
    }

    @Test fun projectChangeFencesLateDataAndCancelPreservesDraft() {
        val (session, _) = session()
        session.newConversation(); session.draft("Keep my exact draft")
        val conversation = session.toki.active!!.id
        session.openWorkspacePicker(); session.browseOrganization("other")
        pump { !session.workspacePicker.busy }
        assertEquals("glossia", session.organization); assertEquals("website", session.project)
        assertEquals("Keep my exact draft", session.toki.active!!.draft)
        assertTrue(calls.any { it.optString("operation") == "workspace" && it.getJSONObject("selection").optionalString("organization") == "other" })
        session.closeWorkspacePicker()
        assertEquals(conversation, session.toki.active!!.id)
        session.openWorkspacePicker(); session.browseOrganization("other"); pump { !session.workspacePicker.busy }
        session.selectWorkspaceProject("docs")
        assertEquals("glossia", session.organization); assertEquals("Keep my exact draft", session.toki.active!!.draft)
        assertNotNull(session.navigationNotice)
        assertFalse(session.workspacePicker.open) // The root notice is not hidden behind a modal.
        session.draft("") // Explicitly finish the draft before changing workspace.
        session.openWorkspacePicker(); session.browseOrganization("other"); pump { !session.workspacePicker.busy }
        session.selectWorkspaceProject("docs")
        assertEquals("other", session.organization); assertEquals("docs", session.project)
        assertNull(session.toki.active); assertFalse(session.workspacePicker.open)
    }

    @Test fun retryRetainsExactConversationMessageUuidAndContentAndPreventsDoubleSend() {
        var failCreate = true; var failSend = true
        val (session, _) = session { request ->
            if (request.optString("operation") != "conversation") null else when (request.optString("action")) {
                "create" -> if (failCreate) { failCreate = false; JSONObject("""{"error":{"kind":"network","message":"Connection lost"}}""") } else null
                "send" -> if (failSend) { failSend = false; JSONObject("""{"error":{"kind":"network","message":"Reply lost"}}""") } else conversation(request.getString("id"), "queued")
                    .put("messages", JSONArray().put(JSONObject().put("id", request.getString("message_id")).put("role", "user").put("content", request.getString("content"))))
                else -> null
            }
        }
        session.newConversation(); session.draft("  Exact message 🌍  "); session.sendMessage(); session.sendMessage()
        pump { session.toki.active?.error != null }
        val pending = session.toki.active!!.pending!!; val id = session.toki.active!!.id
        session.selectTab("Analytics"); session.selectTab("Toki")
        assertNull(session.toki.active)
        session.showConversation(id)
        assertEquals(pending, session.toki.active!!.pending)
        session.sendMessage(); pump { session.toki.active?.error == "Reply lost" }
        session.sendMessage(); session.sendMessage(); pump { session.toki.active?.pending == null }
        val creates = calls.filter { it.optString("action") == "create" }
        val sends = calls.filter { it.optString("action") == "send" }
        assertEquals(2, creates.size); assertEquals(2, sends.size)
        assertTrue(creates.all { it.optString("id") == id })
        assertTrue(sends.all { it.optString("id") == id && it.optString("message_id") == pending.id && it.optString("content") == pending.content })
        assertEquals("", session.toki.active!!.draft)
        assertEquals("queued", session.toki.active!!.status)
    }

    @Test fun paginationDaysAndDraftsAreIndependent() {
        val pages = CopyOnWriteArrayList<Int>()
        val (session, _) = session { request ->
            if (request.optString("resource") == "translations") {
                val page = request.getInt("page"); pages.add(page)
                JSONObject().put("sessions", JSONArray().put(JSONObject().put("id", "page-$page")))
                    .put("meta", JSONObject().put("has_next_page?", page == 1))
            } else if (request.optString("resource") == "analytics") JSONObject().put("days", request.getInt("days")) else null
        }
        session.newConversation(); session.draft("Draft survives tabs")
        val draftId = session.toki.active!!.id
        session.selectTab("Translations"); pump { session.translations.loaded }
        session.loadPage(session.translations); pump { !session.translations.busy }
        session.loadPage(session.translations)
        assertEquals(listOf(1, 2), pages.toList()); assertEquals(2, session.translations.items.size)
        session.selectTab("Analytics"); session.setAnalyticsDays(90); pump { session.analytics.loaded && session.analytics.data?.optInt("days") == 90 }
        session.selectTab("Toki"); assertNull(session.toki.active)
        session.showConversation(draftId); assertEquals("Draft survives tabs", session.toki.active!!.draft)
    }

    @Test fun canonicalPaginationFlagTakesPrecedenceForTranslationsAndConversations() {
        for ((resource, collection) in listOf("translations" to "sessions", "conversations" to "conversations")) {
            val model = PageModel(resource, collection)
            fun accept(meta: String) = model.accept(JSONObject().put(collection, JSONArray()).put("meta", JSONObject(meta)), 1)
            accept("""{"has_next_page?":true}""")
            assertTrue(model.hasMore)
            accept("""{"has_next_page?":false,"has_next_page":true,"total_pages":2}""")
            assertFalse(model.hasMore)
            accept("""{"has_next_page":true}""")
            assertTrue(model.hasMore)
            accept("""{"total_pages":2}""")
            assertTrue(model.hasMore)
        }
    }

    @Test fun pollingStopsInBackgroundAndReportsFailedConversation() {
        var shows = 0
        val (session, _) = session { request ->
            if (request.optString("action") == "show") { shows += 1; conversation(request.getString("id"), if (shows > 1) "failed" else "running") } else null
        }
        session.showConversation("conversation"); pump { session.toki.active?.status == "running" }
        session.setForeground(false)
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofSeconds(10)); Thread.sleep(50)
        assertEquals(1, shows)
        session.setForeground(true)
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofSeconds(3))
        pump { session.toki.active?.status == "failed" }
        assertFalse(session.toki.active!!.running)
    }

    @Test fun staleAnalyticsResponseCannotOverwriteSelectedDays() {
        val started = CountDownLatch(1); val release = CountDownLatch(1).also(releases::add)
        val (session, _) = session { request ->
            if (request.optString("resource") == "analytics") {
                val days = request.getInt("days")
                if (days == 30) { started.countDown(); release.await(5, TimeUnit.SECONDS) }
                JSONObject().put("days", days)
            } else null
        }
        session.selectTab("Analytics"); assertTrue(started.await(2, TimeUnit.SECONDS))
        session.setAnalyticsDays(90); pump { session.analytics.loaded }
        assertEquals(90, session.analytics.data!!.getInt("days"))
        release.countDown(); Thread.sleep(100); shadowOf(Looper.getMainLooper()).idle()
        assertEquals(90, session.analytics.days); assertEquals(90, session.analytics.data!!.getInt("days"))
    }

    @Test fun rejectedOldSessionCannotDeleteReplacementCredentials() {
        val started = CountDownLatch(1); val release = CountDownLatch(1).also(releases::add)
        val (session, storage) = session { request ->
            if (request.optString("resource") == "translations") {
                started.countDown(); release.await(5, TimeUnit.SECONDS)
                JSONObject("""{"error":{"kind":"rejected","message":"Old token rejected"}}""")
            } else null
        }
        session.selectTab("Translations"); assertTrue(started.await(2, TimeUnit.SECONDS))
        session.signOut(); pump { !session.busy }
        storage.save("session", JSONObject("""{"registration":{"server":"https://new.example.com"},"access_token":"replacement"}"""))
        session.retryRestore(); pump { session.server == "https://new.example.com" && !session.busy }
        release.countDown(); Thread.sleep(100); shadowOf(Looper.getMainLooper()).idle()
        assertEquals("replacement", storage.load("session")!!.getString("access_token"))
        assertEquals("https://new.example.com", session.server)
    }

    @Test fun rejectedCurrentSessionClearsPrivateModelsAndCredentials() {
        val (session, storage) = session { request ->
            if (request.optString("resource") == "analytics") JSONObject("""{"error":{"kind":"rejected","message":"Sign in again"}}""") else null
        }
        session.newConversation(); session.draft("Sensitive draft")
        val oldThread = session.toki.active!!
        session.selectTab("Analytics"); pump { session.server == null }
        assertNull(storage.load("session")); assertNull(session.toki.active)
        assertEquals("", oldThread.draft); assertNull(oldThread.pending)
    }

    @Test fun authoritativeConversationDenialClearsPrivateDataButTransientFailuresRetainRetry() {
        for (denial in listOf("forbidden", "not_found")) {
            val failure = java.util.concurrent.atomic.AtomicReference<String?>(null)
            val id = "private-$denial"
            val (session, storage) = session { request ->
                when {
                    request.optString("resource") == "conversations" -> JSONObject()
                        .put("conversations", JSONArray().put(JSONObject().put("id", id).put("title", "Private title")))
                        .put("meta", JSONObject().put("has_next_page?", false))
                    request.optString("operation") == "conversation" -> failure.get()?.let { kind ->
                        JSONObject().put("error", JSONObject().put("kind", kind).put("message", "Request failed: $kind"))
                    } ?: conversation(id, "completed").put("messages", JSONArray().put(JSONObject()
                        .put("id", "private-message").put("role", "assistant").put("content", "Private reply")))
                    else -> null
                }
            }
            session.showConversation(id); pump { session.toki.active?.loaded == true }
            val thread = session.toki.active!!
            session.draft("Private draft")
            failure.set("network"); session.showConversation(id); pump { !thread.busy }
            assertEquals("Private reply", thread.messages.getJSONObject(0).getString("content"))
            assertEquals("Private draft", thread.draft)
            assertTrue(session.toki.history.items.any { it.optString("id") == id })

            fun assertCleared() {
                assertSame(thread, session.toki.active)
                assertEquals(id, session.toki.activeId)
                assertNull(thread.data); assertNull(thread.conversation)
                assertEquals(0, thread.messages.length()); assertEquals("", thread.draft); assertNull(thread.pending)
                assertTrue(thread.unavailable); assertFalse(thread.busy)
                assertTrue(thread.error!!.contains("no longer available"))
                assertTrue(session.toki.history.items.none { it.optString("id") == id })
                assertEquals(0, session.toki.history.data!!.getJSONArray("conversations").length())
                assertNotNull(storage.load("session")); assertNotNull(session.server)
            }
            failure.set(denial); session.showConversation(id); pump { !thread.busy }
            assertCleared()
            session.loadPage(session.toki.history, refresh = true); pump { !session.toki.history.busy }
            assertCleared() // A late/stale history response cannot restore its private title.

            failure.set(null); session.showConversation(id); pump { !thread.busy }
            assertTrue(thread.loaded); assertFalse(thread.unavailable); assertNull(thread.error)
            session.draft("Exact retry draft 🌍")
            failure.set("network"); session.sendMessage(); pump { !thread.busy }
            val pending = thread.pending!!
            failure.set("server"); session.sendMessage(); pump { !thread.busy }
            assertSame(pending, thread.pending); assertEquals(pending.content, thread.draft)
            assertEquals("Private reply", thread.messages.getJSONObject(0).getString("content"))
            failure.set(denial); session.sendMessage(); pump { !thread.busy }
            assertCleared()
            val sends = calls.filter { it.optString("action") == "send" && it.optString("id") == id }
            assertEquals(3, sends.size)
            assertTrue(sends.all { it.optString("message_id") == pending.id && it.optString("content") == pending.content })
        }
    }

    @Test fun draftAndRetryIdentitySurviveViewRecreation() {
        val model = TokiModel()
        val thread = model.newConversation().apply {
            draft = "Retain this exact draft"
            pending = PendingMessage("same-client-uuid", draft)
            error = "Offline"
        }
        repeat(2) {
            val controller = Robolectric.buildActivity(RenderActivity::class.java).setup()
            val activity = controller.get()
            val view = TokiView(activity, model, { model.active!!.draft = it }, {}, {}, {}, {})
            activity.setContentView(view); view.render(true)
            assertEquals(thread.draft, findInput(view)!!.text.toString())
            assertFalse(findInput(view)!!.isEnabled)
            assertEquals("same-client-uuid", model.active!!.pending!!.id)
            controller.pause().stop().destroy()
        }
    }

    private fun findInput(view: View): TextInputEditText? = when (view) {
        is TextInputEditText -> view
        is ViewGroup -> (0 until view.childCount).firstNotNullOfOrNull { findInput(view.getChildAt(it)) }
        else -> null
    }

    @Test @Config(application = GlossiaApplication::class)
    fun tokiToolbarOpensNewConversationAndListResumesDraftsWithoutPrematureWritesOrDuplicateRows() {
        ShadowChoreographer.setFrameDelay(Duration.ofMillis(16))
        for (populated in listOf(false, true)) {
            var savedDraftId: String? = null
            val (session, _) = session { request ->
                when {
                    request.optString("resource") == "conversations" -> {
                        val items = JSONArray()
                        if (populated) {
                            items.put(JSONObject().put("id", conversationId).put("title", "Saved conversation"))
                            items.put(JSONObject().put("id", translationId).put("title", "Empty saved conversation"))
                        }
                        savedDraftId?.let { items.put(JSONObject().put("id", it).put("title", "A conversation with Toki")) }
                        JSONObject().put("conversations", items).put("meta", JSONObject())
                    }
                    request.optString("action") == "send" -> {
                        savedDraftId = request.getString("id")
                        failure("network", "Reply unconfirmed")
                    }
                    request.optString("action") == "show" && request.optString("id") == conversationId ->
                        conversation(conversationId, "completed").put("messages", JSONArray().put(JSONObject()
                            .put("id", "saved-reply").put("role", "assistant").put("content", "A saved reply")))
                    else -> null
                }
            }
            // Inject only the transport-backed session. All actions below use
            // the real Activity toolbar, bottom tabs, Back dispatcher and views.
            org.robolectric.util.ReflectionHelpers.setField(context, "session\$delegate", lazyOf(session))
            val controller = Robolectric.buildActivity(MainActivity::class.java).setup()
            val activity = controller.get()
            val toolbar = activity.findViewById<MaterialToolbar>(R.id.toolbar)
            val navigation = activity.findViewById<BottomNavigationView>(R.id.navigation)
            val screen = activity.findViewById<FrameLayout>(R.id.screen)
            fun view() = screen.getChildAt(0)
            fun texts() = descendants(view()).filterIsInstance<TextView>().map { it.text.toString() }
            fun rows() = descendants(view()).filterIsInstance<MaterialCardView>().filter { it.isClickable }
            fun assertList() {
                assertEquals("Your conversations", texts().first())
                assertTrue(descendants(view()).filterIsInstance<TokiCompanionView>().isEmpty())
                assertTrue(descendants(view()).filterIsInstance<com.google.android.material.chip.Chip>().isEmpty())
                assertNull(findInput(view())); assertNull(toolbar.navigationIcon)
                assertTrue(toolbar.menu.findItem(R.id.compose_conversation).isVisible)
            }
            val writesBefore = calls.count { it.optString("action") in listOf("create", "send") }
            assertList(); assertEquals(if (populated) 2 else 0, rows().size)
            if (!populated) assertTrue(texts().any { it.contains("Compose in the toolbar") })
            ShadowChoreographer.setPaused(true)
            assertTrue(toolbar.menu.performIdentifierAction(R.id.compose_conversation, 0))
            val thread = session.toki.active!!
            assertEquals("New conversation", toolbar.title)
            assertNotNull(toolbar.navigationIcon); assertFalse(thread.created)
            assertFalse(toolbar.menu.findItem(R.id.compose_conversation).isVisible)
            assertTrue(texts().contains("Hi, I’m Toki"))
            val root = activity.findViewById<View>(R.id.root)
            root.measure(View.MeasureSpec.makeMeasureSpec(1080, View.MeasureSpec.EXACTLY), View.MeasureSpec.makeMeasureSpec(2340, View.MeasureSpec.EXACTLY))
            root.layout(0, 0, 1080, 2340)
            advanceFrames(32)
            val rig = descendants(view()).filterIsInstance<TokiCompanionView>().single()
            assertTrue(rig.performClick()); assertEquals("Waving hello", ViewCompat.getStateDescription(rig))
            descendants(view()).filterIsInstance<com.google.android.material.chip.Chip>().first().performClick()
            assertEquals("Help me get started", thread.draft)
            assertEquals(thread.draft, findInput(view())!!.text.toString())
            assertFalse(findInput(view())!!.isSaveEnabled)
            assertEquals(View.IMPORTANT_FOR_AUTOFILL_NO_EXCLUDE_DESCENDANTS, findInput(view())!!.importantForAutofill)
            assertNull(thread.pending); assertFalse(thread.created)
            ShadowChoreographer.setPaused(false)
            advanceFrames(32) // Deliver Activity window traversals before waiting on network callbacks.
            activity.onBackPressedDispatcher.onBackPressed()
            assertList(); assertNull(session.toki.active)
            assertFalse(texts().contains("No conversations yet")) // A local-only draft is a real list row.
            rows().single { it.contentDescription.contains("Draft · Saved on this device") }.performClick()
            assertSame(thread, session.toki.active)
            assertEquals("Help me get started", findInput(view())!!.text.toString())
            navigation.selectedItemId = R.id.analytics
            navigation.selectedItemId = R.id.toki
            assertList(); assertEquals("Help me get started", thread.draft)
            rows().single { it.contentDescription.contains("Draft · Saved on this device") }.performClick()
            assertSame(thread, session.toki.active)
            assertEquals(writesBefore, calls.count { it.optString("action") in listOf("create", "send") })

            // Only explicit Send creates a server conversation. If its message
            // response is lost, merge its history row with the same local retry.
            val send = descendants(view()).single { it.contentDescription == "Send message" }
            assertTrue(send.isEnabled); assertTrue(send.performClick())
            assertNotNull(thread.pending)
            pump { thread.error != null }
            val pending = thread.pending!!
            assertTrue(thread.created)
            activity.onBackPressedDispatcher.onBackPressed()
            session.loadPage(session.toki.history, refresh = true); pump { !session.toki.history.busy }
            assertList(); assertEquals(if (populated) 3 else 1, rows().size)
            val retryRow = rows().single { it.contentDescription.contains("Unconfirmed message · Retry available") }
            retryRow.performClick()
            assertSame(thread, session.toki.active); assertSame(pending, thread.pending)
            assertFalse(findInput(view())!!.isEnabled)
            assertFalse(texts().contains("Hi, I’m Toki"))
            activity.onBackPressedDispatcher.onBackPressed()
            if (populated) {
                rows().single { it.contentDescription.startsWith("Saved conversation.") }.performClick()
                pump { session.toki.active?.loaded == true }
                assertTrue(texts().contains("A saved reply")); assertFalse(texts().contains("Hi, I’m Toki"))
                findInput(view())!!.setText("Keep this existing draft")
                descendants(toolbar).single { it.contentDescription == "Back to conversations" }.performClick()
                assertList(); assertEquals(3, rows().size)
                rows().single { it.contentDescription.startsWith("Saved conversation.") && it.contentDescription.contains("Draft · Saved on this device") }.performClick()
                pump { session.toki.active?.busy == false }
                assertEquals("Keep this existing draft", findInput(view())!!.text.toString())
                activity.onBackPressedDispatcher.onBackPressed()
                rows().single { it.contentDescription.startsWith("Empty saved conversation.") }.performClick()
                pump { session.toki.active?.loaded == true }
                assertFalse(texts().contains("Hi, I’m Toki"))
                assertTrue(descendants(view()).filterIsInstance<TokiCompanionView>().isEmpty())
                activity.onBackPressedDispatcher.onBackPressed(); assertList()
            }
            controller.pause().stop().destroy()
        }
    }

    @Test @Config(application = GlossiaApplication::class)
    fun tokiListRequiresProjectSelectionBeforeCompose() {
        val (session, _) = session(restore = false) { request ->
            if (request.optString("operation") == "workspace") JSONObject()
                .put("organizations", JSONArray()).put("projects", JSONArray())
                .put("selection", JSONObject().put("organization", JSONObject.NULL).put("project", JSONObject.NULL))
            else null
        }
        session.restore(); pump { !session.busy && session.server != null }
        org.robolectric.util.ReflectionHelpers.setField(context, "session\$delegate", lazyOf(session))
        val controller = Robolectric.buildActivity(MainActivity::class.java).setup()
        val activity = controller.get()
        val toolbar = activity.findViewById<MaterialToolbar>(R.id.toolbar)
        assertTrue(toolbar.menu.findItem(R.id.compose_conversation).isVisible)
        assertFalse(toolbar.menu.findItem(R.id.compose_conversation).isEnabled)
        assertTrue(descendants(activity.findViewById(R.id.screen)).filterIsInstance<TextView>()
            .any { it.text.contains("Choose an organization and project") })
        session.newConversation(); session.draft("Not in a project"); session.sendMessage()
        assertNull(session.toki.active); assertTrue(session.toki.threads.isEmpty())
        assertFalse(calls.any { it.optString("operation") == "conversation" || it.optString("resource") == "conversations" })
        controller.pause().stop().destroy()
    }

    private fun appearance(now: () -> Long = { 1_000L }, handler: (JSONObject) -> JSONObject): GlossiaAppearance =
        GlossiaAppearance(context, { raw ->
            val result = handler(JSONObject(raw))
            if (result.has("error")) result.toString() else JSONObject().put("ok", result).toString()
        }, now).also(appearances::add)

    private fun catalog(revision: String = "forest-1"): JSONObject = JSONObject("""{
        "schema_version":1,"revision":"$revision","default_theme_id":"glossia","themes":[{
          "id":"glossia","name":"Forest","description":"A self-hosted forest palette","typography":"standard",
          "button_radius":8,"card_radius":12,
          "light":{"background":"#F0F7F5","surface":"#FFFFFF","subtle":"#E1EEEA","text":"#102A24","secondary_text":"#3E5C52","border":"#8FA99F","accent":"#006B52","on_accent":"#FFFFFF","tint":"#005C46"},
          "dark":{"background":"#0A201A","surface":"#15382E","subtle":"#20483B","text":"#F0FFF8","secondary_text":"#BDD6CA","border":"#628A77","accent":"#7DE5B9","on_accent":"#00291C","tint":"#A1F0CD"}
        }] }""")

    @Test fun originIdentityRejectsNonOriginsWithoutLosingCurrentTheme() {
        val requests = CopyOnWriteArrayList<JSONObject>()
        val owner = appearance { requests.add(it); catalog() }
        owner.configure(" HTTPS://THEMES.EXAMPLE:443/ "); pump { owner.catalog != null }
        assertEquals("https://themes.example", owner.server)
        assertEquals("https://themes.example", requests.single().getString("server"))
        for (address in listOf("http://themes.example", "https://user@themes.example", "https://themes.example/path",
            "https://themes.example//", "https://themes.example?", "https://themes.example/#fragment", "https://themes.example:0")) {
            owner.configure(address)
            assertEquals("https://themes.example", owner.server)
        }
        owner.configure("https://themes.example/"); owner.refresh()
        assertEquals(1, requests.size)
        assertEquals("https://themes.example:8443", GlossiaAppearance.normalizeOrigin("https://THEMES.EXAMPLE:8443/"))
    }

    @Test fun validatedCacheSurvivesNetworkFailureAndInvalidCacheFallsBack() {
        val preferences = context.getSharedPreferences("glossia.appearance", 0)
        preferences.edit().clear().putString("https://cache.example.catalog", catalog("cached").toString()).commit()
        val operations = CopyOnWriteArrayList<String>()
        val owner = appearance { request ->
            operations.add(request.getString("operation"))
            if (request.getString("operation") == "validate_themes") {
                assertEquals("cached", request.getJSONObject("catalog").getString("revision"))
                catalog("normalized-by-rust")
            } else JSONObject("""{"error":{"kind":"rejected","message":"Unavailable"}}""")
        }
        owner.configure("https://CACHE.example/")
        pump { owner.catalog?.optString("revision") == "normalized-by-rust" && operations.size == 2 }
        assertEquals(listOf("validate_themes", "themes"), operations.toList())
        assertEquals("normalized-by-rust", owner.catalog!!.getString("revision"))
        owner.close()
        for (cached in listOf("not JSON", catalog("invalid").toString(), "x".repeat(65_537))) {
            preferences.edit().putString("https://bad.example.catalog", cached).commit()
            val network = CountDownLatch(1)
            val bad = appearance { network.countDown(); JSONObject("""{"error":{"kind":"validation","message":"Invalid"}}""") }
            bad.configure("https://bad.example")
            pump { network.count == 0L }
            assertNull(bad.catalog)
            assertNull(bad.color(context, R.color.glossia_background))
            bad.close()
        }
    }

    @Test fun slowOldOriginCannotBlockOrOverwriteNewOriginOrItsCache() {
        context.getSharedPreferences("glossia.appearance", 0).edit().clear().commit()
        val started = CountDownLatch(1); val release = CountDownLatch(1).also(releases::add)
        val finished = CountDownLatch(1)
        val owner = appearance { request ->
            if (request.getString("server") == "https://old.example") {
                started.countDown(); release.await(5, TimeUnit.SECONDS); finished.countDown(); catalog("old")
            } else catalog("new")
        }
        owner.configure("https://old.example"); pump { started.count == 0L }
        owner.configure("https://new.example"); pump { owner.catalog?.optString("revision") == "new" }
        assertEquals(1L, release.count) // New origin completed while old origin is still blocked.
        release.countDown(); pump { finished.count == 0L }
        Thread.sleep(50); shadowOf(Looper.getMainLooper()).idle()
        assertEquals("new", owner.catalog!!.getString("revision"))
        val preferences = context.getSharedPreferences("glossia.appearance", 0)
        assertFalse(preferences.contains("https://old.example.catalog"))
        assertEquals("new", JSONObject(preferences.getString("https://new.example.catalog", "")!!).getString("revision"))
    }

    @Test fun refreshIsThrottledForFiveMinutesAndKeepsLastGoodCatalogOnFailure() {
        context.getSharedPreferences("glossia.appearance", 0).edit().clear().commit()
        val clock = AtomicLong(1_000); val count = AtomicInteger()
        val owner = appearance(clock::get) {
            val attempt = count.incrementAndGet()
            if (attempt == 3) JSONObject("""{"error":{"kind":"network","message":"Offline"}}""") else catalog("revision-$attempt")
        }
        owner.configure("https://refresh.example"); pump { owner.catalog?.optString("revision") == "revision-1" }
        repeat(5) { owner.refresh() }; clock.addAndGet(299_999); owner.refresh()
        assertEquals(1, count.get())
        clock.incrementAndGet(); owner.refresh(); pump { owner.catalog?.optString("revision") == "revision-2" }
        clock.addAndGet(300_000); owner.refresh(); pump { count.get() == 3 }
        Thread.sleep(50); shadowOf(Looper.getMainLooper()).idle()
        assertEquals("revision-2", owner.catalog!!.getString("revision"))
        owner.refresh(); Thread.sleep(50); assertEquals(3, count.get())
        clock.addAndGet(300_000); owner.refresh(); pump { owner.catalog?.optString("revision") == "revision-4" }
    }

    @Test fun themeRequestsNeverBlockCredentialsOrRejectSessionsAndSignInConfiguresOrigin() {
        val started = CountDownLatch(1); val release = CountDownLatch(1).also(releases::add)
        val (session, storage) = session { request ->
            when (request.getString("operation")) {
                "themes" -> {
                    started.countDown(); release.await(5, TimeUnit.SECONDS)
                    JSONObject("""{"error":{"kind":"rejected","message":"Theme endpoint rejected"}}""")
                }
                "begin" -> JSONObject().put("authorization_url", "https://self.example/oauth/authorize")
                    .put("registration", JSONObject().put("server", "https://self.example")).put("pending", JSONObject())
                else -> null
            }
        }
        pump { started.count == 0L }
        assertEquals("https://glossia.ai", session.appearance.server)
        session.newConversation(); session.draft("Preserve this private draft")
        session.selectTab("Analytics"); pump { session.analytics.loaded }
        session.signIn("HTTPS://SELF.EXAMPLE/")
        assertEquals("https://self.example", session.appearance.server)
        pump { session.authorizationURL != null && !session.busy }
        assertEquals(1L, release.count)
        release.countDown(); Thread.sleep(100); shadowOf(Looper.getMainLooper()).idle()
        assertEquals("https://glossia.ai", session.server); assertNotNull(storage.load("session"))
        assertEquals("Preserve this private draft", session.toki.active!!.draft); assertNull(session.error)
        session.setForeground(false); session.setForeground(true)
        assertEquals(2, calls.count { it.optString("operation") == "themes" })
        session.setForeground(false)
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofSeconds(300))
        session.setForeground(true)
        pump { calls.count { it.optString("operation") == "themes" } == 3 }
        assertNotNull(storage.load("session"))
    }

    @Test fun cachedCatalogsStayOriginScopedAcrossAppearanceInstances() {
        val preferences = context.getSharedPreferences("glossia.appearance", 0)
        preferences.edit().clear().commit()
        val first = appearance { catalog(it.getString("server")) }
        first.configure("https://one.example"); pump { first.catalog != null }
        first.configure("https://two.example"); pump { first.catalog?.optString("revision") == "https://two.example" }
        first.close()
        val second = appearance {
            if (it.getString("operation") == "validate_themes") it.getJSONObject("catalog")
            else JSONObject("""{"error":{"kind":"network","message":"Offline"}}""")
        }
        second.configure("https://ONE.EXAMPLE/"); pump { second.catalog != null }
        assertEquals("https://one.example", second.catalog!!.getString("revision"))
        second.configure("https://two.example"); pump { second.catalog != null }
        assertEquals("https://two.example", second.catalog!!.getString("revision"))
    }

    @Test fun refreshedThemeRepaintsExistingLoginDialogAndComposerWithoutLosingDraftOrSelection() {
        context.getSharedPreferences("glossia.appearance", 0).edit().clear().commit()
        val controller = Robolectric.buildActivity(RenderActivity::class.java).setup()
        val activity = controller.get()
        val clock = AtomicLong(1_000); val count = AtomicInteger()
        activity.appearance.close()
        val owner = appearance(clock::get) {
            catalog("revision-${count.incrementAndGet()}").apply {
                getJSONArray("themes").getJSONObject(0).getJSONObject("light")
                    .put("accent", if (count.get() == 1) "#006B52" else "#174B91")
            }
        }
        activity.appearance = owner
        val root = activity.layoutInflater.inflate(R.layout.activity_main, null)
        activity.setContentView(root)
        val screen = root.findViewById<FrameLayout>(R.id.screen)
        val login = GlossiaLoginView(activity, {}, {}, {}, {})
        screen.addView(login)
        owner.listener = { owner.apply(activity, root) }
        owner.configure("https://live.example"); pump { owner.catalog?.optString("revision") == "revision-1" }
        val primary = descendants(login).filterIsInstance<MaterialButton>().first { it.getTag(R.id.appearance_primary) == true }
        assertEquals(Color.parseColor("#006B52"), primary.backgroundTintList!!.defaultColor)
        val form = activity.layoutInflater.inflate(R.layout.dialog_server, null)
        val address = form.findViewById<TextInputEditText>(R.id.server_address)
        val dialog = activity.themed(MaterialAlertDialogBuilder(activity).setTitle("Self-hosted server").setView(form).setPositiveButton("Sign in", null).show())
        address.setText("https://keep.example"); address.setSelection(8)
        clock.addAndGet(300_000); owner.refresh(); pump { owner.catalog?.optString("revision") == "revision-2" }
        assertSame(primary, descendants(login).filterIsInstance<MaterialButton>().first { it.getTag(R.id.appearance_primary) == true })
        assertEquals(Color.parseColor("#174B91"), primary.backgroundTintList!!.defaultColor)
        assertEquals("https://keep.example", address.text.toString()); assertEquals(8, address.selectionStart)
        assertEquals(activity.token(R.color.glossia_text), address.currentTextColor)
        dialog.dismiss()
        val model = TokiModel()
        model.newConversation()
        val view = TokiView(activity, model, { model.active!!.draft = it }, {}, {}, {}, {})
        screen.removeAllViews(); screen.addView(view); view.render(true)
        val input = findInput(view)!!
        input.setText("My exact private draft 🌍"); input.setSelection(5)
        val pending = PendingMessage("unchanged-uuid", "Not confirmed")
        model.active!!.pending = pending
        owner.listener = { view.render(true); owner.apply(activity, root) }
        clock.addAndGet(300_000); owner.refresh(); pump { owner.catalog?.optString("revision") == "revision-3" }
        assertSame(input, findInput(view)); assertEquals(5, input.selectionStart)
        assertEquals("My exact private draft 🌍", input.text.toString()); assertSame(pending, model.active!!.pending)
        assertFalse(input.isEnabled)
        controller.pause().stop().destroy()
    }

    private fun descendants(view: View): List<View> = listOf(view) +
        if (view is ViewGroup) (0 until view.childCount).flatMap { descendants(view.getChildAt(it)) } else emptyList()

    private fun rendered(view: View) = Bitmap.createBitmap(view.width, view.height, Bitmap.Config.ARGB_8888).also {
        view.draw(Canvas(it))
    }

    // Paused Robolectric vsync is delivered when the fixture clock advances.
    // Tick it in display-sized steps, not one jump straight to the final frame.
    private fun advanceFrames(millis: Long) {
        var remaining = millis
        while (remaining > 0) {
            val step = minOf(16, remaining)
            shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(step))
            remaining -= step
        }
    }

    @Test fun tokiHeroActuallyWavesContinuouslyOnRepeatedClicksAndSettlesWithoutSending() {
        // Use real animator frames on the fixture clock instead of Robolectric's
        // default instant-completion vsync behavior.
        ShadowChoreographer.setPaused(true)
        ShadowChoreographer.setFrameDelay(Duration.ofMillis(16))
        val controller = Robolectric.buildActivity(RenderActivity::class.java).setup()
        val activity = controller.get()
        val model = TokiModel()
        val thread = model.newConversation()
        val hero = TokiView(activity, model, { fail("Greeting must not change drafts") }, { fail("Greeting must not send") },
            { fail("Greeting must not open a conversation") }, {}, {})
        activity.setContentView(hero); hero.render(true)
        hero.measure(View.MeasureSpec.makeMeasureSpec(1080, View.MeasureSpec.EXACTLY), View.MeasureSpec.makeMeasureSpec(2340, View.MeasureSpec.EXACTLY))
        hero.layout(0, 0, 1080, 2340)
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(32))
        val rig = descendants(hero).filterIsInstance<TokiCompanionView>().single()
        assertTrue(descendants(hero).filterIsInstance<TextView>().any { it.text == "Tap Toki to say hello" })
        val info = rig.createAccessibilityNodeInfo()
        assertEquals("Toki", info.contentDescription); assertEquals("android.widget.Button", info.className)
        assertTrue(info.actionList.any { it.id == AccessibilityNodeInfo.ACTION_CLICK && it.label == "Say hello" })
        val rest = rendered(rig)
        assertTrue(rig.performAccessibilityAction(AccessibilityNodeInfo.ACTION_CLICK, null))
        assertEquals("Waving hello", ViewCompat.getStateDescription(rig))
        advanceFrames(480)
        assertEquals("Greeting must remain active while the arm is raised", "Waving hello", ViewCompat.getStateDescription(rig))
        val raised = rendered(rig)
        assertFalse("The articulated rig must visibly move, not just announce a greeting", rest.sameAs(raised))
        // The raised right arm enters space above the resting shoulder. A whole
        // image tilt of two degrees cannot satisfy this pixel observation.
        fun ink(bitmap: Bitmap) = (340 until 500).sumOf { x -> (80 until 230).count { y ->
            Color.alpha(bitmap.getPixel(x * bitmap.width / 512, y * bitmap.height / 512)) > 100
        } }
        assertTrue("Right arm should rise independently above its shoulder", ink(raised) > ink(rest) + 200)
        assertTrue(rig.performClick())
        assertTrue("Repeated taps must preserve the current pose", raised.sameAs(rendered(rig)))
        assertEquals("Happy to see you", ViewCompat.getStateDescription(rig))
        advanceFrames(2100)
        assertEquals("Happy to see you", ViewCompat.getStateDescription(rig)) // Old settlement was cancelled.
        advanceFrames(350)
        assertEquals("Ready to help", ViewCompat.getStateDescription(rig))
        assertTrue("Greeting must settle exactly to the neutral rig", rest.sameAs(rendered(rig)))
        val now = android.os.SystemClock.uptimeMillis()
        for (action in listOf(MotionEvent.ACTION_DOWN, MotionEvent.ACTION_UP)) {
            val event = MotionEvent.obtain(now, now, action, rig.width / 2f, rig.height / 2f, 0)
            assertTrue(rig.dispatchTouchEvent(event)); event.recycle()
        }
        advanceFrames(32)
        assertEquals("A native touch click must also greet", "Waving hello", ViewCompat.getStateDescription(rig))
        assertSame(thread, model.active); assertFalse(thread.created); assertEquals("", thread.draft); assertNull(thread.pending)
        controller.pause().stop().destroy()
    }

    @Test fun tokiReducedMotionIsStaticAndVisibilityBackgroundAndDetachCancelGreetings() {
        ShadowChoreographer.setPaused(true)
        ShadowChoreographer.setFrameDelay(Duration.ofMillis(16))
        val controller = Robolectric.buildActivity(RenderActivity::class.java).setup()
        val activity = controller.get()
        val rig = TokiCompanionView(activity)
        val column = activity.column().apply {
            addView(rig, android.widget.LinearLayout.LayoutParams(512, 512))
            addView(View(activity), android.widget.LinearLayout.LayoutParams(512, 3000))
        }
        val scroll = activity.scroll(column)
        activity.setContentView(scroll)
        scroll.measure(View.MeasureSpec.makeMeasureSpec(1080, View.MeasureSpec.EXACTLY), View.MeasureSpec.makeMeasureSpec(1800, View.MeasureSpec.EXACTLY))
        scroll.layout(0, 0, 1080, 1800)
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(32))
        val rest = rendered(rig)
        val resolver = activity.contentResolver
        val original = Settings.Global.getFloat(resolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f)
        try {
            Settings.Global.putFloat(resolver, Settings.Global.ANIMATOR_DURATION_SCALE, 0f)
            assertTrue(rig.performClick())
            val reduced = rendered(rig)
            assertFalse(rest.sameAs(reduced))
            shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(1000))
            assertTrue("Reduced motion is a static reaction, not a wave loop", reduced.sameAs(rendered(rig)))
            shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(1500))
            assertEquals("Ready to help", ViewCompat.getStateDescription(rig))
            assertTrue(rest.sameAs(rendered(rig)))
            Settings.Global.putFloat(resolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f)
            assertTrue(rig.performClick())
            advanceFrames(480)
            Settings.Global.putFloat(resolver, Settings.Global.ANIMATOR_DURATION_SCALE, 0f)
            resolver.notifyChange(Settings.Global.getUriFor(Settings.Global.ANIMATOR_DURATION_SCALE), null)
            shadowOf(Looper.getMainLooper()).idle()
            val changed = rendered(rig)
            advanceFrames(500)
            assertTrue("Disabling system animations mid-greeting must stop motion", changed.sameAs(rendered(rig)))
            Settings.Global.putFloat(resolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f)
            for (hide in listOf<() -> Unit>({ rig.visibility = View.INVISIBLE },
                { rig.dispatchWindowVisibilityChanged(View.INVISIBLE) }, { scroll.scrollTo(0, 1400) }, { controller.pause() },
                { column.removeView(rig) })) {
                rig.visibility = View.VISIBLE
                rig.dispatchWindowVisibilityChanged(View.VISIBLE)
                scroll.scrollTo(0, 0)
                assertTrue(rig.performClick())
                advanceFrames(480)
                hide()
                advanceFrames(32)
                assertEquals("Hiding must cancel immediately, not wait for settlement", "Ready to help", ViewCompat.getStateDescription(rig))
                shadowOf(Looper.getMainLooper()).idleFor(Duration.ofSeconds(3))
                assertEquals("Hidden greeting must be cancelled", "Ready to help", ViewCompat.getStateDescription(rig))
                assertFalse(rig.performClick())
                assertTrue(rest.sameAs(rendered(rig)))
                if (activity.lifecycle.currentState == androidx.lifecycle.Lifecycle.State.STARTED) controller.resume()
            }
            column.addView(rig, 0, android.widget.LinearLayout.LayoutParams(512, 512))
            shadowOf(Looper.getMainLooper()).idle()
            assertTrue("A reattached companion can greet again", rig.performClick())
        } finally {
            Settings.Global.putFloat(resolver, Settings.Global.ANIMATOR_DURATION_SCALE, original)
            controller.pause().stop().destroy()
        }
    }

    @Test fun navigationUsesCoreValidationAndSeparatesOAuthFromColdWarmAndHistoryIntents() {
        val (session, _) = session()
        val callbacks = mutableListOf<String>()
        val valid = fixtureLink(destination(GlossiaScreen.TRANSLATION, id = translationId))
        fun intent(url: String, flags: Int = 0) = Intent(Intent.ACTION_VIEW, Uri.parse(url)).addFlags(flags)
        val cold = intent(valid)
        GlossiaIntents.consume(cold, session::receiveLink, callbacks::add)
        pump { session.translation.loaded }
        assertNull(cold.data)
        GlossiaIntents.consume(cold, session::receiveLink, callbacks::add)
        assertEquals(1, calls.count { it.optString("action") == "parse" })
        val oauth = "glossia://oauth/callback?code=private&state=state"
        GlossiaIntents.consume(intent(oauth), session::receiveLink, callbacks::add)
        assertEquals(listOf(oauth), callbacks)
        assertEquals(1, calls.count { it.optString("action") == "parse" })
        val warm = fixtureLink(destination(GlossiaScreen.PROFILE))
        GlossiaIntents.consume(intent(warm), session::receiveLink, callbacks::add)
        pump { session.tab == "Profile" }
        GlossiaIntents.consume(intent(valid, Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY), session::receiveLink, callbacks::add)
        assertEquals("Profile", session.tab)
        for (url in listOf("https://glossia.ai/open/toki", "glossia://navigate/profile", "glossia://oauth/callback/extra?code=bad",
            "glossia://user@oauth/callback?code=bad", "glossia://oauth:443/callback?code=bad", "glossia://oauth/callback#fragment",
            "$valid&server=https://evil.example", "$valid#fragment")) {
            session.dismissNavigationNotice()
            GlossiaIntents.consume(intent(url), session::receiveLink, callbacks::add)
            pump { session.navigationNotice != null }
            assertEquals("Profile", session.tab)
        }
        assertEquals(listOf(oauth), callbacks)
        assertFalse(calls.any { it.optString("operation") == "begin" || it.optString("action") in listOf("create", "send") })
    }

    @Test fun pendingLatestLinkWaitsForSignInAndExactWorkspaceReadiness() {
        val workspaceStarted = CountDownLatch(1); val release = CountDownLatch(1).also(releases::add)
        val (session, storage) = session(signedIn = false) { request ->
            if (request.optString("operation") == "workspace" && request.getJSONObject("selection").optionalString("organization") == null) {
                workspaceStarted.countDown(); release.await(5, TimeUnit.SECONDS)
                null
            } else null
        }
        session.receiveLink(fixtureLink(destination(GlossiaScreen.TRANSLATION, id = translationId)))
        pump { session.pendingDestination?.id == translationId }
        session.receiveLink(fixtureLink(destination(GlossiaScreen.NEW_CONVERSATION, org = "other", project = "docs", source = translationId)))
        pump { session.pendingDestination?.screen == GlossiaScreen.NEW_CONVERSATION }
        assertNull(session.toki.active); assertFalse(calls.any { it.optString("operation") == "workspace" })
        session.signIn("https://glossia.ai"); pump { !session.busy && storage.load("pending") != null }
        session.callback("glossia://oauth/callback?code=fixture&state=fixture")
        pump { workspaceStarted.count == 0L }
        assertNull(session.organization); assertNull(session.toki.active)
        release.countDown()
        pump { session.toki.active?.source?.loaded == true }
        assertEquals("other", session.organization); assertEquals("docs", session.project)
        assertNull(session.pendingDestination); assertEquals("Toki", session.tab)
        assertEquals(translationId, session.toki.active!!.translationSessionId)
        assertFalse(session.toki.active!!.created)
        assertFalse(calls.any { it.optString("action") in listOf("create", "send") })
    }

    @Test fun linkedColdLaunchStillRestoresSavedCredentials() {
        val (session, _) = session(restore = false)
        session.receiveLink(fixtureLink(destination(GlossiaScreen.TRANSLATION, id = translationId)))
        pump { session.pendingDestination != null }
        session.restore()
        pump { session.translation.loaded }
        assertEquals("https://glossia.ai", session.server)
        assertEquals("Translations", session.tab); assertEquals(translationId, session.translation.id)
    }

    @Test fun originMismatchIsActionableAndNeverSwitchesServerOrStartsLogin() {
        val (session, _) = session()
        session.receiveLink(fixtureLink(destination(GlossiaScreen.CONVERSATION, id = conversationId, server = "https://other.example:4443/")))
        pump { session.navigationNotice != null }
        assertTrue(session.navigationNotice!!.contains("Sign out")); assertTrue(session.navigationNotice!!.contains("https://other.example:4443/"))
        assertEquals("https://glossia.ai", session.server); assertEquals("glossia", session.organization)
        assertNull(session.pendingDestination); assertNull(session.toki.active)
        assertFalse(calls.any { it.optString("operation") in listOf("begin", "conversation") })
        // A core-normalized destination must match a registration without a trailing slash.
        session.navigate(destination(GlossiaScreen.PROFILE, server = "https://GLOSSIA.AI:443"))
        pump { session.tab == "Profile" }
        assertNull(session.navigationNotice)
    }

    @Test fun originCheckFromPreviousSessionCannotAuthorizeNavigationOnAReplacementServer() {
        val started = CountDownLatch(1); val release = CountDownLatch(1).also(releases::add)
        val block = java.util.concurrent.atomic.AtomicBoolean(true)
        val (session, storage) = session { request ->
            when {
                request.optString("operation") == "navigation" && request.optString("action") == "link" &&
                    request.getJSONObject("destination").getString("server") == "https://glossia.ai" && block.getAndSet(false) -> {
                    started.countDown(); release.await(5, TimeUnit.SECONDS); null
                }
                request.optString("operation") == "complete" -> JSONObject("""{"registration":{"server":"https://replacement.example/"},"access_token":"replacement"}""")
                else -> null
            }
        }
        session.receiveLink(fixtureLink(destination(GlossiaScreen.TRANSLATION, id = translationId)))
        pump { started.count == 0L }
        session.signIn("https://replacement.example/"); pump { !session.busy && storage.load("pending") != null }
        session.callback("glossia://oauth/callback?code=fixture&state=fixture")
        pump { session.server == "https://replacement.example/" && session.navigationNotice != null }
        release.countDown(); Thread.sleep(50); shadowOf(Looper.getMainLooper()).idle()
        assertNull(session.translation.id); assertNull(session.pendingDestination)
        assertFalse(calls.any { it.optString("operation") == "translation" })
    }

    @Test fun inaccessibleWorkspaceNeverAcceptsFallbackOrMembershipMissingFromLists() {
        val (session, _) = session { request ->
            if (request.optString("operation") == "workspace" && request.getJSONObject("selection").optionalString("organization") == "missing")
                JSONObject("""{"organizations":[{"handle":"glossia"}],"projects":[{"handle":"website"}],"selection":{"organization":"glossia","project":"website"}}""")
            else null
        }
        for (org in listOf("missing", "not-in-organizations")) {
            session.dismissNavigationNotice()
            session.receiveLink(fixtureLink(destination(GlossiaScreen.TRANSLATION, org = org, id = translationId)))
            pump { session.navigationNotice != null }
            assertTrue(session.navigationNotice!!.contains("not accessible"))
            assertEquals("glossia", session.organization); assertEquals("website", session.project)
            assertNull(session.translation.id); assertNull(session.pendingDestination)
        }
        assertFalse(calls.any { it.optString("operation") == "translation" })
    }

    @Test fun latestIntentWinsAcrossSlowParserWorkspaceAndDirectRecordLookups() {
        val started = CountDownLatch(1); val release = CountDownLatch(1).also(releases::add)
        val old = fixtureLink(destination(GlossiaScreen.TRANSLATION, org = "other", id = translationId))
        val (session, _) = session { request ->
            if (request.optString("action") == "parse" && request.optString("url") == old) {
                started.countDown(); release.await(5, TimeUnit.SECONDS)
            }
            null
        }
        session.receiveLink(old); assertTrue(started.await(2, TimeUnit.SECONDS))
        session.receiveLink(fixtureLink(destination(GlossiaScreen.PROFILE))); pump { session.tab == "Profile" }
        release.countDown(); Thread.sleep(50); shadowOf(Looper.getMainLooper()).idle()
        assertEquals("Profile", session.tab); assertEquals("glossia", session.organization)

        val workspaceStarted = CountDownLatch(1); val workspaceRelease = CountDownLatch(1).also(releases::add)
        val (workspaceSession, _) = session { request ->
            if (request.optString("operation") == "workspace" && request.getJSONObject("selection").optionalString("organization") == "other") {
                workspaceStarted.countDown(); workspaceRelease.await(5, TimeUnit.SECONDS)
            }
            null
        }
        workspaceSession.receiveLink(old); pump { workspaceStarted.count == 0L }
        workspaceSession.selectTab("Analytics"); pump { workspaceSession.analytics.loaded }
        workspaceRelease.countDown(); Thread.sleep(50); shadowOf(Looper.getMainLooper()).idle()
        assertEquals("Analytics", workspaceSession.tab); assertEquals("glossia", workspaceSession.organization)

        val recordStarted = CountDownLatch(1); val recordRelease = CountDownLatch(1).also(releases::add)
        val (recordSession, _) = session { request ->
            if (request.optString("operation") == "translation" && request.optString("id") == translationId) {
                recordStarted.countDown(); recordRelease.await(5, TimeUnit.SECONDS)
            }
            null
        }
        recordSession.showTranslation(translationId); pump { recordStarted.count == 0L }
        recordSession.showTranslation(conversationId); pump { recordSession.translation.loaded }
        recordRelease.countDown(); Thread.sleep(50); shadowOf(Looper.getMainLooper()).idle()
        assertEquals(conversationId, recordSession.translation.id)
        assertEquals(conversationId, recordSession.translation.data!!.getString("id"))
    }

    @Test fun hiddenDraftsAndPendingSendsBlockNavigationWithoutDroppingWork() {
        val (session, _) = session { request ->
            if (request.optString("action") == "create") failure("network", "Offline") else null
        }
        session.newConversation(); session.draft("Private unsent draft")
        val thread = session.toki.active!!
        session.selectTab("Analytics")
        session.receiveLink(fixtureLink(destination(GlossiaScreen.TRANSLATION, org = "other", project = "docs", id = translationId)))
        pump { session.navigationNotice != null }
        assertEquals("Analytics", session.tab); assertEquals("glossia", session.organization)
        assertEquals("Private unsent draft", thread.draft); assertNull(session.translation.id)
        session.dismissNavigationNotice(); session.selectTab("Toki"); session.showConversation(thread.id); session.sendMessage()
        pump { thread.error != null }
        val pending = thread.pending
        session.selectTab("Profile"); session.newConversation()
        assertNotSame(thread, session.toki.active); assertSame(thread, session.toki.threads[thread.id]); assertSame(pending, thread.pending)
        assertTrue(session.back())
        assertNull(session.toki.active)
        session.showConversation(thread.id) // Local list navigation preserves the original retry.
        assertSame(thread, session.toki.active); assertSame(pending, thread.pending)
        session.receiveLink(fixtureLink(destination(GlossiaScreen.PROFILE))); pump { session.navigationNotice != null }
        assertSame(thread, session.toki.active); assertSame(pending, thread.pending)
    }

    @Test fun signOutClearsPendingLinkAndFencesAParserStillInFlight() {
        val (signedOut, _) = session(signedIn = false)
        signedOut.receiveLink(fixtureLink(destination(GlossiaScreen.PROFILE)))
        pump { signedOut.pendingDestination != null }
        signedOut.signOut(); pump { !signedOut.busy }
        assertNull(signedOut.pendingDestination)
        signedOut.signIn("https://glossia.ai"); pump { !signedOut.busy }
        signedOut.callback("glossia://oauth/callback?code=fixture&state=fixture")
        pump { signedOut.server != null && !signedOut.busy }
        assertEquals("Toki", signedOut.tab)
        val started = CountDownLatch(1); val release = CountDownLatch(1).also(releases::add)
        val (session, _) = session { request ->
            if (request.optString("action") == "parse") { started.countDown(); release.await(5, TimeUnit.SECONDS) }
            null
        }
        session.receiveLink(fixtureLink(destination(GlossiaScreen.TRANSLATION, id = translationId)))
        assertTrue(started.await(2, TimeUnit.SECONDS)); session.signOut(); pump { !session.busy }
        release.countDown(); Thread.sleep(50); shadowOf(Looper.getMainLooper()).idle()
        assertNull(session.pendingDestination); assertNull(session.navigationNotice); assertNull(session.translation.id)
    }

    @Test fun protectedWorkCanBeResumedOrExplicitlyDiscardedWithoutLateCreateSending() {
        val createStarted = CountDownLatch(1); val createRelease = CountDownLatch(1).also(releases::add)
        val (session, _) = session { request ->
            if (request.optString("action") == "create") { createStarted.countDown(); createRelease.await(5, TimeUnit.SECONDS) }
            null
        }
        session.newConversation(); session.draft("Ambiguous create, do not send after discard")
        val thread = session.toki.active!!
        session.sendMessage(); assertTrue(createStarted.await(2, TimeUnit.SECONDS))
        session.selectTab("Analytics")
        val target = fixtureLink(destination(GlossiaScreen.TRANSLATION, id = translationId))
        session.receiveLink(target); pump { session.navigationNotice != null }
        assertTrue(session.hasProtectedWork)
        session.resumeUnsentWork()
        assertEquals("Toki", session.tab); assertSame(thread, session.toki.active)
        assertNotNull(thread.pending); assertNull(session.navigationNotice)
        session.selectTab("Analytics")
        session.discardUnsentWork()
        assertFalse(session.hasProtectedWork); assertNull(session.toki.active); assertNull(thread.pending)
        assertTrue(session.navigationNotice!!.contains("may still complete"))
        session.receiveLink(target); pump { session.translation.loaded }
        createRelease.countDown(); Thread.sleep(50); shadowOf(Looper.getMainLooper()).idle()
        assertFalse(calls.any { it.optString("action") == "send" })
        assertEquals("Translations", session.tab); assertFalse(session.hasProtectedWork)
    }

    @Test fun explicitDiscardFencesAmbiguousSendWithoutDeletingServerConversation() {
        val sendStarted = CountDownLatch(1); val sendRelease = CountDownLatch(1).also(releases::add)
        val (session, _) = session { request ->
            if (request.optString("action") == "send") {
                sendStarted.countDown(); sendRelease.await(5, TimeUnit.SECONDS)
                conversation(request.getString("id"), "running")
            } else null
        }
        session.showConversation(conversationId); pump { session.toki.active?.loaded == true }
        val thread = session.toki.active!!
        session.draft("The server may have received this"); session.sendMessage()
        assertTrue(sendStarted.await(2, TimeUnit.SECONDS))
        session.selectTab("Profile"); session.discardUnsentWork()
        assertFalse(session.hasProtectedWork); assertNull(thread.pending); assertEquals("", thread.draft)
        assertSame(thread, session.toki.threads[conversationId]); assertTrue(thread.created)
        session.receiveLink(fixtureLink(destination(GlossiaScreen.TRANSLATION, org = "other", id = translationId)))
        pump { session.translation.loaded }
        sendRelease.countDown(); Thread.sleep(50); shadowOf(Looper.getMainLooper()).idle()
        assertEquals("other", session.organization); assertNull(session.toki.active)
        assertEquals(1, calls.count { it.optString("action") == "send" })
        assertFalse(calls.any { it.optString("action") in listOf("delete", "cancel") })
    }

    @Test fun directTranslationAndConversationHaveRetryDenialAndNativeBackWithoutListPages() {
        var denied: String? = "network"
        val (session, _) = session { request ->
            if (request.optString("operation") == "translation" || request.optString("action") == "show") denied?.let { failure(it) } else null
        }
        session.showTranslation(translationId); pump { session.translation.error != null }
        assertEquals(translationId, session.translation.id); assertNull(session.translation.data)
        denied = null; session.loadTranslation(); pump { session.translation.loaded }
        assertTrue(session.translations.items.isEmpty())
        denied = "forbidden"; session.loadTranslation(); pump { session.translation.error != null }
        assertNull(session.translation.data); assertFalse(session.translation.loaded)
        denied = "not_found"; session.loadTranslation(); pump { !session.translation.busy }
        assertNull(session.translation.data)
        denied = null; session.loadTranslation(); pump { session.translation.loaded }
        assertTrue(session.back()); assertNull(session.translation.id); assertEquals("Translations", session.tab)
        denied = "network"
        session.receiveLink(fixtureLink(destination(GlossiaScreen.CONVERSATION, id = conversationId)))
        pump { session.toki.active?.error != null }
        assertTrue(session.toki.history.items.isEmpty()); assertEquals(conversationId, session.toki.activeId)
        denied = "not_found"; session.showConversation(conversationId); pump { session.toki.active?.unavailable == true }
        denied = null; session.showConversation(conversationId); pump { session.toki.active?.loaded == true }
        assertTrue(session.back()); assertEquals("Toki", session.tab); assertNull(session.toki.activeId)
    }

    @Test fun translationDenialClearsSourceSummaryAndFencesLateListAndSourceResponses() {
        val listStarted = CountDownLatch(1); val listRelease = CountDownLatch(1).also(releases::add)
        val sourceStarted = CountDownLatch(1); val sourceRelease = CountDownLatch(1).also(releases::add)
        val translationRequests = AtomicInteger()
        val (session, _) = session { request ->
            when {
                request.optString("resource") == "translations" -> {
                    listStarted.countDown(); listRelease.await(5, TimeUnit.SECONDS)
                    JSONObject().put("sessions", JSONArray().put(translationRecord())).put("meta", JSONObject())
                }
                request.optString("operation") == "translation" -> when (translationRequests.incrementAndGet()) {
                    2 -> {
                        sourceStarted.countDown(); sourceRelease.await(5, TimeUnit.SECONDS)
                        JSONObject().put("session", translationRecord().put("summary", "Stale private summary"))
                    }
                    3 -> failure("forbidden")
                    else -> null
                }
                else -> null
            }
        }
        session.navigate(destination(GlossiaScreen.NEW_CONVERSATION, source = translationId))
        pump { session.toki.active?.source?.loaded == true }
        val thread = session.toki.active!!
        session.loadPage(session.translations); assertTrue(listStarted.await(2, TimeUnit.SECONDS))
        session.retrySource(); assertTrue(sourceStarted.await(2, TimeUnit.SECONDS))
        session.showTranslation(translationId); pump { session.translation.error != null }
        assertNull(thread.source.data); assertNotNull(thread.source.error)
        listRelease.countDown()
        pump { !session.translations.busy }
        assertTrue(session.translations.items.isEmpty()); assertNull(thread.source.data)
        assertEquals(translationId, thread.translationSessionId) // Read denial must not rebind the origin.
        session.selectTab("Toki"); session.showConversation(thread.id); session.retrySource(); pump { thread.source.loaded }
        assertEquals(translationId, thread.source.data!!.getString("id"))
        sourceRelease.countDown(); Thread.sleep(50); shadowOf(Looper.getMainLooper()).idle()
        assertEquals("Updated homepage and onboarding translations.", thread.source.data!!.getString("summary"))
    }

    @Test fun workspaceLookupCanRetryAndCannotDiscardADraftStartedWhileResolving() {
        val failed = java.util.concurrent.atomic.AtomicBoolean(true)
        val started = CountDownLatch(1); val release = CountDownLatch(1).also(releases::add)
        val (session, _) = session { request ->
            if (request.optString("operation") == "workspace" && request.getJSONObject("selection").optionalString("organization") == "other") {
                if (failed.getAndSet(false)) failure("network", "Offline")
                else { started.countDown(); release.await(5, TimeUnit.SECONDS); null }
            } else null
        }
        session.newConversation()
        session.receiveLink(fixtureLink(destination(GlossiaScreen.TRANSLATION, org = "other", id = translationId)))
        pump { session.navigationNotice != null }
        assertNotNull(session.pendingDestination)
        session.retryNavigation(); pump { started.count == 0L }
        session.draft("Typed during lookup")
        release.countDown(); pump { session.pendingDestination == null }
        assertEquals("glossia", session.organization); assertEquals("Typed during lookup", session.toki.active!!.draft)
        assertNull(session.translation.id)
    }

    @Test fun translationDiscussionKeepsImmutableOriginAcrossCreateRetriesAndReturnsToSource() {
        var createFails = true
        val (session, _) = session { request ->
            if (request.optString("operation") == "conversation") {
                if (request.optString("action") == "create" && createFails) { createFails = false; failure("network", "Create unconfirmed") }
                else conversation(request.getString("id"), "completed").apply { getJSONObject("conversation").put("translation_session_id", translationId) }
            } else null
        }
        session.showTranslation(translationId); pump { session.translation.loaded }
        val controller = Robolectric.buildActivity(RenderActivity::class.java).setup()
        val activity = controller.get()
        var sharedURL: String? = null
        val detail = FeatureViews(activity).translation(session.translation, session::loadTranslation, { session.back() }, session::discussTranslation, share = {
            session.shareTranslation { url ->
                sharedURL = url
                activity.startActivity(GlossiaIntents.shareTranslation(url))
            }
        })
        activity.setContentView(detail)
        val buildsBeforeShare = calls.count { it.optString("operation") == "navigation" && it.optString("action") == "link" }
        descendants(detail).filterIsInstance<MaterialButton>().single { it.text == "Share translation link" }.performClick()
        pump { sharedURL != null }
        val chooser = shadowOf(activity).nextStartedActivity
        assertEquals(Intent.ACTION_CHOOSER, chooser.action)
        val sendIntent = chooser.getParcelableExtra(Intent.EXTRA_INTENT, Intent::class.java)!!
        assertEquals(Intent.ACTION_SEND, sendIntent.action); assertEquals("text/plain", sendIntent.type)
        assertEquals(link(destination(GlossiaScreen.TRANSLATION, id = translationId)), sendIntent.getStringExtra(Intent.EXTRA_TEXT))
        assertEquals(setOf(Intent.EXTRA_TEXT), sendIntent.extras!!.keySet())
        assertEquals(buildsBeforeShare + 1, calls.count { it.optString("operation") == "navigation" && it.optString("action") == "link" })
        val shareRequest = calls.last { it.optString("operation") == "navigation" }
        assertEquals(setOf("operation", "action", "destination"), shareRequest.keys().asSequence().toSet())
        assertEquals("translation", shareRequest.getJSONObject("destination").getString("screen"))
        assertEquals(translationId, shareRequest.getJSONObject("destination").getString("id"))
        assertFalse(sharedURL!!.contains("private")); assertFalse(sharedURL!!.contains("access_token"))
        assertEquals("Translations", session.tab); assertNull(session.toki.active)
        controller.pause().stop().destroy()
        session.discussTranslation(); pump { session.toki.active?.source?.loaded == true }
        val thread = session.toki.active!!
        assertEquals(translationId, thread.translationSessionId); assertFalse(thread.created)
        assertFalse(calls.any { it.optString("action") in listOf("create", "send") })
        session.draft("Explain the Spanish wording"); session.sendMessage(); pump { thread.error != null }
        val pending = thread.pending!!
        session.selectTab("Translations"); session.discussTranslation(); pump { session.navigationNotice != null }
        assertSame(thread, session.toki.active)
        session.selectTab("Toki"); session.showConversation(thread.id); session.sendMessage(); pump { thread.pending == null }
        val creates = calls.filter { it.optString("action") == "create" }
        assertEquals(2, creates.size)
        assertTrue(creates.all { it.getString("id") == thread.id && it.getString("translation_session_id") == translationId })
        val send = calls.single { it.optString("action") == "send" }
        assertEquals(pending.id, send.getString("message_id")); assertEquals(pending.content, send.getString("content"))
        session.showTranslation(thread.translationSessionId!!); pump { session.tab == "Translations" && session.translation.loaded }
        assertEquals(translationId, session.translation.id)
        assertTrue(session.back()); assertEquals("Translations", session.tab)
        session.receiveLink(fixtureLink(destination(GlossiaScreen.CONVERSATION, id = thread.id)))
        pump { session.tab == "Toki" && session.toki.active?.loaded == true }
        assertSame(thread, session.toki.active); assertEquals(translationId, session.toki.active!!.translationSessionId)
        assertTrue(session.back()); assertNull(session.toki.activeId)
    }

    private fun progressSnapshot(status: String = "running", assessed: Boolean = true, done: Int = 1) = JSONObject()
        .put("session", translationRecord().put("status", status))
        .put("progress", JSONObject().put("seq", 17)
            .put("summary", JSONObject().put("total", 5).put("checked", if (assessed) 5 else 2)
                .put("needs_translation", 3).put("assessed?", assessed).put("skipped", 2).put("done", if (assessed) done else 0)
                .put("failed", if (status == "failed") 1 else 0).put("cancelled", when (status) { "cancelled" -> 2; "failed" -> 1; else -> 0 })
                .put("running", if (status == "running" && assessed) 1 else 0).put("queued", if (status == "running" && assessed) 1 else 0))
            .put("items", if (!assessed) JSONArray() else JSONArray("""[
                {"index":0,"status":"done","output_path":"locales/es/home.json","locale":"es"},
                {"index":1,"status":"running","output_path":"locales/fr/home.json","locale":"fr"},
                {"index":2,"status":"queued","output_path":"locales/de/home.json","locale":"de"}]
            """).apply {
                if (status == "completed") for (index in 0 until length()) getJSONObject(index).put("status", "done")
                if (status in listOf("failed", "cancelled")) {
                    getJSONObject(1).put("status", if (status == "failed") "failed" else "cancelled")
                    getJSONObject(2).put("status", "cancelled")
                }
            }))

    // Transport is injected at the public session boundary. No timers simulate
    // remote progress: each next blocks until an unsolicited delivery or close.
    private class LiveFixture {
        val opens = CopyOnWriteArrayList<JSONObject>()
        val nexts = CopyOnWriteArrayList<JSONObject>()
        val closes = CopyOnWriteArrayList<String>()
        private val queues = java.util.concurrent.ConcurrentHashMap<String, java.util.concurrent.LinkedBlockingQueue<JSONObject>>()
        fun push(handle: String, value: JSONObject) { queues.getValue(handle).put(value) }
        fun command(request: JSONObject): JSONObject? {
            if (request.optString("operation") != "translation_live") return null
            return when (request.getString("action")) {
                "open" -> {
                    val handle = "connection-${opens.size + 1}"
                    queues[handle] = java.util.concurrent.LinkedBlockingQueue()
                    opens.add(JSONObject(request.toString()))
                    JSONObject().put("connection", handle)
                }
                "next" -> { nexts.add(request); queues.getValue(request.getString("connection")).take() }
                "close" -> {
                    val handle = request.getString("connection"); closes.add(handle)
                    push(handle, JSONObject().put("sequence", 999).put("state", "closed").put("snapshot", JSONObject.NULL))
                    JSONObject().put("closed", true)
                }
                else -> error("Unexpected live command")
            }
        }
    }

    private fun delivery(sequence: Long, snapshot: JSONObject? = null, state: String = "live", error: String? = null) = JSONObject()
        .put("sequence", sequence).put("state", state).put("snapshot", snapshot ?: JSONObject.NULL)
        .apply { error?.let { put("error", it) } }

    @Test fun liveTranslationAcceptsUnsolicitedAndStatusOnlyUpdatesWithoutHttpPolling() {
        val live = LiveFixture()
        val (session, _) = session { live.command(it) }
        session.setForeground(true); session.showTranslation(translationId)
        pump { session.translation.loaded && live.nexts.size == 1 }
        assertEquals("private", live.opens.single().getJSONObject("session").getString("access_token"))
        assertEquals("website", live.opens.single().getJSONObject("selection").getString("project"))
        assertEquals(translationId, live.opens.single().getString("id"))
        live.push("connection-1", delivery(1, progressSnapshot()))
        pump { session.translation.progress != null && live.nexts.size == 2 }
        assertEquals(1, session.translation.progress!!.getJSONObject("summary").getInt("done"))
        assertEquals(1L, live.nexts.last().getLong("after"))
        val statusOnly = progressSnapshot().apply { getJSONObject("session").put("status", "failed") }
        live.push("connection-1", delivery(2, statusOnly))
        pump { session.translation.data?.optString("status") == "failed" && live.nexts.size == 3 }
        assertEquals(17, session.translation.progress!!.getInt("seq"))
        assertEquals(1, session.translation.progress!!.getJSONObject("summary").getInt("done"))
        live.push("connection-1", delivery(3, state = "reconnecting"))
        pump { session.translation.liveState == "reconnecting" }
        assertEquals("failed", session.translation.data!!.getString("status"))
        assertEquals(1, calls.count { it.optString("operation") == "translation" })
        assertTrue(live.nexts.all { !it.has("session") && !it.has("selection") })
    }

    @Test fun liveCursorPreservesUnsigned64BitDeliverySequence() {
        val live = LiveFixture()
        val (session, _) = session { live.command(it) }
        session.setForeground(true); session.showTranslation(translationId); pump { live.nexts.size == 1 }
        val cursor = "18446744073709551614"
        live.push("connection-1", delivery(1, progressSnapshot()).put("sequence", cursor.toBigInteger()))
        pump { session.translation.progress != null && live.nexts.size == 2 }
        val request = rawCalls.last { it.contains("\"action\":\"next\"") }
        assertTrue("The u64 cursor must remain an exact JSON number, not a string or rounded double", request.contains("\"after\":$cursor"))
    }

    @Test fun translationHttpBootstrapAcceptsSiblingProgressWithoutStartingBackgroundLiveWork() {
        val (session, _) = session { request ->
            if (request.optString("operation") == "translation") progressSnapshot() else null
        }
        session.showTranslation(translationId); pump { session.translation.loaded }
        assertEquals(1, session.translation.progress!!.getJSONObject("summary").getInt("done"))
        assertFalse(calls.any { it.optString("operation") == "translation_live" })
    }

    @Test fun liveWaitAndCloseBypassSaturatedFeaturePoolAndCredentialQueue() {
        val live = LiveFixture()
        val credentialStarted = CountDownLatch(1)
        val credentialRelease = CountDownLatch(1).also(releases::add)
        val featureStarted = CountDownLatch(4)
        val featureRelease = CountDownLatch(1).also(releases::add)
        val (session, storage) = session { live.command(it) }
        session.setForeground(true); session.showTranslation(translationId)
        pump { live.nexts.size == 1 }
        fun executor(name: String) = (GlossiaSession::class.java.getDeclaredField(name).apply { isAccessible = true }
            .get(session) as java.util.concurrent.ExecutorService)
        executor("credentials").execute { credentialStarted.countDown(); credentialRelease.await(8, TimeUnit.SECONDS) }
        repeat(4) { executor("requests").execute { featureStarted.countDown(); featureRelease.await(8, TimeUnit.SECONDS) } }
        assertTrue(credentialStarted.await(2, TimeUnit.SECONDS)); assertTrue(featureStarted.await(2, TimeUnit.SECONDS))
        live.push("connection-1", delivery(1, progressSnapshot()))
        pump { session.translation.liveState == "live" && live.nexts.size == 2 }
        session.setForeground(false)
        pump { live.closes.contains("connection-1") }
        assertEquals("closed", session.translation.liveState)
        credentialRelease.countDown(); featureRelease.countDown()
        session.signOut(); pump { !session.busy && storage.load("session") == null }
        assertNull(session.translation.data)
    }

    @Test fun liveWaitDoesNotBlockOtherFeaturesAndSignOutAndLateDeliveriesStayFenced() {
        val nextStarted = CountDownLatch(1)
        val nextRelease = CountDownLatch(1).also(releases::add)
        val closed = CountDownLatch(1)
        val (session, storage) = session { request ->
            if (request.optString("operation") != "translation_live") null else when (request.getString("action")) {
                "open" -> JSONObject().put("connection", "held")
                "next" -> { nextStarted.countDown(); nextRelease.await(8, TimeUnit.SECONDS); delivery(1, progressSnapshot()) }
                "close" -> { closed.countDown(); JSONObject().put("closed", true) }
                else -> null
            }
        }
        session.setForeground(true); session.showTranslation(translationId)
        pump { nextStarted.count == 0L }
        session.selectTab("Analytics"); pump { session.analytics.loaded && closed.count == 0L }
        session.signOut(); pump { !session.busy && storage.load("session") == null }
        nextRelease.countDown(); Thread.sleep(50); shadowOf(Looper.getMainLooper()).idle()
        assertNull(session.translation.progress); assertNull(session.translation.data); assertNull(session.server)
    }

    @Test fun lateLiveOpenIsClosedAfterBackgroundBackProjectChangeAndSignOut() {
        for (leave in listOf("background", "back", "project", "signout")) {
            val started = CountDownLatch(1)
            val release = CountDownLatch(1).also(releases::add)
            val credentialsStarted = CountDownLatch(1)
            val credentialsRelease = CountDownLatch(1).also(releases::add)
            val closed = CountDownLatch(1)
            val next = AtomicInteger()
            val (session, _) = session { request ->
                if (request.optString("operation") != "translation_live") null else when (request.getString("action")) {
                    "open" -> { started.countDown(); release.await(8, TimeUnit.SECONDS); JSONObject().put("connection", "late-$leave") }
                    "close" -> { assertEquals("late-$leave", request.getString("connection")); closed.countDown(); JSONObject().put("closed", true) }
                    "next" -> { next.incrementAndGet(); delivery(1, progressSnapshot()) }
                    else -> null
                }
            }
            session.setForeground(true); session.showTranslation(translationId); pump { started.count == 0L }
            val credentials = GlossiaSession::class.java.getDeclaredField("credentials").apply { isAccessible = true }
                .get(session) as java.util.concurrent.ExecutorService
            credentials.execute { credentialsStarted.countDown(); credentialsRelease.await(8, TimeUnit.SECONDS) }
            assertTrue(credentialsStarted.await(2, TimeUnit.SECONDS))
            when (leave) {
                "background" -> session.setForeground(false)
                "back" -> session.back()
                "project" -> { session.openWorkspacePicker(); session.selectWorkspaceProject("docs") }
                else -> session.signOut()
            }
            release.countDown(); pump { closed.count == 0L }
            assertEquals(0, next.get()); assertNull(session.translation.progress)
            credentialsRelease.countDown()
            session.setForeground(false)
        }
    }

    @Test fun liveNeedsSessionReopensOnceWithRefreshedPersistedCredentialsThenClearsProtectedData() {
        val live = LiveFixture()
        val refreshes = AtomicInteger()
        val (session, storage) = session { request ->
            live.command(request) ?: if (request.optString("operation") == "restore")
                JSONObject(request.getJSONObject("session").toString()).put("access_token", "rotated-${refreshes.incrementAndGet()}") else null
        }
        session.setForeground(true); session.showTranslation(translationId); pump { live.nexts.size == 1 }
        live.push("connection-1", delivery(1, progressSnapshot()))
        pump { session.translation.progress != null && live.nexts.size == 2 }
        live.push("connection-1", delivery(2, state = "needs_session", error = "sign_in_required"))
        pump { live.opens.size == 2 && live.nexts.size == 3 }
        assertTrue(live.closes.contains("connection-1"))
        val first = live.opens.first().getJSONObject("session").getString("access_token")
        val second = live.opens.last().getJSONObject("session").getString("access_token")
        assertNotEquals(first, second); assertEquals(second, storage.load("session")!!.getString("access_token"))
        assertNotNull(session.translation.data) // Preserve the last snapshot during credential recovery.
        live.push("connection-2", delivery(1, state = "needs_session", error = "sign_in_required"))
        pump { session.translation.error?.contains("Sign in") == true && live.closes.contains("connection-2") }
        assertEquals(2, live.opens.size); assertNull(session.translation.data); assertNull(session.translation.progress)
        assertEquals("unavailable", session.translation.liveState)
    }

    @Test fun liveAccessDenialClearsProtectedDetailAndFencesLateHttpBootstrap() {
        for (denied in listOf("forbidden", "not_found")) {
            val live = LiveFixture()
            val started = CountDownLatch(1)
            val release = CountDownLatch(1).also(releases::add)
            val finished = CountDownLatch(1)
            val (session, _) = session { request ->
                live.command(request) ?: if (request.optString("operation") == "translation") {
                    started.countDown(); release.await(8, TimeUnit.SECONDS); finished.countDown()
                    JSONObject().put("session", translationRecord().put("summary", "Private late HTTP response"))
                } else null
            }
            session.setForeground(true); session.showTranslation(translationId)
            pump { live.nexts.size == 1 && started.count == 0L }
            live.push("connection-1", delivery(1, progressSnapshot()))
            pump { session.translation.progress != null && live.nexts.size == 2 }
            live.push("connection-1", delivery(2, state = "unavailable", error = denied))
            pump { session.translation.liveState == "unavailable" && live.closes.contains("connection-1") }
            assertNull(session.translation.data); assertNull(session.translation.progress)
            release.countDown(); pump { finished.count == 0L }
            Thread.sleep(50); shadowOf(Looper.getMainLooper()).idle()
            assertNull(session.translation.data); assertFalse(session.translation.loaded)
            session.setForeground(false)
        }
    }

    @Test fun liveProjectionWinsLateHttpAndTransientBridgeErrorsKeepItVisible() {
        val live = LiveFixture()
        val release = CountDownLatch(1).also(releases::add)
        val finished = CountDownLatch(1)
        val httpRequests = AtomicInteger()
        val (session, _) = session { request ->
            live.command(request) ?: if (request.optString("operation") == "translation") {
                release.await(8, TimeUnit.SECONDS); finished.countDown()
                if (httpRequests.incrementAndGet() == 1) JSONObject().put("session", translationRecord().put("status", "queued"))
                else progressSnapshot(status = "completed", done = 3)
            } else null
        }
        session.setForeground(true); session.showTranslation(translationId); pump { live.nexts.size == 1 }
        live.push("connection-1", delivery(1, progressSnapshot()))
        pump { session.translation.progress != null && live.nexts.size == 2 }
        release.countDown(); pump { finished.count == 0L && !session.translation.busy }
        assertEquals("running", session.translation.data!!.getString("status"))
        live.push("connection-1", failure("network", "Disconnected"))
        pump { session.translation.liveState == "reconnecting" && live.closes.contains("connection-1") }
        assertNotNull(session.translation.progress); assertNull(session.translation.error)
        session.loadTranslation(); pump { httpRequests.get() == 2 && !session.translation.busy }
        assertEquals("completed", session.translation.data!!.getString("status"))
        assertEquals(3, session.translation.progress!!.getJSONObject("summary").getInt("done"))
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofSeconds(2))
        pump { live.opens.size == 2 && live.nexts.size == 3 }
        assertEquals(2, calls.count { it.optString("operation") == "translation" })
    }

    private val notificationManager get() = context.getSystemService(NotificationManager::class.java)
    private fun tokiNotification() = notificationManager.activeNotifications.single().notification

    private fun renderNotification(name: String, notification: Notification, expanded: Boolean = false) {
        android.os.SystemClock.setCurrentTimeMillis(System.currentTimeMillis())
        val controller = Robolectric.buildActivity(RenderActivity::class.java).setup()
        val activity = controller.get()
        // This is Android's actual RemoteViews template recovered from the
        // production notification, not an app imitation of the system shade.
        val builder = Notification.Builder.recoverBuilder(activity, notification)
        val view = (if (expanded) builder.createBigContentView() else builder.createContentView())
            .apply(activity, FrameLayout(activity))
        activity.setContentView(view)
        // SystemUI constrains these weighted native templates; UNSPECIFIED
        // height collapses their content to only the notification header.
        view.measure(View.MeasureSpec.makeMeasureSpec(1080, View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(activity.dp(if (expanded) 192 else 88), View.MeasureSpec.EXACTLY))
        view.layout(0, 0, 1080, view.measuredHeight)
        val bitmap = Bitmap.createBitmap(1080, view.measuredHeight, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.drawColor(activity.token(R.color.glossia_surface)); view.draw(canvas)
        File(artifacts, "android-toki-notification-$name.png").outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
        bitmap.recycle(); controller.pause().stop().destroy()
    }

    @Test fun tokiNotificationsFollowRealStatusesWithPrivateContentAndCanonicalImmutableIntent() {
        // Align Android's virtual wall/elapsed clocks with the app's JVM wall
        // clock before building the native chronometer template.
        android.os.SystemClock.setCurrentTimeMillis(System.currentTimeMillis())
        shadowOf(context).grantPermissions(Manifest.permission.POST_NOTIFICATIONS)
        val state = java.util.concurrent.atomic.AtomicReference("queued")
        val turn = java.util.concurrent.atomic.AtomicReference(translationId)
        val (session, _) = session { request ->
            if (request.optString("action") == "show") tokiWork(request.getString("id"), state.get(), turn.get()).apply {
                getJSONObject("conversation").put("title", "Sensitive customer launch")
                getJSONArray("messages").getJSONObject(0).put("content", "Private prompt and model output")
            } else null
        }
        session.setForeground(true); session.showConversation(conversationId)
        pump { notificationManager.activeNotifications.size == 1 }
        val queued = tokiNotification()
        assertEquals("Toki · Queued", queued.extras.getString(Notification.EXTRA_TITLE))
        assertTrue(queued.flags and Notification.FLAG_ONGOING_EVENT != 0)
        assertTrue(queued.extras.getBoolean(Notification.EXTRA_SHOW_CHRONOMETER))
        val observedAt = queued.`when`
        renderNotification("queued", queued)
        val intent = shadowOf(queued.contentIntent).savedIntent
        assertEquals(MainActivity::class.java.name, intent.component!!.className)
        assertEquals(Intent.ACTION_VIEW, intent.action)
        assertNull(intent.extras)
        assertEquals(link(destination(GlossiaScreen.CONVERSATION, id = conversationId)), intent.dataString)
        assertTrue(shadowOf(queued.contentIntent).flags and PendingIntent.FLAG_IMMUTABLE != 0)
        val linkRequest = calls.last { it.optString("operation") == "navigation" }
        assertEquals("conversation", linkRequest.getJSONObject("destination").getString("screen"))
        assertFalse(linkRequest.has("session"))
        for (status in listOf("running", "completed", "running", "failed")) {
            if (state.get() == "completed" && status == "running") turn.set(conversationId)
            state.set(status); session.showConversation(conversationId)
            val title = "Toki · ${when (status) { "running" -> "Working"; "completed" -> "Completed"; else -> "Failed" }}"
            pump { tokiNotification().extras.getString(Notification.EXTRA_TITLE) == title }
            val notification = tokiNotification()
            assertEquals(status == "running", notification.flags and Notification.FLAG_ONGOING_EVENT != 0)
            assertEquals(status == "running", notification.extras.getBoolean(Notification.EXTRA_SHOW_CHRONOMETER))
            assertEquals(Notification.VISIBILITY_PRIVATE, notification.visibility)
            assertEquals(Notification.VISIBILITY_PUBLIC, notification.publicVersion.visibility)
            assertFalse(notification.extras.toString().contains("Sensitive customer"))
            assertFalse(notification.publicVersion.extras.toString().contains("Private prompt"))
            assertFalse(notification.extras.getBoolean(Notification.EXTRA_PROGRESS_INDETERMINATE))
            assertTrue(notification.actions.isNullOrEmpty()) // No unsupported stop/pause/retry controls.
            if (status != "running") assertTrue(notification.timeoutAfter > 0)
            if (status == "completed") assertEquals(observedAt, notification.`when`)
            renderNotification(status, notification)
        }
        renderNotification("lockscreen", tokiNotification().publicVersion)
        // A notification tap follows the same verified navigation/access path.
        GlossiaIntents.consume(intent, session::receiveLink, session::callback)
        pump { session.toki.activeId == conversationId && session.pendingDestination == null }
        session.signOut(); pump { !session.busy && notificationManager.activeNotifications.isEmpty() }
    }

    @Test fun tokiBackgroundAndInactiveTabNotificationsAreExplicitlyLastKnownAndDoNotPoll() {
        android.os.SystemClock.setCurrentTimeMillis(System.currentTimeMillis())
        shadowOf(context).grantPermissions(Manifest.permission.POST_NOTIFICATIONS)
        val (session, _) = session { request ->
            if (request.optString("action") == "show") tokiWork(request.getString("id"), "running") else null
        }
        session.setForeground(true); session.showConversation(conversationId)
        pump { notificationManager.activeNotifications.size == 1 }
        session.setForeground(false)
        assertFalse(tokiNotification().extras.getBoolean(Notification.EXTRA_SHOW_CHRONOMETER))
        assertTrue(tokiNotification().extras.getString(Notification.EXTRA_TEXT)!!.contains("Last known"))
        renderNotification("background", tokiNotification())
        renderNotification("background-expanded", tokiNotification(), expanded = true)
        val shows = calls.count { it.optString("action") == "show" }
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofSeconds(10))
        assertEquals(shows, calls.count { it.optString("action") == "show" })
        session.setForeground(true)
        pump { calls.count { it.optString("action") == "show" } > shows && session.toki.active!!.workObservationCurrent }
        assertTrue(tokiNotification().extras.getBoolean(Notification.EXTRA_SHOW_CHRONOMETER))
        session.selectTab("Analytics"); session.setForeground(true); pump { session.analytics.loaded }
        assertFalse(tokiNotification().extras.getBoolean(Notification.EXTRA_SHOW_CHRONOMETER))
        session.openWorkspacePicker(); session.selectWorkspaceProject("docs")
        assertTrue(notificationManager.activeNotifications.isEmpty())
    }

    @Test fun tokiNotificationPermissionDenialNeverBlocksConversationAndDoesNotNag() {
        shadowOf(context).denyPermissions(Manifest.permission.POST_NOTIFICATIONS)
        val (session, _) = session { request ->
            if (request.optString("action") == "show") tokiWork(request.getString("id"), "running") else null
        }
        session.setForeground(true)
        assertFalse(session.takeNotificationPermissionRequest())
        session.showConversation(conversationId); pump { session.toki.active?.status == "running" }
        assertTrue(session.takeNotificationPermissionRequest())
        assertFalse(session.takeNotificationPermissionRequest())
        session.refreshNotifications(); assertTrue(notificationManager.activeNotifications.isEmpty())
        assertEquals("running", session.toki.active!!.status); assertNull(session.error)
        session.selectTab("Analytics"); pump { session.analytics.loaded }
        shadowOf(context).grantPermissions(Manifest.permission.POST_NOTIFICATIONS)
        session.refreshNotifications(); pump { notificationManager.activeNotifications.size == 1 }
    }

    @Test fun tokiNotificationsIgnoreIdleCompletionAndBindFollowUpToExactSentMessageUuid() {
        shadowOf(context).grantPermissions(Manifest.permission.POST_NOTIFICATIONS)
        val response = java.util.concurrent.atomic.AtomicReference(tokiWork(conversationId, "completed"))
        val sent = CopyOnWriteArrayList<String>()
        val (session, _) = session { request ->
            when (request.optString("action")) {
                "show" -> response.get()
                "send" -> {
                    val turnId = request.getString("message_id"); sent.add(turnId)
                    tokiWork(conversationId, "queued", turnId).also(response::set)
                }
                else -> null
            }
        }
        session.setForeground(true); session.showConversation(conversationId)
        pump { session.toki.active?.loaded == true }
        assertTrue(notificationManager.activeNotifications.isEmpty()) // Historical or idle 'completed' is not a run.
        session.draft("First explicit task"); session.sendMessage()
        pump { sent.size == 1 && session.toki.active?.pending == null && notificationManager.activeNotifications.size == 1 }
        val first = sent.single()
        assertEquals(first, session.toki.active!!.workTurnId)
        response.set(tokiWork(conversationId, "completed", first)); session.showConversation(conversationId)
        pump { tokiNotification().extras.getString(Notification.EXTRA_TITLE) == "Toki · Completed" }
        session.draft("A separate follow-up task"); session.sendMessage()
        pump { sent.size == 2 && session.toki.active?.pending == null && tokiNotification().extras.getString(Notification.EXTRA_TITLE) == "Toki · Queued" }
        val second = sent.last(); assertNotEquals(first, second)
        val secondStart = tokiNotification().`when`
        response.set(tokiWork(conversationId, "completed", first)); session.showConversation(conversationId)
        pump { !session.toki.active!!.busy }
        assertEquals(second, session.toki.active!!.workTurnId)
        assertEquals("Toki · Queued", tokiNotification().extras.getString(Notification.EXTRA_TITLE))
        assertTrue(tokiNotification().flags and Notification.FLAG_ONGOING_EVENT != 0)
        assertEquals(secondStart, tokiNotification().`when`)
        assertTrue(tokiNotification().extras.getString(Notification.EXTRA_TEXT)!!.contains("Last known"))
        response.set(tokiWork(conversationId, "running", second)); session.showConversation(conversationId)
        pump { tokiNotification().extras.getString(Notification.EXTRA_TITLE) == "Toki · Working" }
        assertEquals(secondStart, tokiNotification().`when`)
        response.set(tokiWork(conversationId, "failed", second)); session.showConversation(conversationId)
        pump { tokiNotification().extras.getString(Notification.EXTRA_TITLE) == "Toki · Failed" }
        assertFalse(tokiNotification().flags and Notification.FLAG_ONGOING_EVENT != 0)
    }

    @Test @Config(sdk = [32]) fun tokiNotificationsDoNotRequireRuntimePermissionBeforeAndroid13() {
        val (session, _) = session { request ->
            if (request.optString("action") == "show") tokiWork(request.getString("id"), "running") else null
        }
        session.setForeground(true); session.showConversation(conversationId)
        pump { notificationManager.activeNotifications.size == 1 }
        assertFalse(session.takeNotificationPermissionRequest())
        session.signOut(); assertTrue(notificationManager.activeNotifications.isEmpty())
    }

    @Test fun tokiAccessLossAndLateCanonicalLinkCannotRestoreNotifications() {
        shadowOf(context).grantPermissions(Manifest.permission.POST_NOTIFICATIONS)
        for (reason in listOf("forbidden", "not_found", "source_forbidden", "late_link")) {
            val state = java.util.concurrent.atomic.AtomicReference("running")
            val linkStarted = CountDownLatch(1)
            val linkRelease = CountDownLatch(if (reason == "late_link") 1 else 0).also(releases::add)
            val (session, _) = session { request ->
                when {
                    request.optString("action") == "show" -> if (state.get() == "running") tokiWork(request.getString("id"), "running").apply {
                        if (reason == "source_forbidden") getJSONObject("conversation").put("translation_session_id", translationId)
                    } else failure(state.get())
                    request.optString("operation") == "translation" && state.get() == "forbidden" -> failure("forbidden")
                    request.optString("operation") == "navigation" -> { linkStarted.countDown(); linkRelease.await(8, TimeUnit.SECONDS); null }
                    else -> null
                }
            }
            session.setForeground(true); session.showConversation(conversationId)
            pump { linkStarted.count == 0L }
            if (reason == "late_link") session.signOut()
            else {
                pump { notificationManager.activeNotifications.size == 1 }
                if (reason == "source_forbidden") {
                    pump { session.toki.active!!.source.loaded }
                    state.set("forbidden"); session.retrySource()
                    pump { session.toki.active!!.source.error != null }
                } else {
                    state.set(reason); session.showConversation(conversationId)
                    pump { session.toki.active?.unavailable == true }
                }
            }
            assertTrue(notificationManager.activeNotifications.isEmpty())
            linkRelease.countDown(); Thread.sleep(50); shadowOf(Looper.getMainLooper()).idle()
            assertTrue(notificationManager.activeNotifications.isEmpty()); session.setForeground(false)
        }
    }

    @Test fun fluentLanguagesUseIndependentProfilePutAndPreserveFailedDrafts() {
        var fail = true
        val (session, _) = session { request ->
            when (request.optString("operation")) {
                "resource" -> if (request.optString("resource") == "profile") JSONObject().put("user", JSONObject().put("fluent_languages", JSONArray().put("es"))) else null
                "fluent_languages" -> if (fail) failure("forbidden", "user:write required") else JSONObject().put("user", JSONObject().put("fluent_languages", request.getJSONArray("fluent_languages")))
                else -> null
            }
        }
        pump { session.server != null && !session.busy }
        session.loadProfile(); pump { session.profile.loaded }
        session.editFluentLanguages(); assertEquals("es", session.fluentLanguages.draft)
        session.fluentLanguages.draft = "ar, zh-Hant"; session.saveFluentLanguages()
        pump { session.fluentLanguages.error != null }
        assertEquals("ar, zh-Hant", session.fluentLanguages.draft); assertTrue(session.hasProtectedWork)
        fail = false; session.saveFluentLanguages(); pump { session.fluentLanguages.draft == null }
        val write = calls.last { it.optString("operation") == "fluent_languages" }
        assertEquals(listOf("ar", "zh-Hant"), (0 until write.getJSONArray("fluent_languages").length()).map { write.getJSONArray("fluent_languages").getString(it) })
        assertFalse(write.has("locale")); assertFalse(session.hasProtectedWork)
    }

    @Test @Config(sdk = [32, 35]) fun appLanguagePickerUsesOnlyPackagedCatalogsAndPlatformStorage() {
        val controller = Robolectric.buildActivity(RenderActivity::class.java).setup()
        val activity = controller.get()
        val metadata = activity.packageManager.getServiceInfo(ComponentName(activity,
            "androidx.appcompat.app.AppLocalesMetadataHolderService"), PackageManager.GET_META_DATA or PackageManager.MATCH_DISABLED_COMPONENTS)
        assertTrue(metadata.metaData.getBoolean("autoStoreLocales"))
        assertFalse(metadata.exported)
        val packaged = activity.appLanguageTags()
        assertTrue(packaged.contains("en"))
        val catalogs = File("../locales").listFiles().orEmpty().filter { File(it, "android/strings.xml").isFile }.map { it.name }
        assertEquals((listOf("en") + catalogs).distinct().sorted().map { java.util.Locale.forLanguageTag(it).toLanguageTag() }, packaged)
        fun picker(): androidx.appcompat.app.AlertDialog {
            val view = FeatureViews(activity).profile(FeatureModel(), "https://glossia.ai", null, null, {}, {})
            activity.setContentView(view)
            descendants(view).filterIsInstance<MaterialButton>().single { it.contentDescription?.startsWith("App language:") == true }.performClick()
            return ShadowDialog.getLatestDialog() as androidx.appcompat.app.AlertDialog
        }
        try {
            val dialog = picker()
            val names = (0 until dialog.listView.count).map { dialog.listView.adapter.getItem(it).toString() }
            assertEquals(listOf("System default") + packaged.map { tag -> java.util.Locale.forLanguageTag(tag).let { it.getDisplayName(it) } }, names)
            assertEquals(0, dialog.listView.checkedItemPosition)
            assertTrue(names.contains("English"))
            val decor = dialog.window!!.decorView
            decor.measure(View.MeasureSpec.makeMeasureSpec(1024, View.MeasureSpec.EXACTLY), View.MeasureSpec.makeMeasureSpec(2000, View.MeasureSpec.AT_MOST))
            decor.layout(0, 0, 1024, decor.measuredHeight)
            val bitmap = rendered(decor)
            File(artifacts, "android-app-language-picker-api${android.os.Build.VERSION.SDK_INT}.png").outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
            bitmap.recycle()
            val english = names.indexOf("English")
            dialog.listView.performItemClick(null, english, english.toLong())
            pump { LocaleManagerCompat.getApplicationLocales(activity).toLanguageTags() == "en" }
            assertEquals("en", AppCompatDelegate.getApplicationLocales().toLanguageTags())
            val selected = picker()
            assertEquals(english, selected.listView.checkedItemPosition)
            selected.listView.performItemClick(null, 0, 0)
            pump { LocaleManagerCompat.getApplicationLocales(activity).isEmpty }
            assertTrue(AppCompatDelegate.getApplicationLocales().isEmpty)
        } finally {
            AppCompatDelegate.setApplicationLocales(LocaleListCompat.getEmptyLocaleList())
            controller.pause().stop().destroy()
        }
    }

    @Test @Config(sdk = [32], application = GlossiaApplication::class, qualifiers = "ar-rEG-ldrtl-w411dp-h891dp-420dpi")
    fun appLanguageRecreationPreservesSessionChatAndUnsavedFluencyAndMirrorsBack() {
        val (session, storage) = session { request ->
            if (request.optString("operation") == "resource" && request.optString("resource") == "profile")
                JSONObject().put("user", JSONObject().put("fluent_languages", JSONArray().put("es"))) else null
        }
        // Install the existing fake transport at the Application boundary; run the
        // real Activity, picker, AppCompat delegate and resource configurations.
        GlossiaApplication::class.java.getDeclaredField("session\$delegate").apply { isAccessible = true }
            .set(context, lazyOf(session))
        session.newConversation(); session.draft("Keep my private chat مرحبا 🌍")
        val thread = session.toki.active!!
        session.selectTab("Profile"); pump { session.profile.loaded }
        val originalCredentials = storage.load("session").toString()
        val controller = Robolectric.buildActivity(MainActivity::class.java).setup().visible()
        fun root() = controller.get().findViewById<View>(R.id.root)
        fun capture(name: String) {
            root().measure(View.MeasureSpec.makeMeasureSpec(1080, View.MeasureSpec.EXACTLY), View.MeasureSpec.makeMeasureSpec(2340, View.MeasureSpec.EXACTLY))
            root().layout(0, 0, 1080, 2340)
            val bitmap = rendered(root())
            File(artifacts, "android-app-language-$name.png").outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
            bitmap.recycle()
        }
        fun choose(tag: String) {
            descendants(root()).filterIsInstance<MaterialButton>().single { it.contentDescription?.startsWith("App language:") == true }.performClick()
            val dialog = ShadowDialog.getLatestDialog() as androidx.appcompat.app.AlertDialog
            val index = (listOf("") + controller.get().appLanguageTags()).indexOf(tag)
            dialog.listView.performItemClick(null, index, index.toLong())
            shadowOf(Looper.getMainLooper()).idle()
        }
        try {
            assertEquals(View.LAYOUT_DIRECTION_RTL, root().layoutDirection)
            capture("system-rtl-profile")
            descendants(root()).filterIsInstance<MaterialButton>().single { it.text == "Edit fluent languages" }.performClick()
            val field = descendants(root()).filterIsInstance<TextInputEditText>().single()
            field.setText("ar, zh-Hant")
            val before = controller.get()
            choose("en")
            pump { controller.get() !== before }
            assertEquals(View.LAYOUT_DIRECTION_LTR, root().layoutDirection)
            assertEquals("en", controller.get().resources.configuration.locales[0].language)
            assertEquals("1,234", controller.get().nativeFormat("%,d", 1234))
            assertEquals("Oct 25, 2026", controller.get().displayDate("2026-10-25T08:00:00Z"))
            assertEquals("ar, zh-Hant", descendants(root()).filterIsInstance<TextInputEditText>().single().text.toString())
            assertSame(session, (controller.get().application as GlossiaApplication).session)
            assertSame(thread, session.toki.threads[thread.id])
            assertEquals("Keep my private chat مرحبا 🌍", thread.draft)
            assertEquals(originalCredentials, storage.load("session").toString())
            assertEquals("es", session.profile.data!!.getJSONObject("user").getJSONArray("fluent_languages").getString(0))
            assertFalse(calls.any { it.optString("operation") == "fluent_languages" })
            capture("english-fluency")
            pump { LocaleManagerCompat.getApplicationLocales(context).toLanguageTags() == "en" }
            assertEquals("1,234", context.nativeFormat("%,d", 1234))
            // Robolectric's recreation rewrites its global device qualifiers too.
            // Restore the device environment and explicitly relaunch for the
            // return-to-system check. The English switch above recreates itself.
            choose("")
            pump { LocaleManagerCompat.getApplicationLocales(context).isEmpty }
            RuntimeEnvironment.setQualifiers("ar-rEG-ldrtl-w411dp-h891dp-420dpi")
            controller.recreate()
            assertEquals(View.LAYOUT_DIRECTION_RTL, root().layoutDirection)
            assertEquals("ar", controller.get().resources.configuration.locales[0].language)
            assertEquals(java.text.NumberFormat.getIntegerInstance(java.util.Locale.forLanguageTag("ar-EG")).format(1234),
                controller.get().nativeFormat("%,d", 1234))
            assertEquals("ar, zh-Hant", session.fluentLanguages.draft)
            capture("system-rtl-fluency")
        } finally {
            AppCompatDelegate.setApplicationLocales(LocaleListCompat.getEmptyLocaleList())
            controller.pause().stop().destroy()
        }
    }

    @Test fun appLanguageFormatsDatesAndAnalyticsWithResourceLocaleNotProcessDefault() {
        val controller = Robolectric.buildActivity(RenderActivity::class.java).setup()
        val original = java.util.Locale.getDefault()
        try {
            val english = android.view.ContextThemeWrapper(controller.get().createConfigurationContext(android.content.res.Configuration(
                controller.get().resources.configuration).apply { setLocale(java.util.Locale.ENGLISH) }), R.style.GlossiaTheme)
            java.util.Locale.setDefault(java.util.Locale.forLanguageTag("ar-EG"))
            assertEquals("1,234", english.nativeFormat("%,d", 1234))
            assertEquals("Oct 25, 2026", english.displayDate("2026-10-25T08:00:00Z"))
            val model = AnalyticsModel().apply {
                loaded = true; data = JSONObject("""{"summary":{"pageviews":12480},"top_pages":[]}""")
            }
            val view = FeatureViews(english).analytics(model, true, {}, {})
            assertTrue(descendants(view).filterIsInstance<TextView>().any { it.text == "12,480" })
            assertEquals("not a date", english.displayDate("not a date"))
        } finally {
            java.util.Locale.setDefault(original)
            controller.pause().stop().destroy()
        }
    }

    @Test @Config(application = GlossiaApplication::class)
    fun appLanguageLayoutUsesLocaleWhenFrameworkDirectionBitIsStale() {
        val (session, _) = session(signedIn = false)
        GlossiaApplication::class.java.getDeclaredField("session\$delegate").apply { isAccessible = true }
            .set(context, lazyOf(session))
        for ((locale, staleDirection) in listOf("ar-rEG" to "ldltr", "en" to "ldrtl")) {
            RuntimeEnvironment.setQualifiers("$locale-$staleDirection-w411dp-h891dp-420dpi")
            val controller = Robolectric.buildActivity(MainActivity::class.java).setup().visible()
            val root = controller.get().findViewById<View>(R.id.root)
            val expected = if (locale == "en") View.LAYOUT_DIRECTION_LTR else View.LAYOUT_DIRECTION_RTL
            assertEquals(expected, root.layoutDirection)
            descendants(root).filterIsInstance<MaterialButton>().single { it.text == "Self-hosted server" }.performClick()
            val dialog = ShadowDialog.getLatestDialog() as androidx.appcompat.app.AlertDialog
            assertEquals(expected, dialog.window!!.decorView.layoutDirection)
            dialog.dismiss()
            controller.pause().stop().destroy()
        }
    }

    @Test fun goalEligibilityRequiresACompletedReplyToTheLatestHumanTurn() {
        val model = ConversationModel(goalChatId, created = true)
        model.accept(goalConversation()); assertTrue(model.canResolve)
        model.messages.getJSONObject(model.messages.length() - 1).remove("reply_to_id")
        assertFalse(model.canResolve)
        model.accept(goalConversation()); model.messages.getJSONObject(model.messages.length() - 1).put("status", "running")
        assertFalse(model.canResolve)
        model.accept(goalConversation()); model.messages.put(JSONObject().put("id", reviewId).put("role", "user").put("content", "Newer turn"))
        assertFalse(model.canResolve)
        for (phase in listOf("queued", "running", "failed")) { model.accept(goalConversation(phase = phase)); assertFalse(model.canResolve) }
        model.accept(goalConversation()); model.beginResolution(); model.messages.getJSONObject(model.messages.length() - 1).put("id", reviewId)
        assertFalse(model.canSaveDecision); assertTrue(model.protectsDecision)
    }

    @Test fun idleSharedGoalPollsTeammatesAndPreservesFrozenProposalAndEditor() {
        var response = goalConversation()
        val (session, _) = session { request -> if (request.optString("operation") == "conversation") response else null }
        session.showConversation(goalChatId); pump { session.toki.active?.loaded == true }
        val thread = session.toki.active!!
        thread.draft = "Unsent chat"; session.setForeground(true)
        pump { !thread.busy }
        response = goalConversation().apply { getJSONArray("messages").put(JSONObject().put("id", reviewId).put("role", "user").put("content", "Another linguist asks")) }
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(2600))
        pump { thread.messages.length() == 4 && !thread.busy }
        assertEquals("Unsent chat", thread.draft); assertFalse(thread.canResolve)
        thread.draft = ""; response = goalConversation(); session.showConversation(goalChatId); pump { !thread.busy }
        thread.beginResolution(); thread.decision!!.apply { answer = "Reviewed decision"; reusable = true; guidance = "Independent rule" }
        val controller = Robolectric.buildActivity(RenderActivity::class.java).setup(); val activity = controller.get()
        val view = TokiView(activity, session.toki, {}, {}, {}, {}, {}).apply { render(true) }
        val editor = view.findViewWithTag<TextInputEditText>("goal-decision")!!
        editor.requestFocus(); editor.setSelection(3)
        response = goalConversation().apply { getJSONArray("messages").getJSONObject(2).put("id", reviewId) }
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(2600)); pump { !thread.busy && thread.completedReply?.optString("id") == reviewId }
        view.render(true)
        assertSame(editor, view.findViewWithTag<TextInputEditText>("goal-decision")); assertEquals(3, editor.selectionStart)
        assertEquals("Reviewed decision", thread.decision!!.answer); assertFalse(thread.canSaveDecision)
        response = goalConversation("answered")
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(2600)); pump { thread.goalClosed && !thread.busy }
        view.render(true)
        assertSame(editor, view.findViewWithTag<TextInputEditText>("goal-decision")); assertEquals("Independent rule", thread.decision!!.guidance)
        assertTrue(thread.protectsDecision); assertFalse(thread.canSaveDecision); assertNotNull(thread.resolutionError)
        controller.pause().stop().destroy()
        val ordinary = ConversationModel(reviewId, true).apply { accept(conversation(reviewId, "completed")) }
        assertFalse(ordinary.shouldPollVisible)
    }

    @Test fun sharedGoalsRenderMirroredArabicHebrewAndLargeTextWithRealViews() {
        for (language in listOf("ar", "he")) for (large in listOf(false, true)) {
            RuntimeEnvironment.setQualifiers("$language-r${if (language == "ar") "EG" else "IL"}-ldrtl-w411dp-h891dp-420dpi")
            RuntimeEnvironment.setFontScale(if (large) 1.6f else 1f)
            val controller = Robolectric.buildActivity(RenderActivity::class.java).setup()
            val activity = controller.get()
            val thread = ConversationModel(goalChatId, created = true).apply {
                accept(goalConversation()); draft = "مرحبا L10N/ar.md שלום"
                goal!!.put("locale", language).put("question", if (language == "ar") "هل نخاطب القارئ بصيغة رسمية أم ودية؟" else "באיזה סגנון נפנה לקוראים?")
                    .put("output_path", "locales/$language/welcome.json").put("translation_excerpt", if (language == "ar") "مرحبًا بعودتك!" else "ברוכים השבים!")
            }
            val model = TokiModel().apply { threads[goalChatId] = thread; activeId = goalChatId }
            val voice = TokiVoiceInput(TestTokiVoiceCapture(), { true }, {}, {}, {})
            val view = TokiView(activity, model, { thread.draft = it }, {}, {}, {}, {}, voice = voice).apply { layoutDirection = View.LAYOUT_DIRECTION_RTL }
            view.render(true); activity.setContentView(view)
            view.setBackgroundColor(activity.token(R.color.glossia_background))
            activity.appearance.apply(activity, view)
            descendants(view).filterIsInstance<MaterialButton>().single { it.text == "Source and translation context" }.performClick()
            view.measure(View.MeasureSpec.makeMeasureSpec(1080, View.MeasureSpec.EXACTLY), View.MeasureSpec.makeMeasureSpec(2340, View.MeasureSpec.EXACTLY)); view.layout(0, 0, 1080, 2340)
            shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(32))
            val attach = descendants(view).single { it.contentDescription == "Import text file; images unavailable" }
            val send = descendants(view).single { it.contentDescription == "Send message" }
            val mic = descendants(view).single { it.contentDescription == "Transcribe a voice message" }
            fun position(v: View) = IntArray(2).also { v.getLocationOnScreen(it) }[0]
            assertTrue(position(attach) > position(mic)); assertTrue(position(mic) > position(send))
            assertTrue(send.width >= activity.dp(48)); assertTrue(mic.isEnabled)
            assertEquals("مرحبا L10N/ar.md שלום", findInput(view)!!.text.toString())
            val bitmap = Bitmap.createBitmap(1080, 2340, Bitmap.Config.ARGB_8888); view.draw(Canvas(bitmap))
            File(artifacts, "android-goal-$language${if (large) "-large" else ""}.png").outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }; bitmap.recycle()
            controller.pause().stop().destroy()
        }
        RuntimeEnvironment.setFontScale(1f)
    }

    @Test fun productionViewsRenderLightAndDarkAndChatStates() {
        for (custom in listOf(false, true)) for (night in listOf(false, true)) {
            RuntimeEnvironment.setQualifiers("w411dp-h891dp-${if (night) "night" else "notnight"}-420dpi")
            val controller = Robolectric.buildActivity(RenderActivity::class.java).setup()
            val activity = controller.get()
            val login = GlossiaLoginView(activity, {}, {}, {}, {}) // Created before the catalog arrives.
            if (custom) {
                activity.appearance.close()
                activity.appearance = appearance { catalog() }
                activity.appearance.configure("https://forest.example")
                pump { activity.appearance.catalog != null }
            }
            val prefix = if (custom) "custom-" else ""
            val root = activity.layoutInflater.inflate(R.layout.activity_main, null)
            activity.setContentView(root)
            val screen = root.findViewById<FrameLayout>(R.id.screen)
            val toolbar = root.findViewById<MaterialToolbar>(R.id.toolbar)
            val nav = root.findViewById<BottomNavigationView>(R.id.navigation)
            fun show(name: String, view: View, tab: Int? = null, thread: ConversationModel? = null) {
                toolbar.visibility = if (tab == null) View.GONE else View.VISIBLE
                nav.visibility = toolbar.visibility
                if (tab != null) { nav.selectedItemId = tab; toolbar.title = nav.menu.findItem(tab).title; toolbar.subtitle = "glossia / website" }
                toolbar.menu.findItem(R.id.compose_conversation).isVisible = tab == R.id.toki && thread == null
                if (thread != null) {
                    toolbar.title = if (!thread.created) "New conversation" else thread.conversation?.optionalString("title") ?: "Conversation"
                    toolbar.setNavigationIcon(R.drawable.ic_back)
                    toolbar.navigationContentDescription = "Back to conversations"
                } else toolbar.navigationIcon = null
                if (screen.getChildAt(0) !== view) { screen.removeAllViews(); screen.addView(view) }
                activity.appearance.apply(activity, root)
                if (custom) {
                    val palette = catalog().getJSONArray("themes").getJSONObject(0).getJSONObject(if (night) "dark" else "light")
                    assertEquals(Color.parseColor(palette.getString("background")), (root.background as ColorDrawable).color)
                    descendants(view).filterIsInstance<MaterialButton>().forEach { button ->
                        assertEquals(activity.dp(8), button.cornerRadius)
                        if (button.getTag(R.id.appearance_primary) == true) {
                            assertEquals(Color.parseColor(palette.getString("accent")), button.backgroundTintList!!.defaultColor)
                            assertEquals(Color.parseColor(palette.getString("on_accent")), button.textColors.defaultColor)
                            if (!button.isEnabled) assertTrue(Color.alpha(button.currentTextColor) < 255)
                        }
                    }
                    descendants(view).filterIsInstance<MaterialCardView>().forEach {
                        assertEquals(activity.dp(if (it.getTag(R.id.appearance_surface) == "composer") 28 else 12).toFloat(), it.radius, 1f)
                    }
                }
                root.measure(View.MeasureSpec.makeMeasureSpec(1080, View.MeasureSpec.EXACTLY), View.MeasureSpec.makeMeasureSpec(2340, View.MeasureSpec.EXACTLY))
                root.layout(0, 0, 1080, 2340)
                shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(32))
                val bitmap = Bitmap.createBitmap(1080, 2340, Bitmap.Config.ARGB_8888)
                root.draw(Canvas(bitmap))
                File(artifacts, "android-$prefix$name-${if (night) "dark" else "light"}.png").outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
                bitmap.recycle()
            }
            show("login-fixture", login)
            assertFalse(descendants(login).filterIsInstance<TextView>().any { it.text.contains("Toki") })
            val model = TokiModel()
            model.history.accept(JSONObject("""{"conversations":[],"meta":{}}"""), 1)
            val toki = TokiView(activity, model, { model.active!!.draft = it }, {}, {}, {}, {})
            toki.render(true); show("toki-empty", toki, R.id.toki)
            assertNull(findInput(toki)); assertTrue(descendants(toki).filterIsInstance<TokiCompanionView>().isEmpty())
            model.newConversation(); toki.render(true); show("toki-new-conversation", toki, R.id.toki, model.active)
            val rig = descendants(toki).filterIsInstance<TokiCompanionView>().single()
            ShadowChoreographer.setPaused(true)
            ShadowChoreographer.setFrameDelay(Duration.ofMillis(16))
            assertTrue(rig.performClick())
            advanceFrames(480)
            show("toki-wave", toki, R.id.toki, model.active)
            advanceFrames(2000)
            show("toki-settled", toki, R.id.toki, model.active)
            ShadowChoreographer.setPaused(false)
            if (custom) {
                descendants(toki).filterIsInstance<com.google.android.material.chip.Chip>().first().performClick()
                assertEquals("Help me get started", model.active!!.draft)
                descendants(toki).filterIsInstance<com.google.android.material.chip.Chip>().forEach {
                    assertEquals(activity.token(R.color.glossia_text), it.currentTextColor)
                }
                assertEquals("Help me get started", findInput(toki)!!.text.toString())
            }
            val thread = model.newConversation()
            thread.accept(conversation(thread.id, "completed").put("messages", JSONArray("""[{"id":"1","role":"user","content":"How can I reach more readers?"},{"id":"2","role":"assistant","content":"Start with the languages your audience already speaks. I can help you review your translations and understand your locale gaps."}]""")))
            toki.render(true); show("toki-chat", toki, R.id.toki, thread)
            thread.accept(conversation(thread.id, "failed")); toki.render(true); show("toki-failed", toki, R.id.toki, thread)
            thread.pending = PendingMessage("immutable", "Please review this translation."); thread.draft = thread.pending!!.content; thread.error = "Connection lost. Your message was not confirmed. Retry safely."
            toki.render(true); show("toki-retry", toki, R.id.toki, thread)
            model.history.accept(JSONObject("""{"conversations":[{"id":"one","title":"Reaching new readers","status":"completed","updated_at":"2026-10-25T08:00:00Z"},{"id":"two","title":"Reviewing Spanish translations","status":"running","updated_at":"2026-10-24T08:00:00Z"}],"meta":{"has_next_page":true}}"""), 1)
            model.activeId = null; toki.render(true); show("toki-history", toki, R.id.toki)
            thread.clear(); thread.created = true; thread.unavailable = true
            thread.error = "This conversation is no longer available. Retry to check access, or start a new conversation."
            model.activeId = thread.id; toki.render(true); show("toki-unavailable", toki, R.id.toki, thread)
            val views = FeatureViews(activity)
            val translations = PageModel("translations", "sessions").apply { accept(JSONObject("""{"sessions":[{"id":"1","status":"completed","commit_message":"A warmer welcome, in every language","source_language":"en","target_languages":["es","fr","de"],"translated_content_count":128,"summary":"Updated homepage and onboarding translations.","inserted_at":"2026-10-25T08:00:00Z"}],"meta":{"has_next_page":true}}"""), 1) }
            show("translations", views.translations(translations, true, {}, {}), R.id.translations)
            val detail = TranslationModel().apply { id = translationId; loaded = true; data = translationRecord() }
            var discussed = false
            var shared = false
            val detailView = views.translation(detail, {}, {}, { discussed = true }, { shared = true })
            show("translation-detail", detailView, R.id.translations)
            descendants(detailView).filterIsInstance<MaterialButton>().single { it.text == "Discuss with Toki" }.performClick()
            assertTrue(discussed)
            descendants(detailView).filterIsInstance<MaterialButton>().single { it.text == "Share translation link" }.performClick()
            assertTrue(shared)
            for (state in listOf("planning", "running", "reconnecting", "completed", "failed", "cancelled", "zero", "missing")) {
                val snapshot = progressSnapshot(
                    status = if (state in listOf("completed", "failed", "cancelled")) state else "running",
                    assessed = state != "planning", done = if (state == "completed") 3 else 1)
                if (state == "zero") {
                    snapshot.getJSONObject("progress").getJSONObject("summary").put("needs_translation", 0).put("done", 0)
                    snapshot.getJSONObject("progress").put("items", JSONArray())
                }
                if (state == "missing") snapshot.remove("progress")
                val liveDetail = TranslationModel().apply {
                    id = translationId; acceptSnapshot(snapshot)
                    liveState = if (state == "reconnecting") "reconnecting" else "live"
                }
                val liveView = views.translation(liveDetail, {}, {}, {})
                show("translation-live-$state", liveView, R.id.translations)
                val labels = descendants(liveView).filterIsInstance<TextView>().map { it.text.toString() }
                val indicators = descendants(liveView).filterIsInstance<LinearProgressIndicator>()
                when (state) {
                    "planning", "missing" -> {
                        assertTrue(indicators.single().isIndeterminate)
                        assertTrue(labels.contains("Planning translations…"))
                        assertFalse(labels.any { it.contains(" / ") && it.endsWith("translated") })
                    }
                    "zero" -> { assertTrue(indicators.isEmpty()); assertTrue(labels.contains("No translation work required")) }
                    else -> {
                        assertFalse(indicators.single().isIndeterminate)
                        assertEquals(if (state == "completed") 1000 else 333, indicators.single().progress)
                        assertTrue(labels.contains("${if (state == "completed") 3 else 1} / 3 translated"))
                        assertTrue(labels.contains("\u2066locales/es/home.json\u2069")); assertTrue(labels.contains("\u2068es\u2069 · Translated"))
                        assertEquals(activity.token(R.color.glossia_primary), indicators.single().indicatorColor.single())
                        assertEquals(activity.token(R.color.glossia_border), indicators.single().trackColor)
                        if (state == "reconnecting") assertTrue(labels.any { it.startsWith("Reconnecting…") })
                        if (state in listOf("completed", "failed", "cancelled")) assertTrue(labels.contains(state.replaceFirstChar { it.uppercase() }))
                    }
                }
            }
            for (state in listOf("open", "answered", "stale", "denied", "loading", "error", "legacy")) {
                val reviewModel = TranslationModel().apply {
                    id = translationId; data = translationRecord().put("status", "awaiting_input"); loaded = true
                    liveState = "connecting"
                    reviews.loaded = true
                    if (state == "loading") { reviews.busy = true; reviews.loaded = false }
                    else if (state == "denied") { reviews.error = "You do not have permission to view linguistic reviews." }
                    else if (state == "error") reviews.error = "Offline. Refresh reviews to try again."
                    else reviews.items.add(reviewRecord(if (state in listOf("answered", "stale")) state else "open").apply {
                        if (state == "answered") { put("answer", "Use informal tú."); put("guidance", "Use informal Spanish in onboarding.")
                            put("context_path", "L10N/es.md"); put("resumed_session_id", "aaa12345-802e-4f91-9112-77d8a919efc5") }
                    })
                    if (state == "legacy") reviews.items[0].remove("conversation_id")
                }
                var opened: String? = null
                val reviewView = views.translation(reviewModel, {}, {}, {}, openReview = { opened = it })
                show("review-$state", reviewView, R.id.translations)
                val labels = descendants(reviewView).filterIsInstance<TextView>().map { it.text.toString() }
                assertFalse(labels.any { it.startsWith("Connecting") || it.startsWith("Reconnecting") })
                assertFalse(labels.contains("Planning translations…"))
                assertFalse(labels.contains("Translating files"))
                assertFalse(labels.contains("Submit answer"))
                if (state in listOf("denied", "loading", "error")) assertFalse(labels.contains("No linguistic questions for this translation."))
                if (state in listOf("open", "answered", "stale")) {
                    descendants(reviewView).filterIsInstance<MaterialButton>().single { it.text == "Open shared Toki conversation" }.performClick()
                    assertEquals(goalChatId, opened)
                }
            }
            for (state in listOf("active", "editing", "resolved", "stale", "error", "permission", "denied", "closed-draft")) {
                val goals = TokiModel()
                val thread = ConversationModel(goalChatId, created = true).apply {
                    accept(goalConversation(if (state == "resolved") "answered" else if (state == "stale") "stale" else "open"))
                    messages = JSONArray().put(messages.getJSONObject(0))
                        .put(JSONObject().put("id", "ddd12345-802e-4f91-9112-77d8a919efc5").put("role", "user").put("author", "Sam").put("content", "Let's keep the welcome approachable."))
                        .put(messages.getJSONObject(1).put("author", "Alex")).put(messages.getJSONObject(2))
                    goal!!.put("participants", JSONArray().put(JSONObject().put("id", "alex").put("name", "Alex")).put(JSONObject().put("id", "sam").put("name", "Sam")))
                    if (state == "resolved") goal!!.put("answer", "Use informal tú.").put("guidance", "Use informal Spanish in onboarding.").put("context_path", "L10N/es.md").put("resumed_session_id", goalReplyId)
                    if (state in listOf("editing", "error", "permission", "closed-draft")) {
                        beginResolution(); decision!!.reusable = true; decision!!.guidance = "Use informal Spanish in onboarding."
                        if (state == "closed-draft") accept(goalConversation("answered"))
                        else if (state != "editing") { resolutionNeedsRefresh = true; resolutionError = if (state == "permission") "Saving requires translation:write permission. Refresh before explicitly retrying." else "Connection lost. Refresh before explicitly retrying; the decision may already be saved." }
                    }
                    if (state == "denied") { clear(); created = true; unavailable = true; error = "You do not have permission to view this shared conversation." }
                }
                goals.threads[goalChatId] = thread; goals.activeId = goalChatId
                var resumed: String? = null
                val capture = TestTokiVoiceCapture()
                val voice = TokiVoiceInput(capture, { true }, {}, { thread.draft += it }, {})
                val goalView = TokiView(activity, goals, { thread.draft = it }, {}, {}, {}, {}, source = { resumed = it }, voice = voice)
                goalView.render(true); show("goal-$state", goalView, R.id.toki, thread)
                val labels = descendants(goalView).filterIsInstance<TextView>().map { it.text.toString() }
                if (state == "active") {
                    assertTrue(labels.contains("Alex")); assertTrue(labels.contains("Sam"))
                    assertFalse(labels.contains("Linguist")); assertFalse(labels.contains("You")); assertTrue(thread.canResolve)
                    thread.messages.getJSONObject(2).remove("author"); goalView.render(true)
                    assertTrue(descendants(goalView).filterIsInstance<TextView>().any { it.text == "Linguist" })
                    thread.messages.getJSONObject(2).put("author", "Alex"); goalView.render(true)
                }
                if (state == "resolved") {
                    descendants(goalView).filterIsInstance<MaterialButton>().single { it.text == "View resumed translation" }.performClick()
                    assertEquals(goalReplyId, resumed)
                }
                if (state == "editing") {
                    val scopes = descendants(goalView).filterIsInstance<com.google.android.material.chip.Chip>()
                    assertEquals("This locale", scopes.single { it.isChecked }.text.toString())
                    assertTrue(scopes.single { it.isChecked }.isCheckedIconVisible)
                    scopes.single { it.text == "Whole project" }.performClick()
                    assertEquals("project", thread.decision!!.scope)
                    assertEquals("Whole project", scopes.single { it.isChecked }.text.toString())
                }
                if (state in listOf("error", "permission", "closed-draft")) assertFalse(descendants(goalView).filterIsInstance<MaterialButton>().single { it.text == "Save decision and resume" }.isEnabled)
                if (state == "active") {
                    voice.start(); repeat(24) { capture.level!!((it % 9).toFloat()) }
                    goalView.refreshVoice(); show("goal-dictation-measured-fixture", goalView, R.id.toki, thread)
                    voice.cancel()
                }
            }
            val fluent = FluentLanguagesModel().apply { draft = "ar, he, es" }
            val fluentView = activity.scroll(activity.column().apply { addView(activity.fluentLanguagesView(fluent, {}, {})) })
            show("fluency", fluentView, R.id.profile)
            val fluentField = descendants(fluentView).filterIsInstance<com.google.android.material.textfield.TextInputLayout>().single()
            assertNull(fluentField.editText!!.backgroundTintList)
            assertEquals(activity.token(R.color.glossia_surface), fluentField.boxBackgroundColor)
            val sourceThread = model.newConversation(translationId).apply {
                source.loaded = true; source.data = translationRecord()
            }
            var openedSource: String? = null
            val sourceToki = TokiView(activity, model, { model.active!!.draft = it }, {}, {}, {}, {}, { openedSource = it })
            sourceToki.render(true); show("toki-source-draft", sourceToki, R.id.toki, sourceThread)
            descendants(sourceToki).filterIsInstance<MaterialButton>().single { it.text == "View source translation" }.performClick()
            assertEquals(translationId, openedSource)
            sourceThread.accept(conversation(sourceThread.id, "completed").put("messages", JSONArray("""[{"id":"source-user","role":"user","content":"Why did the Spanish welcome change?"},{"id":"source-assistant","role":"assistant","content":"Let’s review the wording together using this translation as our starting point."}]""")))
            sourceToki.render(true); show("toki-source-chat", sourceToki, R.id.toki, sourceThread)
            val empty = PageModel("translations", "sessions").apply { accept(JSONObject("""{"sessions":[],"meta":{}}"""), 1) }
            show("translations-empty", views.translations(empty, true, {}, {}), R.id.translations)
            val analytics = AnalyticsModel().apply { loaded = true; data = JSONObject("""{"summary":{"pageviews":12480,"unique_visitors":8290,"locale_gap_visits":1240,"top_country":"Germany","top_browser_language":"German"},"top_pages":[{"pathname":"/","pageviews":8240},{"pathname":"/docs","pageviews":4240}],"days":30}""") }
            show("analytics", views.analytics(analytics, true, {}, {}), R.id.analytics)
            val profile = FeatureModel().apply { loaded = true; data = JSONObject("""{"user":{"name":"Alex Morgan","email":"alex@example.com","handle":"alex","id":"account-123"},"server_version":"2026.10.1"}""") }
            show("profile", views.profile(profile, "https://glossia.ai", "glossia", "website", {}, {}), R.id.profile)
            val pickerModel = WorkspacePickerModel().apply {
                open = true; organization = "glossia"
                projects = JSONArray("""[{"handle":"website","name":"Website"},{"handle":"docs","name":"Documentation"},{"handle":"app","name":"Mobile app"}]""")
            }
            val picker = WorkspacePickerView(activity, pickerModel, JSONArray("""[{"handle":"glossia","name":"Glossia"},{"handle":"other","name":"Other team"}]"""), {}, {})
            picker.render("glossia", "website")
            val dialog = activity.themed(MaterialAlertDialogBuilder(activity).setTitle("Switch workspace").setView(picker).setNegativeButton("Cancel", null).show())
            val decor = dialog.window!!.decorView
            decor.measure(View.MeasureSpec.makeMeasureSpec(1024, View.MeasureSpec.EXACTLY), View.MeasureSpec.makeMeasureSpec(2000, View.MeasureSpec.AT_MOST))
            decor.layout(0, 0, 1024, decor.measuredHeight)
            shadowOf(Looper.getMainLooper()).idle()
            val bitmap = Bitmap.createBitmap(1024, decor.measuredHeight, Bitmap.Config.ARGB_8888)
            decor.draw(Canvas(bitmap))
            File(artifacts, "android-${prefix}workspace-picker-${if (night) "dark" else "light"}.png").outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
            findInput(picker)!!.setText("doc")
            assertEquals("doc", pickerModel.search)
            dialog.dismiss()
            controller.pause().stop().destroy()
        }
    }

    private fun tokiWork(id: String, status: String, turnId: String = translationId) = conversation(id, status)
        .put("messages", JSONArray().put(JSONObject().put("id", turnId).put("role", "user").put("content", "A private request").put("inserted_at", "2026-10-25T08:00:00Z")))

    private fun conversation(id: String, status: String) = JSONObject().put("conversation", JSONObject().put("id", id).put("title", "A conversation with Toki").put("status", status)).put("messages", JSONArray())
}
