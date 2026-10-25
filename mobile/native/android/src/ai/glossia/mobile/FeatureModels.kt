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

class TranslationModel : FeatureModel() {
    var id: String? = null
    var ticket = 0
    override fun clear() { super.clear(); id = null; ticket += 1 }
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

class ConversationModel(val id: String, var created: Boolean = false, translationId: String? = null) : FeatureModel() {
    var draft = ""
    var pending: PendingMessage? = null
    var writeTicket = 0
    var unavailable = false
    var conversation: JSONObject? = null
    var messages = JSONArray()
    var translationSessionId: String? = translationId
        private set
    val source = TranslationModel()
    val status get() = conversation?.optString("status") ?: ""
    val running get() = status in listOf("queued", "running")

    fun accept(response: JSONObject) {
        conversation = response.getJSONObject("conversation")
        if (translationSessionId == null) translationSessionId = conversation?.optionalString("translation_session_id")
        messages = response.optJSONArray("messages") ?: JSONArray()
        data = response; created = true; loaded = true; unavailable = false
    }

    override fun clear() {
        super.clear(); draft = ""; pending = null; conversation = null; messages = JSONArray(); created = false; unavailable = false
        translationSessionId = null; source.clear(); writeTicket += 1
    }
}

class TokiModel {
    val history = PageModel("conversations", "conversations")
    val threads = mutableMapOf<String, ConversationModel>()
    var activeId: String? = null
    val active get() = threads[activeId]

    fun newConversation(translationId: String? = null): ConversationModel {
        val thread = ConversationModel(UUID.randomUUID().toString(), translationId = translationId)
        threads[thread.id] = thread
        activeId = thread.id
        return thread
    }

    fun clear() {
        history.clear(); threads.values.forEach { it.clear() }; threads.clear(); activeId = null
    }
}
