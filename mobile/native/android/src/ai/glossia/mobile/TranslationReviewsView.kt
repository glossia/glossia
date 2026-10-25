package ai.glossia.mobile

import android.content.Context
import android.widget.LinearLayout

fun translationStatus(status: String) = when (status) {
    "awaiting_input" -> "Awaiting linguistic input"
    "pending" -> "Pending"
    "running" -> "Running"
    "completed" -> "Completed"
    "done" -> "Translated"
    "queued" -> "Queued"
    "skipped" -> "Already up to date"
    "failed" -> "Failed"
    "cancelled" -> "Cancelled"
    else -> "Unknown status"
}

class TranslationReviewsView(context: Context, model: TranslationReviewsModel, refresh: () -> Unit,
    open: (String) -> Unit) : LinearLayout(context) {
    init {
        orientation = VERTICAL
        addSpaced(context.heading("Linguistic goals", 20f), 8)
        if (model.busy) loading("Loading linguistic reviews…")
        failure(model.error, refresh)
        if (model.loaded && model.items.isEmpty() && model.error == null) addSpaced(context.label("No linguistic questions for this translation.", muted = true), 8)
        addSpaced(context.button("Refresh reviews", action = refresh).apply { isEnabled = !model.busy }, 12)
        model.items.forEach { row ->
            addSpaced(context.card {
                addSpaced(context.heading(row.optString("question"), 18f, verbatim = true), 8)
                addSpaced(context.label("\u2068${row.optString("locale")}\u2069 · ${context.nativeText(when (row.optString("status")) { "answered" -> "Goal resolved"; "stale" -> "No longer current"; else -> "Open goal" })}", 14f, true, verbatim = true), 8)
                addSpaced(context.label("\u2066${row.optString("source_path")} → ${row.optString("output_path")}\u2069", 12f, true, verbatim = true), 8)
                val conversation = row.optionalString("conversation_id")
                if (conversation?.matches(Regex("[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}")) == true) {
                    addView(context.button("Open shared Toki conversation") { open(conversation) })
                } else addView(context.label("Shared conversation unavailable. Refresh reviews to retry.", muted = true))
            }, 16)
        }
        addView(context.label("Discuss each goal in its project-shared Toki conversation, then explicitly save the agreed decision to resume affected work in a new translation.", 13f, true))
    }
}
