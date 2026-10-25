package ai.glossia.mobile

import android.content.Context
import android.content.res.ColorStateList
import android.text.Editable
import android.text.InputType
import android.text.TextWatcher
import android.view.Gravity
import android.view.View
import android.widget.LinearLayout
import android.widget.ScrollView
import com.google.android.material.card.MaterialCardView
import com.google.android.material.chip.Chip
import com.google.android.material.chip.ChipGroup
import com.google.android.material.textfield.TextInputEditText
import com.google.android.material.textfield.TextInputLayout

class TokiView(context: Context, private val model: TokiModel,
    private val draftChanged: (String) -> Unit, send: () -> Unit,
    private val open: (String) -> Unit, private val loadMore: () -> Unit,
    private val refreshHistory: () -> Unit, private val source: (String) -> Unit = {},
    private val retrySource: () -> Unit = {}) : LinearLayout(context) {
    private val body = context.column(20)
    private val scroll = context.scroll(body)
    private val input = TextInputEditText(context).apply {
        inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_MULTI_LINE or InputType.TYPE_TEXT_FLAG_CAP_SENTENCES
        maxLines = 4; minLines = 1
        setTextColor(context.token(R.color.glossia_text)); textSize = 15f
        // Private drafts must not enter Android's saved view hierarchy or autofill.
        isSaveEnabled = false
        importantForAutofill = View.IMPORTANT_FOR_AUTOFILL_NO_EXCLUDE_DESCENDANTS
    }
    private val field = TextInputLayout(context, null, com.google.android.material.R.attr.textInputOutlinedStyle).apply {
        hint = "Message Toki"; boxBackgroundMode = TextInputLayout.BOX_BACKGROUND_OUTLINE
        setBoxCornerRadii(context.dp(20).toFloat(), context.dp(20).toFloat(), context.dp(20).toFloat(), context.dp(20).toFloat())
        addView(input)
    }
    private val sendButton = context.button("Send", true, send)
    private val composer = LinearLayout(context).apply {
        gravity = Gravity.BOTTOM
        setPadding(context.dp(16), context.dp(8), context.dp(16), context.dp(12))
        addView(field, LayoutParams(0, LayoutParams.WRAP_CONTENT, 1f))
        addView(sendButton, LayoutParams(LayoutParams.WRAP_CONTENT, context.dp(56)).apply { marginStart = context.dp(8) })
    }
    private var binding = false
    private var available = false
    private var signature: String? = null

    init {
        orientation = VERTICAL
        addView(scroll, LayoutParams(LayoutParams.MATCH_PARENT, 0, 1f))
        input.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) = Unit
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {
                if (!binding) { draftChanged(s.toString()); updateComposer() }
            }
            override fun afterTextChanged(s: Editable?) = Unit
        })
    }

    fun render(canChat: Boolean) {
        available = canChat
        val thread = model.active
        binding = true
        if (input.text.toString() != (thread?.draft ?: "")) {
            input.setText(thread?.draft ?: ""); input.setSelection(input.length())
        }
        binding = false
        if (thread == null) removeView(composer) else if (composer.parent == null) addView(composer)
        body.removeAllViews()
        if (thread == null) renderHistory(canChat) else renderConversation(thread, canChat)
        updateComposer()
        val nextSignature = thread?.let { "${it.id}:${it.messages}:${it.pending?.id}" }
        if (thread != null && nextSignature != signature) {
            val nearBottom = scroll.getChildAt(0).height - (scroll.height + scroll.scrollY) < context.dp(100)
            if (signature == null || nearBottom || thread.pending != null) scroll.post { scroll.fullScroll(ScrollView.FOCUS_DOWN) }
        }
        signature = nextSignature
        // Suggestion taps rebuild this body locally, without a session event.
        context.appearance?.paint(this)
    }

    private fun updateComposer() {
        val thread = model.active
        val draft = input.text.toString()
        val length = draft.codePointCount(0, draft.length)
        val locked = thread?.pending != null
        input.isEnabled = available && !locked && thread?.unavailable != true
        sendButton.text = if (thread?.pending != null && thread.error != null) "Retry" else "Send"
        sendButton.isEnabled = available && thread?.unavailable != true && thread?.busy != true && thread?.running != true &&
            (thread?.pending != null || (draft.isNotBlank() && length <= 4000))
        field.error = if (length > 4000) "Use at most 4,000 characters ($length)." else null
    }

    private fun renderConversation(thread: ConversationModel, canChat: Boolean) {
        val messages = thread.messages
        thread.translationSessionId?.let { id ->
            body.addSpaced(context.card {
                addSpaced(context.label("SOURCE TRANSLATION", 12f, true), 8)
                val summary = thread.source.data
                addSpaced(context.heading(summary?.optionalString("commit_message") ?: "Translation session", 18f), 8)
                summary?.optionalString("summary")?.let { addSpaced(context.label(it, 14f, true), 8) }
                summary?.optionalString("status")?.let { addSpaced(context.label(it.replaceFirstChar { c -> c.uppercase() }, 13f, true), 4) }
                if (thread.source.busy) loading("Loading source…")
                failure(thread.source.error, retrySource)
                addView(context.button("View source translation") { source(id) })
            })
        }
        if (!thread.created && messages.length() == 0 && thread.pending == null && thread.busy != true &&
            thread.error == null && !thread.unavailable && thread.status != "failed") {
            body.addView(TokiCompanionView(context).apply {
                layoutParams = LayoutParams(context.dp(192), context.dp(192)).apply { gravity = Gravity.CENTER_HORIZONTAL }
            })
            body.addSpaced(context.label("Tap Toki to say hello", 12f, true).apply { gravity = Gravity.CENTER }, 8)
            body.addSpaced(context.heading("Hi, I’m Toki").apply { gravity = Gravity.CENTER }, 8)
            body.addSpaced(context.label(if (thread.translationSessionId != null) "What would you like to discuss about this translation?\nNothing is sent until you choose Send."
                else if (canChat) "Your companion for every language.\nWhat shall we work on together?"
                else "Choose an organization and project above\nto start a conversation.", 15f, true).apply { gravity = Gravity.CENTER }, 24)
            if (canChat) {
                val chips = ChipGroup(context).apply { isSingleLine = false; chipSpacingHorizontal = context.dp(8); chipSpacingVertical = context.dp(8) }
                listOf("Help me get started", "Review my translations", "Understand my audience").forEach { suggestion ->
                    chips.addView(Chip(context).apply {
                        text = suggestion; isCheckable = false; isClickable = true
                        chipBackgroundColor = ColorStateList.valueOf(context.token(R.color.glossia_accent_soft))
                        setTextColor(context.token(R.color.glossia_primary))
                        setOnClickListener { draftChanged(suggestion); render(true); input.requestFocus() }
                    })
                }
                body.addSpaced(chips)
            }
        }
        for (index in 0 until messages.length()) {
            val message = messages.getJSONObject(index)
            val role = message.optString("role")
            bubble(message.optString("content"), role == "user", if (role == "user") "You" else "Toki")
        }
        thread.pending?.let { pending ->
            val exists = (0 until messages.length()).any { messages.getJSONObject(it).optString("id") == pending.id }
            if (!exists) bubble(pending.content, true, if (thread.error == null) "You · Sending…" else "You · Not confirmed")
        }
        if (thread.error == null && (thread.busy || thread.running)) {
            val status = if (thread.pending != null) "Sending your message…" else if (thread.running) "Toki is thinking…" else "Loading conversation…"
            if (thread.running) body.addView(context.mascot(R.drawable.toki_focused, 72))
            body.loading(status)
        }
        if (thread.status == "failed" && thread.pending == null) {
            body.addSpaced(context.card {
                addView(context.mascot(R.drawable.toki_curious, 112))
                addSpaced(context.heading("Toki couldn’t finish", 18f), 8)
                addSpaced(context.label("The latest reply didn’t complete. Refresh the status or send a new message.", muted = true), 0)
                addView(context.button("Refresh status") { open(thread.id) })
            })
        }
        thread.error?.let { failure ->
            body.failure(failure) { if (thread.pending != null) sendButton.performClick() else open(thread.id) }
        }
    }

    private fun bubble(content: String, user: Boolean, author: String) {
        val wrapper = LinearLayout(context).apply { gravity = if (user) Gravity.END else Gravity.START }
        val bubble = MaterialCardView(context).apply {
            radius = context.dp(20).toFloat(); cardElevation = 0f; strokeWidth = if (user) 0 else context.dp(1)
            setTag(R.id.appearance_surface, if (user) "subtle" else "surface")
            strokeColor = context.token(R.color.glossia_border)
            setCardBackgroundColor(context.token(if (user) R.color.glossia_accent_soft else R.color.glossia_surface))
            addView(context.column(16).apply {
                addSpaced(context.label(author, 12f, true), 4)
                addView(context.label(content, 15f).apply { setTextIsSelectable(true) })
            })
        }
        wrapper.addView(bubble, LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT).apply {
            if (user) marginStart = context.dp(32) else marginEnd = context.dp(32)
        })
        body.addSpaced(wrapper, 16)
    }

    private fun renderHistory(canChat: Boolean) {
        body.addSpaced(context.heading("Your conversations"), 8)
        body.addSpaced(context.label(if (canChat) "Pick up where you left off, or use Compose in the toolbar to start something new."
            else "Choose an organization and project above to see your conversations and start a new one.", muted = true), 20)
        if (!canChat) return
        val savedIds = model.history.items.map { it.optString("id") }.toSet()
        val drafts = model.threads.values.filter { !it.unavailable && it.id !in savedIds && (it.draft.isNotEmpty() || it.pending != null) }
        drafts.forEach { thread ->
            historyRow(thread.id, thread.conversation?.optionalString("title") ?: thread.draft.take(80).ifBlank { "New conversation" }, draftDetail(thread)!!)
        }
        model.history.items.forEach { item ->
            historyRow(item.getString("id"), item.optionalString("title") ?: "New conversation",
                listOfNotNull(draftDetail(model.threads[item.getString("id")]), item.optionalString("status"),
                    item.optionalString("updated_at")?.let(::displayDate)).joinToString(" · "))
        }
        if (model.history.busy) body.loading("Loading conversations…")
        if (model.history.loaded && model.history.items.isEmpty() && drafts.isEmpty()) {
            body.addSpaced(context.heading("No conversations yet", 20f), 8)
            body.addSpaced(context.label("Choose Compose in the toolbar to start a conversation with Toki. Nothing is sent until you choose Send.", muted = true))
        }
        body.failure(model.history.error, if (model.history.requestedPage == 1) refreshHistory else loadMore)
        if (model.history.hasMore) body.addSpaced(context.button("Load more", action = loadMore).apply { isEnabled = !model.history.busy })
    }

    private fun draftDetail(thread: ConversationModel?): String? = when {
        thread?.pending != null -> if (thread.busy) "Sending message…" else "Unconfirmed message · Retry available"
        !thread?.draft.isNullOrEmpty() -> "Draft · Saved on this device"
        else -> null
    }

    private fun historyRow(id: String, title: String, detail: String) {
        body.addSpaced(context.card {
            addSpaced(context.heading(title, 17f), 4)
            addView(context.label(detail, 12f, true))
        }.apply {
            isClickable = true; isFocusable = true; contentDescription = "$title. $detail. Open conversation"
            setOnClickListener { open(id) }
        })
    }
}

internal fun displayDate(value: String): String = try {
    java.time.OffsetDateTime.parse(value).toLocalDate().format(java.time.format.DateTimeFormatter.ofLocalizedDate(java.time.format.FormatStyle.MEDIUM))
} catch (_: Exception) { value }
