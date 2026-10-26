package ai.glossia.mobile

import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

// These models contain no Context, View or Activity. They belong to the
// Application session, not a destination or an Activity's saved-instance bundle.
open class FeatureModel {
    var data: JSONObject? = null
    var loaded = false
    var busy = false
    var error: String? = null

    open fun clear() { data = null; loaded = false; busy = false; error = null }
}

class PageModel(val resource: String, private val collection: String) : FeatureModel() {
    val items = mutableListOf<JSONObject>()
    var page = 0
    var requestedPage = 1
    var hasMore = false

    fun accept(response: JSONObject, requestedPage: Int) {
        if (requestedPage == 1) items.clear()
        val incoming = response.optJSONArray(collection) ?: JSONArray()
        for (index in 0 until incoming.length()) {
            val item = incoming.getJSONObject(index)
            val existing = items.indexOfFirst { it.optionalString("id") == item.optionalString("id") }
            if (existing < 0) items.add(item) else items[existing] = item
        }
        page = requestedPage
        val meta = response.optJSONObject("meta") ?: JSONObject()
        hasMore = when {
            meta.has("has_next_page?") -> meta.optBoolean("has_next_page?")
            meta.has("has_next_page") -> meta.optBoolean("has_next_page")
            meta.has("next_page") -> meta.optInt("next_page") > requestedPage
            else -> meta.optInt("total_pages") > requestedPage
        }
        data = response; loaded = true
    }

    fun remove(id: String) {
        items.removeAll { it.optionalString("id") == id }
        data?.put(collection, JSONArray(items))
    }

    override fun clear() { super.clear(); items.clear(); page = 0; requestedPage = 1; hasMore = false }
}

class AnalyticsModel : FeatureModel() {
    var days = 30
    var ticket = 0
    override fun clear() { super.clear(); days = 30; ticket += 1 }
}

class FluentLanguagesModel {
    var draft: String? = null
    var saving = false
    var error: String? = null
    val languages get() = draft.orEmpty().split(Regex("[,\\s]+")).filter { it.isNotEmpty() }
    val protectsDraft get() = draft != null || saving
    fun clear() { draft = null; saving = false; error = null }
}

class TranslationModel : FeatureModel() {
    var id: String? = null
    var ticket = 0
    val reviews = TranslationReviewsModel()
    var progress: JSONObject? = null
    var liveState = "closed"
    var liveSnapshotRevision = 0L
        private set

    fun acceptSnapshot(snapshot: JSONObject) {
        data = snapshot.getJSONObject("session")
        progress = snapshot.optJSONObject("progress")
        loaded = true; error = null; liveSnapshotRevision += 1
    }

    override fun clear() {
        super.clear(); id = null; ticket += 1
        reviews.clear()
        progress = null; liveState = "closed"; liveSnapshotRevision = 0
    }
}

class ReviewDraft {
    var answer = ""
    var reusable = false
    var guidance = ""
    var scope = "locale"
    val valid get() = answer.isNotBlank() && answer.codePointCount(0, answer.length) <= 8000 &&
        (!reusable || guidance.isNotBlank() && guidance.codePointCount(0, guidance.length) <= 8000)
}

class TranslationReviewsModel : FeatureModel() {
    val items = mutableListOf<JSONObject>()
    var ticket = 0

    fun valid(row: JSONObject, sessionId: String) = row.optionalString("translation_session_id") == sessionId &&
        row.optionalString("id") != null && row.optString("status") in listOf("open", "answered", "stale")

    fun accept(response: JSONObject, sessionId: String) {
        val rows = response.getJSONArray("reviews")
        val incoming = (0 until rows.length()).map { rows.getJSONObject(it) }
        require(incoming.all { valid(it, sessionId) }) { "Glossia returned an invalid linguistic review." }
        items.clear(); items.addAll(incoming); loaded = true
    }

    override fun clear() {
        super.clear(); items.clear(); ticket += 1
    }
}

class WorkspacePickerModel : FeatureModel() {
    var open = false
    var organization: String? = null
    var projects = JSONArray()
    var search = ""
    var ticket = 0
    override fun clear() {
        super.clear(); open = false; organization = null; projects = JSONArray(); search = ""; ticket += 1
    }
}

data class PendingMessage(val id: String, val content: String)

class ConversationModel(val id: String, var created: Boolean = false, translationId: String? = null,
    private val localize: (String) -> String = { it }) : FeatureModel() {
    var draft = ""
    var pending: PendingMessage? = null
    var writeTicket = 0
    var unavailable = false
    var conversation: JSONObject? = null
    var messages = JSONArray()
    var workTurnId: String? = null
        private set
    var workStatus: String? = null
        private set
    var workObservationCurrent = false
        private set
    var translationSessionId: String? = translationId
        private set
    val source = TranslationModel()
    val status get() = conversation?.optString("status") ?: ""
    val running get() = status in listOf("queued", "running")
    val sharedGoal get() = conversation?.optJSONObject("linguistic_review") != null
    val goal get() = conversation?.optJSONObject("linguistic_review")?.takeIf {
        it.optionalString("conversation_id") == id && it.optionalString("id") != null &&
            it.optionalString("translation_session_id") != null && it.optString("status") in listOf("open", "answered", "stale")
    }
    val goalClosed get() = sharedGoal && goal?.optString("status") != "open"
    var decision: ReviewDraft? = null
    var resolutionMessageId: String? = null
    var resolutionAcknowledged = false
    var inputActive = false
    var resolving = false
    var resolutionNeedsRefresh = false
    var resolutionError: String? = null
    val completedReply get() = messages.optJSONObject(messages.length() - 1)?.takeIf {
        status == "completed" && it.optString("role") == "assistant" && it.optString("status") == "completed" &&
            it.optionalString("reply_to_id") != null && it.optionalString("reply_to_id") ==
                (messages.length() - 1 downTo 0).firstNotNullOfOrNull { index -> messages.optJSONObject(index)?.takeIf { message -> message.optString("role") == "user" } }?.optionalString("id") &&
            it.optionalString("id")?.matches(Regex("[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}")) == true
    }
    val canResolve get() = goal?.optString("status") == "open" && completedReply != null &&
        !busy && !running && !resolving && !inputActive && pending == null && draft.isEmpty() && !resolutionNeedsRefresh && !unavailable && error == null
    val canSaveDecision get() = canResolve && decision?.valid == true && resolutionMessageId == completedReply?.optionalString("id")
    val protectsDecision get() = resolving || decision != null || inputActive
    val shouldPollVisible get() = running || goal?.optString("status") == "open"

    fun beginResolution() {
        if (!canResolve || decision != null) return
        resolutionMessageId = completedReply?.optionalString("id")
        decision = ReviewDraft().apply { answer = completedReply?.optString("content") ?: "" }
        resolutionError = null; resolutionAcknowledged = false
    }
    fun discardDecision() { if (!resolving) { decision = null; resolutionMessageId = null; resolutionAcknowledged = false } }

    fun accept(response: JSONObject, sentTurnId: String? = null) {
        val next = response.getJSONObject("conversation")
        require(next.optString("id") == id && (!sharedGoal || next.optJSONObject("linguistic_review") != null)) { "Glossia returned an invalid shared conversation." }
        conversation = next
        if (translationSessionId == null) translationSessionId = conversation?.optionalString("translation_session_id")
        messages = response.optJSONArray("messages") ?: JSONArray()
        val userMessage = (messages.length() - 1 downTo 0).firstNotNullOfOrNull { index ->
            messages.optJSONObject(index)?.takeIf { it.optString("role") == "user" }
        }
        val candidate = sentTurnId ?: userMessage?.optionalString("id")
        // A send acknowledgement binds to the immutable UUID we sent. Later
        // detail responses must identify that turn before ending its activity.
        // Idle/new conversations are also 'completed', so never start from that.
        val pendingOtherTurn = sentTurnId == null && pending?.id?.let { it != candidate } == true
        if (!pendingOtherTurn && candidate != null && (sentTurnId != null || candidate == workTurnId || running)) {
            workTurnId = candidate; workStatus = status; workObservationCurrent = true
        } else if (workTurnId != null) workObservationCurrent = false
        data = response; created = true; loaded = true; unavailable = false
        resolutionNeedsRefresh = false
        if (goalClosed && !resolving && decision != null) {
            if (resolutionAcknowledged) { discardDecision(); resolutionError = null }
            else resolutionError = localize("This goal has closed. Your unsaved decision and guidance are retained below. Copy or explicitly discard the draft; it cannot be saved to a closed goal.")
        }
    }

    fun pauseWorkObservation() { workObservationCurrent = false }
    fun clearWorkObservation() { workTurnId = null; workStatus = null; workObservationCurrent = false }

    override fun clear() {
        super.clear(); draft = ""; pending = null; conversation = null; messages = JSONArray(); created = false; unavailable = false
        decision = null; resolutionMessageId = null; resolving = false; resolutionNeedsRefresh = false; resolutionError = null
        resolutionAcknowledged = false; inputActive = false
        clearWorkObservation()
        translationSessionId = null; source.clear(); writeTicket += 1
    }
}

class TokiModel(private val localize: (String) -> String = { it }) {
    val history = PageModel("conversations", "conversations")
    val threads = mutableMapOf<String, ConversationModel>()
    var activeId: String? = null
    val active get() = threads[activeId]

    fun newConversation(translationId: String? = null): ConversationModel {
        val thread = ConversationModel(UUID.randomUUID().toString(), translationId = translationId, localize = localize)
        threads[thread.id] = thread
        activeId = thread.id
        return thread
    }

    fun clear() {
        history.clear(); threads.values.forEach { it.clear() }; threads.clear(); activeId = null
    }
}
