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
import android.widget.ImageButton
import android.widget.FrameLayout
import android.view.MotionEvent
import android.os.Handler
import android.os.Looper
import androidx.appcompat.widget.PopupMenu
import androidx.core.content.ContextCompat
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.google.android.material.card.MaterialCardView
import com.google.android.material.chip.Chip
import com.google.android.material.chip.ChipGroup
import com.google.android.material.textfield.TextInputEditText
import com.google.android.material.textfield.TextInputLayout

internal class TokiView(context: Context, private val model: TokiModel,
    private val draftChanged: (String) -> Unit, send: () -> Unit,
    private val open: (String) -> Unit, private val loadMore: () -> Unit,
    private val refreshHistory: () -> Unit, private val source: (String) -> Unit = {},
    private val retrySource: () -> Unit = {}, private val saveDecision: () -> Unit = {},
    private val voice: TokiVoiceInput? = null, private val startVoice: () -> Unit = {}, private val importText: () -> Unit = {}) : LinearLayout(context) {
    private val body = context.column(20)
    private val scroll = context.scroll(body)
    private val input = TextInputEditText(context).apply {
        inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_MULTI_LINE or InputType.TYPE_TEXT_FLAG_CAP_SENTENCES
        maxLines = if (resources.configuration.fontScale >= 1.3f) 3 else 6; minLines = 1
        hint = context.nativeText("Message Toki…"); background = null
        setPadding(0, context.dp(11), 0, context.dp(11))
        setTextColor(context.token(R.color.glossia_text)); textSize = 15f
        // Private drafts must not enter Android's saved view hierarchy or autofill.
        isSaveEnabled = false
        importantForAutofill = View.IMPORTANT_FOR_AUTOFILL_NO_EXCLUDE_DESCENDANTS
    }
    private val sendButton = icon(R.drawable.ic_composer_send, "Send message").apply { setOnClickListener { if (voice?.busy == true) voice.cancel() else send() } }
    private fun icon(drawable: Int, description: String) = ImageButton(context).apply {
        setImageResource(drawable); contentDescription = context.nativeText(description)
        background = android.graphics.drawable.GradientDrawable().apply { shape = android.graphics.drawable.GradientDrawable.OVAL; setColor(context.token(R.color.glossia_subtle)) }
        imageTintList = ColorStateList.valueOf(context.token(R.color.glossia_text))
        setPadding(context.dp(14), context.dp(14), context.dp(14), context.dp(14))
    }
    private val attachment = icon(R.drawable.ic_composer_attach, "Import text file; images unavailable").apply {
        setOnClickListener {
            PopupMenu(context, this).apply {
                menu.add(context.nativeText("Choose Files")).setOnMenuItemClickListener { importText(); true }
                menu.add(context.nativeText("Photo Library unavailable: this server supports text only")).isEnabled = false
            }.show()
        }
    }
    private val microphone = icon(R.drawable.ic_composer_mic, "Transcribe a voice message").apply {
        setOnClickListener { if (voice?.busy == true) voice.finish() else startVoice() }
    }
    private val voiceMessage = context.label("", 12f, true)
    private val waveform = TokiWaveformView(context).apply { visibility = View.GONE }
    private val waiting = context.label("Waiting for permission…", 14f, true).apply { visibility = View.GONE }
    private val microphoneSlot = View(context)
    private val composerSurface = FrameLayout(context).apply {
        val row = LinearLayout(context).apply {
            gravity = Gravity.BOTTOM; setPadding(context.dp(4), context.dp(4), context.dp(4), context.dp(4))
            fun target(view: View) = addView(view, LayoutParams(context.dp(48), context.dp(48)).apply { marginStart = context.dp(2); marginEnd = context.dp(2) })
            target(attachment)
            addView(FrameLayout(context).apply {
                addView(input, FrameLayout.LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT, Gravity.CENTER_VERTICAL))
                addView(waveform, FrameLayout.LayoutParams(LayoutParams.MATCH_PARENT, context.dp(48)))
                addView(waiting, FrameLayout.LayoutParams(LayoutParams.MATCH_PARENT, context.dp(48)))
            }, LayoutParams(0, LayoutParams.WRAP_CONTENT, 1f))
            target(microphoneSlot); target(sendButton)
        }
        addView(MaterialCardView(context).apply {
            radius = context.dp(28).toFloat(); cardElevation = 0f; strokeWidth = context.dp(1)
            setTag(R.id.appearance_surface, "composer"); setCardBackgroundColor(context.token(R.color.glossia_surface))
            strokeColor = context.token(R.color.glossia_border); addView(row)
        }, FrameLayout.LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT))
        // This target is never reparented during a gesture. Only its gravity
        // changes, mirroring Atlas's stable UIKit recording target for RTL too.
        addView(microphone, FrameLayout.LayoutParams(context.dp(48), context.dp(48), Gravity.BOTTOM or Gravity.END).apply { marginEnd = context.dp(60); bottomMargin = context.dp(4) })
    }
    private val composer = LinearLayout(context).apply {
        orientation = VERTICAL; setPadding(context.dp(16), context.dp(8), context.dp(16), context.dp(10))
        addView(voiceMessage); addView(composerSurface)
    }
    private var binding = false
    private var available = false
    private var signature: String? = null
    private var decisionDraft: ReviewDraft? = null
    private var decisionSheet: TokiDecisionSheet? = null
    private var reviewingDecision = false
    private var contextThreadId: String? = null
    private var goalContextExpanded = false

    init {
        orientation = VERTICAL
        addView(scroll, LayoutParams(LayoutParams.MATCH_PARENT, 0, 1f))
        installMicrophoneGesture()
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
        if (contextThreadId != thread?.id) { contextThreadId = thread?.id; goalContextExpanded = false }
        binding = true
        if (input.text.toString() != (thread?.draft ?: "")) {
            input.setText(thread?.draft ?: ""); input.setSelection(input.length())
        }
        binding = false
        if (thread == null || thread.goalClosed) removeView(composer) else if (composer.parent == null) addView(composer)
        if (decisionDraft !== thread?.decision) {
            decisionSheet?.dismissPreservingDraft(); decisionSheet = null
            decisionDraft = thread?.decision
            reviewingDecision = decisionDraft != null
        }
        body.removeAllViews()
        if (thread == null) renderHistory(canChat) else renderConversation(thread, canChat)
        syncDecisionSheet()
        updateComposer()
        renderVoice()
        val nextSignature = thread?.let { "${it.id}:${it.messages}:${it.pending?.id}:${it.decision != null}" }
        if (thread != null && nextSignature != signature) {
            val nearBottom = scroll.getChildAt(0).height - (scroll.height + scroll.scrollY) < context.dp(100)
            if (thread.decision != null || thread.sharedGoal && signature == null) scroll.post { scroll.fullScroll(ScrollView.FOCUS_UP) }
            else if (signature == null || nearBottom || thread.pending != null) scroll.post { scroll.fullScroll(ScrollView.FOCUS_DOWN) }
        }
        signature = nextSignature
        // Suggestion taps rebuild this body locally, without a session event.
        context.appearance?.paint(this)
    }

    override fun onAttachedToWindow() { super.onAttachedToWindow(); syncDecisionSheet() }

    override fun onDetachedFromWindow() {
        decisionSheet?.dismissPreservingDraft(); decisionSheet = null
        super.onDetachedFromWindow()
    }

    private fun syncDecisionSheet() {
        val thread = model.active ?: return
        if (!isAttachedToWindow || thread.decision == null || !reviewingDecision) return
        if (decisionSheet == null) {
            decisionSheet = TokiDecisionSheet(context, thread, saveDecision, { open(thread.id) }, {
                reviewingDecision = false; decisionSheet = null; render(available)
            }).also { it.show() }
        }
        decisionSheet?.refreshState()
    }

    private fun updateComposer() {
        val thread = model.active
        val draft = input.text.toString()
        val length = draft.codePointCount(0, draft.length)
        val locked = thread?.pending != null
        input.isEnabled = available && !locked && thread?.unavailable != true && thread?.goalClosed != true && thread?.resolving != true && thread?.decision == null && thread?.resolutionNeedsRefresh != true && thread?.inputActive != true
        sendButton.contentDescription = context.nativeText(if (thread?.pending != null && thread.error != null) "Retry message" else "Send message")
        sendButton.isEnabled = available && thread?.unavailable != true && thread?.busy != true && thread?.running != true && thread?.goalClosed != true && thread?.resolving != true && thread?.decision == null && thread?.resolutionNeedsRefresh != true &&
            thread?.inputActive != true && (thread?.pending != null || (draft.isNotBlank() && length <= 4000))
        input.error = if (length > 4000) context.nativeFormat("Use at most 4,000 characters (%1\$s).", length) else null
    }

    fun refreshVoice() { updateComposer(); renderVoice() }

    private fun renderVoice() {
        val recording = voice?.busy == true
        val permitted = input.isEnabled || recording
        val explanation = voice?.error ?: if (voice?.supported != true) context.nativeText("On-device dictation is unavailable on this device. You can still type.").toString() else null
        voiceMessage.text = explanation ?: "" // The controller localizes its own fixed copy.
        voiceMessage.visibility = if (explanation == null) View.GONE else View.VISIBLE
        input.visibility = if (recording) View.INVISIBLE else View.VISIBLE
        waveform.visibility = if (voice?.phase == TokiVoiceInput.Phase.RECORDING) View.VISIBLE else View.GONE
        waveform.levels = voice?.levels?.toList() ?: emptyList()
        waiting.visibility = if (voice?.phase == TokiVoiceInput.Phase.REQUESTING) View.VISIBLE else View.GONE
        attachment.visibility = if (recording) View.INVISIBLE else View.VISIBLE
        attachment.isEnabled = permitted && !recording
        microphoneSlot.visibility = if (recording) View.GONE else View.VISIBLE
        microphone.isEnabled = permitted && voice?.supported == true
        microphone.alpha = if (microphone.isEnabled) 1f else 0.35f
        microphone.setImageResource(if (recording) android.R.drawable.ic_media_pause else R.drawable.ic_composer_mic)
        microphone.contentDescription = context.nativeText(if (recording) "Stop dictation and edit transcript" else "Transcribe a voice message")
        microphone.layoutParams = FrameLayout.LayoutParams(context.dp(48), context.dp(48), Gravity.BOTTOM or if (recording) Gravity.START else Gravity.END).apply {
            marginStart = if (recording) context.dp(6) else 0
            marginEnd = if (recording) 0 else context.dp(60); bottomMargin = context.dp(4)
        }
        sendButton.setImageResource(if (recording) android.R.drawable.ic_menu_close_clear_cancel else R.drawable.ic_composer_send)
        if (recording) { sendButton.contentDescription = context.nativeText("Discard dictation"); sendButton.isEnabled = true }
    }

    @android.annotation.SuppressLint("ClickableViewAccessibility")
    private fun installMicrophoneGesture() {
        val main = Handler(Looper.getMainLooper())
        var holding = false
        val hold = Runnable { holding = true; if (voice?.busy != true) startVoice() }
        microphone.setOnTouchListener { view, event ->
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> { holding = false; view.isPressed = true; main.postDelayed(hold, 500); true }
                MotionEvent.ACTION_UP -> {
                    main.removeCallbacks(hold); view.isPressed = false
                    if (holding) voice?.finish() else view.performClick()
                    holding = false; true
                }
                MotionEvent.ACTION_CANCEL -> { main.removeCallbacks(hold); view.isPressed = false; if (holding) voice?.cancel(); holding = false; true }
                else -> true
            }
        }
    }

    private fun renderConversation(thread: ConversationModel, canChat: Boolean) {
        val messages = thread.messages
        if (thread.sharedGoal) body.addSpaced(TokiGoalView(context, thread, { open(thread.id) }, source, goalContextExpanded) { goalContextExpanded = it })
        thread.translationSessionId?.takeUnless { thread.sharedGoal }?.let { id ->
            body.addSpaced(context.card {
                addSpaced(context.label("SOURCE TRANSLATION", 12f, true), 8)
                val summary = thread.source.data
                addSpaced(context.heading(summary?.optionalString("commit_message") ?: context.nativeText("Translation session").toString(), 18f, verbatim = true), 8)
                summary?.optionalString("summary")?.let { addSpaced(context.label(it, 14f, true, verbatim = true), 8) }
                summary?.optionalString("status")?.let { addSpaced(context.label(translationStatus(it), 13f, true), 4) }
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
                        text = context.nativeText(suggestion); isCheckable = false; isClickable = true
                        chipBackgroundColor = ColorStateList.valueOf(context.token(R.color.glossia_accent_soft))
                        setTextColor(context.token(R.color.glossia_primary))
                        setOnClickListener { draftChanged(context.nativeText(suggestion).toString()); render(true); input.requestFocus() }
                    })
                }
                body.addSpaced(chips)
            }
        }
        val proposal = (0 until messages.length()).firstNotNullOfOrNull { index ->
            messages.getJSONObject(index).takeIf { thread.proposalReplyId != null && it.optionalString("id") == thread.proposalReplyId }
        }?.takeIf { thread.goal?.optString("status") == "open" || thread.decision != null }
        for (index in 0 until messages.length()) {
            val message = messages.getJSONObject(index)
            val role = message.optString("role")
            // The goal question is already the compact header. Replace only the
            // eligible reply with its proposal card, never duplicate its bubble.
            if (index == 0 && thread.sharedGoal && role == "assistant" && message.optString("content") == thread.goal?.optString("question")) continue
            if (proposal?.optionalString("id") == message.optionalString("id") && proposal != null) {
                body.addSpaced(context.card {
                    val continuing = thread.decision != null && thread.resolutionMessageId == message.optionalString("id")
                    addSpaced(context.label("Toki", 12f, true), 4)
                    addSpaced(context.heading("Proposed decision", 18f), 8)
                    addSpaced(context.label(message.optString("content"), 16f, verbatim = true).apply { setTextIsSelectable(true) }, 12)
                    addView(context.button(if (continuing) "Continue reviewing" else "Review decision", true) {
                        thread.beginResolution(); reviewingDecision = true; render(available)
                    }.apply { isEnabled = available && (continuing || thread.decision == null && thread.canResolve) })
                })
                continue
            }
            if (thread.goal?.optString("status") == "answered" && message.optionalString("id") != null && message.optionalString("id") == thread.goal?.optionalString("resolution_message_id")) continue
            val namedHuman = role == "user" && thread.sharedGoal
            bubble(message.optString("content"), role == "user", if (role == "user") {
                if (namedHuman) message.optionalString("author")?.take(100) ?: context.nativeText("Linguist").toString() else "You"
            } else "Toki", verbatimAuthor = namedHuman)
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
        if (thread.goal?.optString("status") == "answered") {
            body.addSpaced(context.resolvedGoalView(thread, source) { open(thread.id) })
        }
        if (thread.decision != null && (proposal == null || thread.resolutionMessageId != proposal.optionalString("id"))) {
            body.addSpaced(context.card {
                addSpaced(context.label("Your unsaved decision draft is retained. Review or explicitly discard it before starting another decision.", muted = true), 8)
                addView(context.button("Continue reviewing") { reviewingDecision = true; syncDecisionSheet() })
            })
        }
        if (thread.goal?.optString("status") == "open" && thread.decision == null) {
            body.addSpaced(ChipGroup(context).apply {
                chipSpacingHorizontal = context.dp(8); chipSpacingVertical = context.dp(8)
                listOf("Compare examples" to "Compare examples for this goal (%1\$s): %2\$s",
                    "Check support tone" to "Check the support tone for this goal (%1\$s): %2\$s").forEach { (title, prompt) ->
                    addView(Chip(context).apply {
                        text = context.nativeText(title); isCheckable = false; isClickable = true
                        isEnabled = available && thread.canStageGoalPrompt
                        setEnsureMinTouchTargetSize(true)
                        setOnClickListener {
                            val goal = thread.goal ?: return@setOnClickListener
                            if (thread.stageGoalPrompt(context.nativeFormat(prompt, "\u2068${goal.optString("locale")}\u2069", "\u2068${goal.optString("question")}\u2069"))) {
                                draftChanged(thread.draft); render(available); input.requestFocus()
                            }
                        }
                    })
                }
            }, 8)
        }
    }

    private fun bubble(content: String, user: Boolean, author: String, verbatimAuthor: Boolean = false) {
        val wrapper = LinearLayout(context).apply { gravity = if (user) Gravity.END else Gravity.START }
        val bubble = MaterialCardView(context).apply {
            radius = context.dp(20).toFloat(); cardElevation = 0f; strokeWidth = if (user) 0 else context.dp(1)
            setTag(R.id.appearance_surface, if (user) "subtle" else "surface")
            strokeColor = context.token(R.color.glossia_border)
            setCardBackgroundColor(context.token(if (user) R.color.glossia_accent_soft else R.color.glossia_surface))
            addView(context.column(16).apply {
                addSpaced(context.label(author, 12f, true, verbatim = verbatimAuthor), 4)
                addView(context.label(content, 15f, verbatim = true).apply { setTextIsSelectable(true) })
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
            historyRow(thread.id, thread.conversation?.optionalString("title") ?: thread.draft.take(80).ifBlank { context.nativeText("New conversation").toString() }, draftDetail(thread)!!)
        }
        model.history.items.forEach { item ->
            historyRow(item.getString("id"), item.optionalString("title") ?: context.nativeText("New conversation").toString(),
                listOfNotNull(draftDetail(model.threads[item.getString("id")]), item.optionalString("status")?.let { context.nativeText(translationStatus(it)) },
                    item.optionalString("updated_at")?.let { context.displayDate(it) }).joinToString(" · "))
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
        thread?.pending != null -> context.nativeText(if (thread.busy) "Sending message…" else "Unconfirmed message · Retry available").toString()
        !thread?.draft.isNullOrEmpty() -> context.nativeText("Draft · Saved on this device").toString()
        else -> null
    }

    private fun historyRow(id: String, title: String, detail: String) {
        body.addSpaced(context.card {
            addSpaced(context.heading(title, 17f, verbatim = true), 4)
            addView(context.label(detail, 12f, true, verbatim = true))
        }.apply {
            isClickable = true; isFocusable = true; contentDescription = context.nativeFormat("%1\$s. %2\$s. Open conversation", title, detail)
            setOnClickListener { open(id) }
        })
    }
}

internal fun Context.displayDate(value: String): String = try {
    java.time.OffsetDateTime.parse(value).toLocalDate().format(java.time.format.DateTimeFormatter.ofLocalizedDate(java.time.format.FormatStyle.MEDIUM).withLocale(nativeLocale))
} catch (_: Exception) { value }
