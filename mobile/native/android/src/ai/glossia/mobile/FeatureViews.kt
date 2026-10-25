package ai.glossia.mobile

import android.content.Context
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import com.google.android.material.button.MaterialButtonToggleGroup
import com.google.android.material.chip.Chip
import com.google.android.material.progressindicator.LinearProgressIndicator
import org.json.JSONArray
import org.json.JSONObject
import java.text.NumberFormat

class FeatureViews(private val context: Context) {
    fun translations(model: PageModel, ready: Boolean, refresh: () -> Unit, more: () -> Unit, open: (String) -> Unit = {}): View {
        val body = context.column(20)
        body.addSpaced(context.heading("Every word, in motion"), 8)
        body.addSpaced(context.label("Translation activity for your project.", 15f, true), 24)
        if (!ready) body.addSpaced(empty(R.drawable.toki_languages, "Choose a project", "Use the workspace selector above to see its translations."))
        else {
            if (model.loaded && model.items.isEmpty()) body.addSpaced(empty(R.drawable.toki_languages, "Ready for your first words", "Translation sessions will appear here when your project starts translating."))
            model.items.forEach { item ->
                body.addSpaced(context.card {
                    addSpaced(context.heading(item.optionalString("commit_message") ?: context.nativeText("Translation session").toString(), 18f, verbatim = true), 8)
                    addSpaced(Chip(context).apply {
                        text = context.nativeText(translationStatus(item.optString("status", "Unknown")))
                        isCheckable = false; isClickable = false
                    }, 8)
                    val targets = item.optJSONArray("target_languages") ?: JSONArray()
                    val languages = (0 until targets.length()).joinToString(", ") { targets.optString(it) }
                    addSpaced(context.label("\u2068${item.optionalString("source_language") ?: context.nativeText("Source")}\u2069 → \u2068${languages.ifEmpty { context.nativeText("No target languages").toString() }}\u2069", 14f, true, verbatim = true), 8)
                    addSpaced(context.label(context.nativeFormat("Translated items: %1\$s", number(item, "translated_content_count")), 14f), 8)
                    item.optionalString("summary")?.let { addSpaced(context.label(it, 14f, true, verbatim = true), 8) }
                    item.optionalString("inserted_at")?.let { addView(context.label(displayDate(it), 12f, true)) }
                    item.optionalString("id")?.let { id -> addView(context.button("View translation") { open(id) }) }
                })
            }
            if (model.busy) body.loading("Loading translations…")
            body.failure(model.error) { if (model.requestedPage == 1) refresh() else more() }
            if (model.hasMore) body.addSpaced(context.button("Load more", action = more).apply { isEnabled = !model.busy })
            body.addSpaced(context.button("Refresh translations", action = refresh).apply { isEnabled = !model.busy })
        }
        return context.scroll(body)
    }

    fun translation(model: TranslationModel, retry: () -> Unit, back: () -> Unit, discuss: () -> Unit, share: () -> Unit = {},
        refreshReviews: () -> Unit = {}, openReview: (String) -> Unit = {}): View {
        val body = context.column(20)
        body.addSpaced(context.button("Back to translations", action = back), 8)
        body.addSpaced(context.heading("Translation detail"), 16)
        if (model.busy) body.loading("Loading translation…")
        body.failure(model.error, retry)
        if (model.data != null) {
            val answered = model.reviews.loaded && model.reviews.items.any { it.optString("status") == "answered" } &&
                model.reviews.items.none { it.optString("status") == "open" }
            val status = if (model.data?.optString("status") == "awaiting_input" && answered) "Linguistic input answered" else translationStatus(model.data?.optString("status") ?: "Unknown")
            body.addSpaced(context.label(status, 16f), 12)
            body.addSpaced(TranslationReviewsView(context, model.reviews, refreshReviews, openReview))
        }
        if (model.data != null || model.liveState in listOf("connecting", "reconnecting")) {
            body.addSpaced(translationProgress(model))
        }
        model.data?.let { item ->
            body.addSpaced(context.card {
                addSpaced(context.heading(item.optionalString("commit_message") ?: context.nativeText("Translation session").toString(), 20f, verbatim = true), 12)
                addSpaced(Chip(context).apply {
                    text = context.nativeText(if (item.optString("status") == "awaiting_input" && model.reviews.loaded &&
                        model.reviews.items.any { it.optString("status") == "answered" } && model.reviews.items.none { it.optString("status") == "open" })
                        "Linguistic input answered" else translationStatus(item.optString("status", "Unknown")))
                    isClickable = false; isCheckable = false
                }, 16)
                detail("Summary", item.optionalString("summary") ?: context.nativeText("No summary is available for this translation.").toString())
                val targets = item.optJSONArray("target_languages") ?: JSONArray()
                detail("Languages", "\u2068${item.optionalString("source_language") ?: context.nativeText("Source")}\u2069 → \u2068" +
                    (0 until targets.length()).joinToString(", ") { targets.optString(it) }.ifEmpty { context.nativeText("No target languages").toString() } + "\u2069")
                detail("Translated items", number(item, "translated_content_count"))
                item.optionalString("inserted_at")?.let { detail("Started", displayDate(it)) }
            })
            body.addSpaced(context.button("Discuss with Toki", true, discuss).apply { isEnabled = !model.busy && model.error == null })
            body.addSpaced(context.button("Share translation link", action = share).apply { isEnabled = !model.busy && model.error == null })
            body.addSpaced(context.label("Start a conversation about this translation. Nothing is sent until you choose Send.", 14f, true))
        }
        return context.scroll(body)
    }

    private fun translationProgress(model: TranslationModel) = context.card {
        val progress = model.progress
        val summary = progress?.optJSONObject("summary")
        val status = model.data?.optionalString("status")
        val terminal = status in listOf("completed", "failed", "cancelled")
        val assessed = summary?.optBoolean("assessed?", summary.optBoolean("assessed")) == true
        val total = summary?.takeIf { it.has("needs_translation") && !it.isNull("needs_translation") }?.optLong("needs_translation")
        val done = summary?.takeIf { it.has("done") && !it.isNull("done") }?.optLong("done")
        addSpaced(context.heading("Translation progress", 18f), 8)
        if (!terminal && status != "awaiting_input") {
            addSpaced(context.label(when (model.liveState) {
                "live" -> "Live updates"
                "connecting" -> "Connecting to live updates…"
                "reconnecting" -> "Reconnecting… Showing the latest available progress."
                "unavailable" -> "Live updates unavailable"
                else -> "Live updates paused"
            }, 13f, true).apply { accessibilityLiveRegion = View.ACCESSIBILITY_LIVE_REGION_POLITE }, 12)
        }
        addSpaced(context.label(when {
            status == "awaiting_input" -> if (model.reviews.loaded && model.reviews.items.none { it.optString("status") == "open" } && model.reviews.items.any { it.optString("status") == "answered" }) "Historical run · linguistic input answered" else "Waiting for linguistic input"
            terminal -> translationStatus(status!!)
            !assessed -> "Planning translations…"
            total == 0L -> "No translation work required"
            else -> "Translating files"
        }, 16f), 8)
        if (assessed && total != null && total > 0 && done != null) {
            val title = context.nativeFormat("%1\$s / %2\$s translated", number(summary!!, "done"), number(summary, "needs_translation"))
            addSpaced(context.label(title, 20f), 12)
            addSpaced(LinearProgressIndicator(context).apply {
                isIndeterminate = false; max = 1000
                setProgressCompat(((done.toDouble() / total) * max).toInt().coerceIn(0, max), false)
                contentDescription = title
                themed { setIndicatorColor(context.token(R.color.glossia_primary)); trackColor = context.token(R.color.glossia_border) }
            }, 16)
        } else if (!terminal && status != "awaiting_input" && !(assessed && total == 0L)) {
            addSpaced(LinearProgressIndicator(context).apply {
                isIndeterminate = true
                contentDescription = context.nativeText("Planning translations; progress is not yet known")
                themed { setIndicatorColor(context.token(R.color.glossia_primary)); trackColor = context.token(R.color.glossia_border) }
            }, 16)
        }
        if (summary != null) {
            val counts = listOf("checked" to "checked", "total" to "planned", "skipped" to "up to date",
                "running" to "running", "queued" to "queued", "awaiting_input" to "awaiting linguistic input", "failed" to "failed", "cancelled" to "cancelled")
                .filter { summary.has(it.first) && !summary.isNull(it.first) }
                .joinToString(" · ") { context.nativeFormat("%1\$s %2\$s", number(summary, it.first), context.nativeText(it.second)) }
            if (counts.isNotEmpty()) addSpaced(context.label(counts, 13f, true, verbatim = true), 16)
        }
        val items = progress?.optJSONArray("items")
        if (items != null && items.length() > 0) {
            addSpaced(context.heading("Files", 16f), 12)
            for (index in 0 until items.length()) {
                val item = items.getJSONObject(index)
                addSpaced(context.label("\u2066${item.optionalString("output_path") ?: context.nativeText("Path not available")}\u2069", 14f, verbatim = true).apply {
                    setTextIsSelectable(true)
                }, 4)
                addSpaced(context.label(listOfNotNull(item.optionalString("locale")?.let { "\u2068$it\u2069" }, item.optionalString("status")?.let { context.nativeText(translationStatus(it)) })
                    .joinToString(" · ").ifEmpty { context.nativeText("Status not available").toString() }, 13f, true, verbatim = true), 12)
            }
        } else addView(context.label(if (terminal) "No file details are available." else "File progress will appear as the plan is prepared.", 13f, true))
    }

    fun analytics(model: AnalyticsModel, ready: Boolean, daysChanged: (Int) -> Unit, retry: () -> Unit): View {
        val body = context.column(20)
        body.addSpaced(context.heading("A world of understanding"), 8)
        body.addSpaced(context.label("See who you reach, and who’s still waiting.", 15f, true), 20)
        val filter = MaterialButtonToggleGroup(context).apply { isSingleSelection = true; isSelectionRequired = true }
        val dayIds = mutableMapOf<Int, Int>()
        listOf(7, 30, 90).forEach { days ->
            val button = context.button(context.nativeFormat("%1\$s days", days)) {}.apply {
                id = View.generateViewId(); isCheckable = true
                dayIds[id] = days
            }
            filter.addView(button, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
            if (model.days == days) filter.check(button.id)
        }
        filter.addOnButtonCheckedListener { _, id, checked -> if (checked) dayIds[id]?.let(daysChanged) }
        body.addSpaced(filter, 24)
        if (!ready) body.addSpaced(empty(R.drawable.toki_globe, "Choose a project", "Select a project above to explore its audience."))
        else {
            val data = model.data
            if (data != null) {
                val summary = data.optJSONObject("summary") ?: JSONObject()
                val row = LinearLayout(context)
                row.addView(metric("Pageviews", number(summary, "pageviews")), LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f).apply { marginEnd = context.dp(12) })
                row.addView(metric("Unique visitors", number(summary, "unique_visitors")), LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
                body.addSpaced(row)
                body.addSpaced(context.card {
                    addSpaced(context.label("Locale gap visits", 14f, true), 4)
                    addSpaced(context.heading(number(summary, "locale_gap_visits"), 28f), 8)
                    addView(context.label("Visits in a language your project doesn’t offer yet.", 13f, true))
                })
                body.addSpaced(context.card {
                    addSpaced(context.heading("Your audience", 18f), 16)
                    detail("Top country", summary.optionalString("top_country") ?: context.nativeText("No data yet").toString())
                    detail("Top browser language", summary.optionalString("top_browser_language") ?: context.nativeText("No data yet").toString())
                })
                val pages = data.optJSONArray("top_pages") ?: JSONArray()
                body.addSpaced(context.card {
                    addSpaced(context.heading("Top pages", 18f), 16)
                    if (pages.length() == 0) {
                        addView(context.label("No pageviews in this period. Data will appear after your tracker receives visits.", muted = true))
                    } else for (index in 0 until pages.length()) {
                        val page = pages.getJSONObject(index)
                        detail(page.optString("pathname", "/"), context.nativeFormat("%1\$s views", number(page, "pageviews")), titleVerbatim = true)
                    }
                })
            }
            if (model.busy) body.loading("Loading audience insights…")
            body.failure(model.error, retry)
            body.addSpaced(context.button("Refresh analytics", action = retry).apply { isEnabled = !model.busy })
        }
        return context.scroll(body)
    }

    fun profile(model: FeatureModel, server: String?, organization: String?, project: String?, retry: () -> Unit, signOut: () -> Unit,
        push: GlossiaPushNotifications? = null, languages: FluentLanguagesModel? = null,
        editLanguages: () -> Unit = {}, saveLanguages: () -> Unit = {}, discardLanguages: () -> Unit = {}): View {
        if (languages?.draft != null) return context.scroll(context.column().apply {
            addView(context.fluentLanguagesView(languages, saveLanguages, discardLanguages))
        })
        val body = context.column(20)
        val user = model.data?.optJSONObject("user")
        body.addView(context.mascot(R.drawable.toki_delighted, 112))
        body.addSpaced(context.heading(user?.optionalString("name") ?: context.nativeText("Your profile").toString(), verbatim = true).apply { gravity = Gravity.CENTER }, 8)
        user?.optionalString("email")?.let { body.addSpaced(context.label(it, 15f, true, verbatim = true).apply { gravity = Gravity.CENTER }, 24) }
        if (model.busy) body.loading("Loading profile…")
        body.failure(model.error, retry)
        if (push != null) body.addSpaced(context.pushSettings(push))
        body.addSpaced(context.card {
            addSpaced(context.heading("Fluent languages", 18f), 8)
            val tags = user?.optJSONArray("fluent_languages")
            addSpaced(context.label(if (tags == null || tags.length() == 0) "No fluent languages selected" else
                (0 until tags.length()).joinToString(", ") { tags.getString(it) }, muted = true), 8)
            addView(context.button("Edit fluent languages", action = editLanguages).apply { isEnabled = model.loaded && !model.busy })
        })
        body.addSpaced(context.card {
            addSpaced(context.heading("Account", 18f), 16)
            detail("Name", user?.optionalString("name") ?: context.nativeText("Not available").toString())
            detail("Email", user?.optionalString("email") ?: context.nativeText("Not available").toString())
            detail("Handle", user?.optionalString("handle") ?: context.nativeText("Not available").toString())
            user?.optionalString("id")?.let { detail("Account ID", it) }
        })
        body.addSpaced(context.card {
            addSpaced(context.heading("Workspace", 18f), 16)
            detail("Organization", organization ?: context.nativeText("None selected").toString())
            detail("Project", project ?: context.nativeText("None selected").toString())
            detail("Server", server ?: context.nativeText("Not connected").toString())
            detail("Server version", model.data?.optionalString("server_version") ?: context.nativeText("Not available").toString())
            val version = context.packageManager.getPackageInfo(context.packageName, 0).versionName ?: "Unknown"
            detail("Glossia for Android", version)
        })
        body.addSpaced(context.card {
            addSpaced(context.heading("Private by design", 18f), 8)
            addView(context.label("Your credentials are encrypted with Android Keystore. Signing out clears your workspace, conversations and drafts from this app.", muted = true))
        })
        body.addSpaced(context.button("Refresh profile", action = retry).apply { isEnabled = !model.busy })
        body.addSpaced(context.button("Sign out", action = signOut).apply {
            themed { setTextColor(GlossiaAppearance.states(readableErrorColor())) }
        })
        return context.scroll(body)
    }

    private fun empty(image: Int, title: String, subtitle: String) = context.card {
        addView(context.mascot(image, 144))
        addSpaced(context.heading(title, 20f).apply { gravity = Gravity.CENTER }, 8)
        addView(context.label(subtitle, 14f, true).apply { gravity = Gravity.CENTER })
    }

    private fun metric(title: String, value: String) = context.card {
        addSpaced(context.label(title, 13f, true), 8)
        addView(context.heading(value, 28f))
    }

    private fun LinearLayout.detail(title: String, value: String, titleVerbatim: Boolean = false) {
        addSpaced(context.label(title, 12f, true, verbatim = titleVerbatim), 2)
        addSpaced(context.label(value, 15f, verbatim = true).apply { setTextIsSelectable(true) }, 16)
    }

    private fun number(value: JSONObject, key: String): String = if (!value.has(key) || value.isNull(key)) "—"
        else NumberFormat.getIntegerInstance().format(value.optLong(key))
}
