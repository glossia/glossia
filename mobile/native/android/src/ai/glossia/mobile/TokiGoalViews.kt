package ai.glossia.mobile

import android.content.Context
import android.text.Editable
import android.text.InputType
import android.text.TextWatcher
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.LinearLayout
import androidx.core.view.ViewCompat
import androidx.core.widget.NestedScrollView
import com.google.android.material.bottomsheet.BottomSheetBehavior
import com.google.android.material.bottomsheet.BottomSheetDialog
import com.google.android.material.bottomsheet.BottomSheetDragHandleView
import com.google.android.material.chip.Chip
import com.google.android.material.chip.ChipGroup
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.google.android.material.materialswitch.MaterialSwitch
import com.google.android.material.textfield.TextInputEditText
import com.google.android.material.textfield.TextInputLayout

class TokiGoalView(context: Context, thread: ConversationModel, refresh: () -> Unit, source: (String) -> Unit,
    expanded: Boolean = false, contextChanged: (Boolean) -> Unit = {}) : LinearLayout(context) {
    init {
        orientation = VERTICAL
        val goal = thread.goal
        if (goal == null) addSpaced(context.label("Goal unavailable. Refresh the conversation to check access."), 8)
        else {
            addSpaced(context.heading(goal.optString("question"), 20f, verbatim = true), 4)
            addSpaced(context.label("\u2068${goal.optString("locale")}\u2069 · ${context.nativeText(when (goal.optString("status")) { "answered" -> "Goal resolved"; "stale" -> "No longer current"; else -> "Open goal" })}", 13f, true, verbatim = true), 4)
            goal.optJSONArray("participants")?.let { members ->
                val names = (0 until members.length()).mapNotNull { members.optJSONObject(it)?.optionalString("name") }
                if (names.isNotEmpty()) addSpaced(context.label(context.nativeFormat("Participants: %1\$s", names.joinToString(", ") { "\u2068$it\u2069" }), 12f, true, verbatim = true), 4)
            }
            val excerpts = context.column(0).apply {
                visibility = if (expanded) View.VISIBLE else View.GONE
                addSpaced(context.label("Visible to project members · one shared conversation.", 12f, true), 8)
                listOf("source" to "source_path", "translation" to "output_path").forEach { (kind, path) ->
                    addSpaced(context.label("\u2066${goal.optString(path)}\u2069", 12f, true, verbatim = true).apply { textDirection = View.TEXT_DIRECTION_LTR }, 4)
                    addSpaced(context.label(goal.optString("${kind}_excerpt").take(1200), 14f, verbatim = true).apply { setTextIsSelectable(true) }, 8)
                }
                if (thread.source.busy) loading("Loading source…")
                failure(thread.source.error, refresh)
                goal.optionalString("translation_session_id")?.let { id -> addSpaced(context.button("View source translation") { source(id) }, 4) }
                addView(context.button("Refresh goal and conversation", action = refresh).apply { isEnabled = !thread.busy && !thread.resolving })
            }
            addSpaced(context.button("Source and translation context") {}.apply {
                ViewCompat.setStateDescription(this, context.nativeText(if (expanded) "Expanded" else "Collapsed"))
                setOnClickListener {
                    excerpts.visibility = if (excerpts.visibility == View.GONE) View.VISIBLE else View.GONE
                    contextChanged(excerpts.visibility == View.VISIBLE)
                    ViewCompat.setStateDescription(this, context.nativeText(if (excerpts.visibility == View.VISIBLE) "Expanded" else "Collapsed"))
                }
            }, 0)
            addSpaced(excerpts, 0)
            if (goal.optString("status") == "stale") addSpaced(context.label("This goal is no longer current. Chat and resolution are read-only."), 8)
            if (thread.goalClosed && thread.draft.isNotEmpty()) {
                addSpaced(context.heading("Unsent message retained on this device", 16f), 8)
                addSpaced(context.label(thread.draft, verbatim = true).apply { setTextIsSelectable(true) }, 8)
                addView(context.button("Discard unsent message") { thread.draft = ""; refresh() })
            }
        }
    }
}

internal fun Context.resolvedGoalView(thread: ConversationModel, source: (String) -> Unit, refresh: () -> Unit) = card {
    val goal = requireNotNull(thread.goal)
    addSpaced(context.heading("Approved decision", 18f), 8)
    goal.optJSONObject("answered_by")?.optionalString("name")?.let { name ->
        addSpaced(context.label(context.nativeFormat("Approved by %1\$s", "\u2068$name\u2069"), 13f, true, verbatim = true), 8)
    }
    addSpaced(context.label(goal.optString("answer"), 16f, verbatim = true).apply { setTextIsSelectable(true) }, 12)
    goal.optionalString("guidance")?.let { guidance ->
        addSpaced(context.label("Guidance proposed for PR review", 13f, true), 4)
        goal.optionalString("context_path")?.let { path -> addSpaced(context.label("\u2066$path\u2069", 12f, true, verbatim = true), 4) }
        addSpaced(context.label(guidance, verbatim = true).apply { setTextIsSelectable(true) }, 12)
    }
    goal.optionalString("resumed_session_id")?.let { id ->
        addView(context.button("View resumed translation") { source(id) })
    } ?: run {
        addSpaced(context.label("Refresh to check for the resumed translation.", 12f, true), 4)
        addView(context.button("Refresh goal and conversation", action = refresh).apply { isEnabled = !thread.busy })
    }
}

// The dialog owns its editor hierarchy for the lifetime of the frozen draft.
// Polls update eligibility in place, never focus, selection or field contents.
internal class TokiDecisionSheet(context: Context, private val thread: ConversationModel, save: () -> Unit,
    refresh: () -> Unit, private val closed: () -> Unit) : BottomSheetDialog(context) {
    private var confirming = false
    private val editor = TokiDecisionView(context, thread, save, refresh, ::confirmDiscard)

    init {
        val content = context.column().apply {
            isFocusableInTouchMode = true
            addView(BottomSheetDragHandleView(context), LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, context.dp(48)))
            addSpaced(LinearLayout(context).apply {
                gravity = android.view.Gravity.CENTER_VERTICAL
                setPaddingRelative(context.dp(24), 0, context.dp(16), 0)
                addView(context.heading("Review decision", 22f), LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
                addView(context.button("Close", action = ::cancel))
            }, 16)
            addView(NestedScrollView(context).apply {
                isFillViewport = true
                addView(editor)
            }, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        }
        setContentView(content)
        window?.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE)
        behavior.peekHeight = context.resources.displayMetrics.heightPixels / 2
        behavior.maxHeight = context.resources.displayMetrics.heightPixels - context.dp(24)
        setOnShowListener {
            ViewCompat.setAccessibilityPaneTitle(content, context.nativeText("Review decision"))
            content.requestFocus()
            context.appearance?.paint(content, dialog = true)
        }
        fun expandOnFocus(view: View) {
            if (view is TextInputEditText) view.setOnFocusChangeListener { _, focused ->
                if (focused) behavior.state = BottomSheetBehavior.STATE_EXPANDED
            }
            if (view is ViewGroup) for (index in 0 until view.childCount) expandOnFocus(view.getChildAt(index))
        }
        expandOnFocus(editor)
    }

    fun refreshState() = editor.refreshState()

    // Native back, scrim, swipe and Close return to chat, not approval or discard.
    override fun cancel() {
        dismissPreservingDraft()
        closed()
    }

    private fun confirmDiscard() {
        if (thread.resolving || confirming) return
        confirming = true
        MaterialAlertDialogBuilder(context)
            .setTitle(context.nativeText("Discard decision draft?"))
            .setMessage(context.nativeText("Your decision and optional guidance have not been saved."))
            .setNegativeButton(context.nativeText("Keep editing"), null)
            .setPositiveButton(context.nativeText("Discard decision draft")) { _, _ ->
                thread.discardDecision()
                dismissPreservingDraft()
                closed()
            }
            .setOnDismissListener { confirming = false }
            .show()
    }

    // View detach/navigation and successful saves are not user discards. Drafts
    // stay in the session and are reopened when this conversation is attached.
    fun dismissPreservingDraft() { super.dismiss() }
}

class TokiDecisionView(context: Context, private val thread: ConversationModel, save: () -> Unit, refresh: () -> Unit,
    discard: () -> Unit) : LinearLayout(context) {
    private val state = context.label("", 14f, true)
    private val send = context.button("Save decision and resume", true, save)
    init {
        orientation = VERTICAL
        setPadding(context.dp(24), 0, context.dp(24), context.dp(24))
        val draft = requireNotNull(thread.decision)
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
        addSpaced(context.button("Discard decision draft", action = discard).apply { isEnabled = !thread.resolving }, 8)
        addView(context.label("Your approval resolves this question. Guidance is only proposed in the translation PR for review.", 12f, true))
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
        state.accessibilityLiveRegion = View.ACCESSIBILITY_LIVE_REGION_POLITE
        state.visibility = if (state.text.isEmpty()) View.GONE else View.VISIBLE
    }

    private fun editor(context: Context, title: String, identity: String, value: String, editable: Boolean, changed: (String) -> Unit): TextInputLayout {
        val field = TextInputLayout(context, null, com.google.android.material.R.attr.textInputOutlinedStyle).apply {
            hint = context.nativeText(title); boxBackgroundMode = TextInputLayout.BOX_BACKGROUND_OUTLINE
            setLengthCounter { text -> if (text == null) 0 else Character.codePointCount(text, 0, text.length) }
            isCounterEnabled = true; counterMaxLength = 8000
        }
        field.addView(TextInputEditText(field.context).apply {
            // Let TextInputLayout supply the outlined Material box rather than
            // retaining the Activity's default underlined EditText background.
            background = null
            tag = identity; inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_MULTI_LINE or InputType.TYPE_TEXT_FLAG_CAP_SENTENCES
            minLines = 2; maxLines = 6; isEnabled = editable; isSaveEnabled = false
            importantForAutofill = View.IMPORTANT_FOR_AUTOFILL_NO_EXCLUDE_DESCENDANTS
            textDirection = View.TEXT_DIRECTION_FIRST_STRONG
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
