package ai.glossia.mobile

import android.content.Intent
import android.net.Uri
import org.json.JSONObject

enum class GlossiaScreen(val wire: String, val tab: String) {
    TOKI("toki", "Toki"), CONVERSATION("conversation", "Toki"),
    NEW_CONVERSATION("new_conversation", "Toki"), TRANSLATIONS("translations", "Translations"),
    TRANSLATION("translation", "Translations"), ANALYTICS("analytics", "Analytics"), PROFILE("profile", "Profile")
}

// URL syntax and origin validation belong exclusively to the Rust navigation
// contract. This is a typed representation of its normalized result, not a parser.
data class GlossiaDestination(val screen: GlossiaScreen, val server: String,
    val organization: String? = null, val project: String? = null,
    val id: String? = null, val translationId: String? = null) {
    fun json() = JSONObject().put("screen", screen.wire).put("server", server)
        .put("organization", organization ?: JSONObject.NULL).put("project", project ?: JSONObject.NULL)
        .put("id", id ?: JSONObject.NULL).put("translation_id", translationId ?: JSONObject.NULL)

    companion object {
        fun fromCore(value: JSONObject) = GlossiaDestination(
            GlossiaScreen.entries.first { it.wire == value.getString("screen") }, value.getString("server"),
            value.optionalString("organization"), value.optionalString("project"),
            value.optionalString("id"), value.optionalString("translation_id"))
    }
}

internal object GlossiaIntents {
    fun shareTranslation(url: String): Intent = Intent.createChooser(
        Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, url), "Share translation link")

    fun isOAuthCallback(uri: Uri) = uri.scheme == "glossia" && uri.encodedAuthority == "oauth" &&
        uri.encodedPath == "/callback" && uri.fragment == null

    fun consume(intent: Intent, receive: (String) -> Unit, callback: (String) -> Unit) {
        val uri = intent.data ?: return
        intent.data = null // Never replay a consumed intent after Activity recreation.
        if (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0 || intent.action != Intent.ACTION_VIEW) return
        if (isOAuthCallback(uri)) callback(uri.toString()) else receive(uri.toString())
    }
}
