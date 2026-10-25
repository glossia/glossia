package ai.glossia.mobile

import android.content.Context
import android.text.Editable
import android.text.InputType
import android.text.TextWatcher
import android.view.View
import android.widget.LinearLayout
import com.google.android.material.chip.Chip
import com.google.android.material.chip.ChipGroup
import com.google.android.material.materialswitch.MaterialSwitch
import com.google.android.material.textfield.TextInputEditText
import com.google.android.material.textfield.TextInputLayout

class TokiGoalView(context: Context, thread: ConversationModel, refresh: () -> Unit, source: (String) -> Unit) : LinearLayout(context) {
    init {
        orientation = VERTICAL
        addSpaced(context.heading("Shared linguistic goal", 20f), 8)
        addSpaced(context.label("Visible to project members · one shared conversation.", 12f, true), 8)
        val goal = thread.goal
        if (goal == null) addSpaced(context.label("Goal unavailable. Refresh the conversation to check access."), 8)
        else {
            addSpaced(context.heading(goal.optString("question"), 18f, verbatim = true), 8)
            goal.optJSONArray("participants")?.let { members ->
                if (members.length() > 0) addSpaced(context.label(context.nativeFormat("Participants: %1\$s", (0 until members.length()).joinToString(", ") { members.getJSONObject(it).optString("name", "Linguist") }), 12f, true, verbatim = true), 8)
            }
            addSpaced(context.label("\u2068${goal.optString("locale")}\u2069 · ${context.nativeText(when (goal.optString("status")) { "answered" -> "Goal resolved"; "stale" -> "No longer current"; else -> "Open goal" })}", 13f, true, verbatim = true), 8)
            val excerpts = context.column(0).apply {
                visibility = View.GONE
                listOf("source" to "source_path", "translation" to "output_path").forEach { (kind, path) ->
                    addSpaced(context.label("\u2066${goal.optString(path)}\u2069", 12f, true).apply { textDirection = View.TEXT_DIRECTION_LTR }, 4)
                    addSpaced(context.label(goal.optString("${kind}_excerpt").take(1200), 14f, verbatim = true).apply { setTextIsSelectable(true) }, 8)
                }
            }
            addSpaced(context.button("Source and translation context") { excerpts.visibility = if (excerpts.visibility == View.GONE) View.VISIBLE else View.GONE }, 8)
            addSpaced(excerpts, 8)
            if (goal.optString("status") == "answered") {
                addSpaced(context.heading("Saved decision", 16f), 8)
                addSpaced(context.label(goal.optString("answer"), verbatim = true).apply { setTextIsSelectable(true) }, 8)
                goal.optionalString("guidance")?.let {
                    addSpaced(context.label(context.nativeFormat("Proposed guidance · %1\$s", "\u2066${goal.optionalString("context_path") ?: context.nativeText("Translation PR")}\u2069"), 12f, true), 4)
                    addSpaced(context.label(it, verbatim = true), 8)
                }
                goal.optionalString("resumed_session_id")?.let {
                    addSpaced(context.heading("Translation resumed", 18f), 8)
                    addSpaced(context.button("View resumed translation") { source(it) }, 8)
                } ?: addSpaced(context.label("Refresh to check for the resumed translation.", 12f, true), 8)
            } else if (goal.optString("status") == "stale") addSpaced(context.label("This goal is no longer current. Chat and resolution are read-only."), 8)
            if (thread.goalClosed && thread.draft.isNotEmpty()) {
                addSpaced(context.heading("Unsent message retained on this device", 16f), 8)
                addSpaced(context.label(thread.draft, verbatim = true).apply { setTextIsSelectable(true) }, 8)
                addView(context.button("Discard unsent message") { thread.draft = ""; refresh() })
            }
        }
        addView(context.button("Refresh goal and conversation", action = refresh).apply { isEnabled = !thread.busy && !thread.resolving })
    }
}

class TokiDecisionView(context: Context, private val thread: ConversationModel, save: () -> Unit, refresh: () -> Unit, discard: () -> Unit) : LinearLayout(context) {
    private val state = context.label("", 14f, true)
    private val send = context.button("Save decision and resume", true, save)
    init {
        orientation = VERTICAL
        val draft = requireNotNull(thread.decision)
        addSpaced(context.heading("Resolve goal", 22f), 8)
        addSpaced(context.label("Review this editable proposal from Toki’s latest completed reply. Saving is an explicit decision, not an automatic resolution.", 14f, true), 12)
        fun update() { send.isEnabled = thread.canSaveDecision }
        addSpaced(editor(context, "Decision summary", "goal-decision", draft.answer, !thread.resolving) { draft.answer = it; update() }, 12)
        val guidance = context.column(0).apply {
            visibility = if (draft.reusable) View.VISIBLE else View.GONE
            addSpaced(editor(context, "Independent reusable rule", "goal-guidance", draft.guidance, !thread.resolving) { draft.guidance = it; update() }, 12)
            addSpaced(ChipGroup(context).apply {
                isSingleSelection = true; isSelectionRequired = true
                listOf("locale" to "This locale", "project" to "Whole project").forEach { (scope, title) ->
                    addView(Chip(context).apply {
                        id = View.generateViewId(); text = context.nativeText(title); isCheckable = true; isChecked = draft.scope == scope; isEnabled = !thread.resolving
                        setCheckedIconResource(R.drawable.ic_check); isCheckedIconVisible = true
                        setOnCheckedChangeListener { _, checked -> if (checked) draft.scope = scope }
                    })
                }
            }, 8)
            addView(context.label("Glossia chooses the nearest L10N.md or L10N/<locale>.md path. Guidance becomes a reviewed diff in the normal translation PR, never a direct repository edit.", 12f, true))
        }
        addSpaced(MaterialSwitch(context).apply {
            text = context.nativeText("Propose reusable guidance"); isChecked = draft.reusable; isEnabled = !thread.resolving
            setOnCheckedChangeListener { _, checked -> draft.reusable = checked; guidance.visibility = if (checked) View.VISIBLE else View.GONE; update() }
        }, 12)
        addSpaced(guidance, 12)
        addSpaced(state, 12)
        update(); addSpaced(send, 8)
        addSpaced(context.button("Refresh goal and conversation", action = refresh).apply { isEnabled = !thread.resolving }, 8)
        addView(context.button("Discard decision draft", action = discard).apply { isEnabled = !thread.resolving })
        refreshState()
    }

    // Polling changes eligibility, not the editor instances, selection or frozen
    // reply UUID. Teammates cannot silently replace a proposal being reviewed.
    fun refreshState() {
        fun editable(view: View) {
            if (view is TextInputEditText || view is MaterialSwitch || view is Chip || view is com.google.android.material.button.MaterialButton) view.isEnabled = !thread.resolving
            if (view is android.view.ViewGroup) for (index in 0 until view.childCount) editable(view.getChildAt(index))
        }
        editable(this)
        send.text = context.nativeText(if (thread.resolving) "Saving decision…" else "Save decision and resume")
        send.isEnabled = thread.canSaveDecision
        state.text = thread.resolutionError ?: if (thread.goalClosed) context.nativeText("Goal closed. Your unsaved decision and guidance are retained; copy or explicitly discard them.")
            else if (!thread.canSaveDecision && !thread.resolving) context.nativeText("Refresh if the conversation changed; discard this proposal before resolving a newer reply.") else ""
        state.visibility = if (state.text.isEmpty()) View.GONE else View.VISIBLE
    }

    private fun editor(context: Context, title: String, identity: String, value: String, editable: Boolean, changed: (String) -> Unit): TextInputLayout {
        val field = TextInputLayout(context, null, com.google.android.material.R.attr.textInputOutlinedStyle).apply {
            hint = context.nativeText(title); boxBackgroundMode = TextInputLayout.BOX_BACKGROUND_OUTLINE
            setLengthCounter { text -> if (text == null) 0 else Character.codePointCount(text, 0, text.length) }
            isCounterEnabled = true; counterMaxLength = 8000
        }
        field.addView(TextInputEditText(context).apply {
            tag = identity; inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_MULTI_LINE or InputType.TYPE_TEXT_FLAG_CAP_SENTENCES
            minLines = 2; maxLines = 6; isEnabled = editable; isSaveEnabled = false
            importantForAutofill = View.IMPORTANT_FOR_AUTOFILL_NO_EXCLUDE_DESCENDANTS
            setText(value)
            addTextChangedListener(object : TextWatcher {
                override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) = Unit
                override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) { changed(s.toString()) }
                override fun afterTextChanged(s: Editable?) = Unit
            })
        })
        return field
    }
}
