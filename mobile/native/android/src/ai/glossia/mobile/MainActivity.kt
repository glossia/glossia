package ai.glossia.mobile

import android.Manifest
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.inputmethod.InputMethodManager
import android.widget.FrameLayout
import android.widget.LinearLayout
import androidx.activity.OnBackPressedCallback
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import com.google.android.material.appbar.MaterialToolbar
import com.google.android.material.bottomnavigation.BottomNavigationView
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.google.android.material.textfield.TextInputEditText

class MainActivity : AppCompatActivity(), AppearanceOwner {
    private val session get() = (application as GlossiaApplication).session
    override val appearance get() = session.appearance
    private lateinit var toolbar: MaterialToolbar
    private lateinit var navigation: BottomNavigationView
    private lateinit var screen: FrameLayout
    private lateinit var toki: TokiView
    private lateinit var login: GlossiaLoginView
    private lateinit var features: FeatureViews
    private lateinit var workspaceError: LinearLayout
    private lateinit var navigationNotice: LinearLayout
    private var workspaceDialog: AlertDialog? = null
    private var workspacePickerView: WorkspacePickerView? = null
    private var bindingNavigation = false
    private var keyboardVisible = false
    private var voiceThread: ConversationModel? = null
    private var voiceWorkspace: String? = null
    private var permissionTicket = 0
    private lateinit var voice: TokiVoiceInput
    private val microphonePermission = registerForActivityResult(ActivityResultContracts.RequestPermission()) {
        if (voiceWorkspace == inputWorkspace()) voice.permissionResult(permissionTicket, it) else voice.cancel()
    }
    private var importingThread: ConversationModel? = null
    private var importingWorkspace: String? = null
    private var importRevision = 0
    private val textImports = java.util.concurrent.Executors.newSingleThreadExecutor()
    private val textFile = registerForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        val thread = importingThread; val workspace = importingWorkspace; val ticket = importRevision
        if (thread == null) return@registerForActivityResult
        if (uri == null || workspace != inputWorkspace()) { thread.inputActive = false; importingThread = null; importingWorkspace = null; render(); return@registerForActivityResult }
        textImports.execute {
            val result = runCatching {
                require(contentResolver.getType(uri)?.startsWith("image/") != true) { nativeText("Image uploads are unavailable. Choose a UTF-8 text file instead.").toString() }
                contentResolver.openInputStream(uri)?.use { stream ->
                    val buffer = ByteArray(TokiTextImport.MAX_BYTES + 1)
                    var count = 0
                    while (count < buffer.size) { val read = stream.read(buffer, count, buffer.size - count); if (read <= 0) break; count += read }
                    buffer.copyOf(count)
                } ?: error(nativeText("Could not open the text file. Your draft is unchanged.").toString())
            }
            runOnUiThread {
                if (ticket == importRevision) { thread.inputActive = false; importingThread = null; importingWorkspace = null }
                if (!isDestroyed && ticket == importRevision && workspace == inputWorkspace() && session.toki.active === thread) {
                    try {
                        val bytes = result.getOrThrow()
                        session.draft(TokiTextImport.append(bytes, thread.draft) { nativeText(it).toString() })
                    } catch (error: Exception) {
                        themed(MaterialAlertDialogBuilder(this).setMessage(error.message ?: nativeText("Could not import the text file. Your draft is unchanged."))
                            .setPositiveButton(nativeText("OK"), null).show())
                    }
                    render()
                }
            }
        }
    }
    private val notificationPermission = registerForActivityResult(ActivityResultContracts.RequestPermission()) {
        session.refreshNotifications() // Denial never changes work, navigation or sign-in.
    }
    private val pushPermission = registerForActivityResult(ActivityResultContracts.RequestPermission()) {
        session.push.permissionResult(it)
    }
    private val destinations = linkedMapOf(R.id.toki to "Toki", R.id.translations to "Translations", R.id.analytics to "Analytics", R.id.profile to "Profile")

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        setContentView(R.layout.activity_main)
        toolbar = findViewById(R.id.toolbar)
        navigation = findViewById(R.id.navigation)
        for (index in 0 until toolbar.menu.size()) toolbar.menu.getItem(index).let { it.title = nativeText(it.title ?: "") }
        for (index in 0 until navigation.menu.size()) navigation.menu.getItem(index).let { it.title = nativeText(it.title ?: "") }
        screen = findViewById(R.id.screen)
        features = FeatureViews(this)
        login = GlossiaLoginView(this, { session.signIn("https://glossia.ai") }, ::selfHosted,
            session::retryRestore, { session.signOut(resetRegistration = true) })
        voice = TokiVoiceInput(AndroidTokiVoiceCapture(this), { microphoneAllowed() }, { ticket ->
            permissionTicket = ticket; microphonePermission.launch(Manifest.permission.RECORD_AUDIO)
        }, { transcript ->
            val thread = voiceThread
            if (thread != null && session.toki.active === thread && voiceWorkspace == inputWorkspace() && !thread.goalClosed) {
                session.draft(thread.draft + (if (thread.draft.isEmpty() || thread.draft.last().isWhitespace()) "" else " ") + transcript)
                toki.render(true)
            }
        }, {
            voiceThread?.inputActive = voice.busy
            if (::toki.isInitialized) toki.refreshVoice()
        }, { nativeText(it).toString() })
        toki = TokiView(this, session.toki, session::draft, session::sendMessage,
            session::showConversation, { session.loadPage(session.toki.history) }, { session.loadPage(session.toki.history, refresh = true) },
            session::showTranslation, session::retrySource, session::saveGoalDecision, voice, ::startDictation, ::chooseTextFile)
        workspaceError = column(16)
        (findViewById<View>(R.id.root) as LinearLayout).addView(workspaceError, 2)
        navigationNotice = column(16)
        (findViewById<View>(R.id.root) as LinearLayout).addView(navigationNotice, 3)
        navigation.setOnItemSelectedListener { item ->
            if (!bindingNavigation) destinations[item.itemId]?.let {
                (getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager).hideSoftInputFromWindow(screen.windowToken, 0)
                session.selectTab(it)
            }
            true
        }
        toolbar.setOnMenuItemClickListener { item ->
            when (item.itemId) {
                R.id.choose_workspace -> session.openWorkspacePicker()
                R.id.refresh -> { session.reload(); session.loadCurrent(force = true) }
                R.id.compose_conversation -> session.newConversation()
            }
            true
        }
        toolbar.setNavigationOnClickListener {
            (getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager).hideSoftInputFromWindow(screen.windowToken, 0)
            session.back()
        }
        toolbar.setOnClickListener { if (!session.busy) session.openWorkspacePicker() }
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.root)) { view, insets ->
            val bars = insets.getInsets(WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout())
            val ime = insets.getInsets(WindowInsetsCompat.Type.ime())
            keyboardVisible = insets.isVisible(WindowInsetsCompat.Type.ime())
            view.setPadding(bars.left, bars.top, bars.right, maxOf(bars.bottom, ime.bottom))
            navigation.visibility = if (session.server != null && !keyboardVisible) View.VISIBLE else View.GONE
            WindowInsetsCompat.CONSUMED // Root owns system and keyboard insets, exactly once.
        }
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                if (!session.back()) { isEnabled = false; onBackPressedDispatcher.onBackPressed(); isEnabled = true }
            }
        })
        render()
        session.restore()
        if (savedInstanceState == null) consumeIntent(intent)
    }

    override fun onStart() {
        super.onStart()
        session.listener = ::render
        appearance.listener = ::render
        session.setForeground(true)
        render()
    }

    override fun onStop() {
        if (::voice.isInitialized) voice.cancel()
        session.listener = null
        appearance.listener = null
        session.setForeground(false)
        super.onStop()
    }

    override fun onDestroy() {
        workspaceDialog?.setOnCancelListener(null)
        workspaceDialog?.dismiss()
        workspaceDialog = null; workspacePickerView = null
        importRevision += 1; importingThread?.inputActive = false; importingThread = null; importingWorkspace = null
        textImports.shutdownNow()
        super.onDestroy()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        consumeIntent(intent)
    }

    private fun consumeIntent(intent: Intent) {
        if (session.consumePushIntent(intent)) return
        GlossiaIntents.consume(intent, session::receiveLink, session::callback)
    }

    private fun render() {
        if (::voice.isInitialized && voice.busy && (session.tab != "Toki" || voiceWorkspace != inputWorkspace() || session.toki.active?.goalClosed == true)) voice.cancel()
        val connected = session.server != null
        toolbar.visibility = if (connected) View.VISIBLE else View.GONE
        navigation.visibility = if (connected && !keyboardVisible) View.VISIBLE else View.GONE
        findViewById<View>(R.id.workspace_progress).visibility = if (connected && session.busy) View.VISIBLE else View.GONE
        workspaceError.removeAllViews()
        workspaceError.visibility = if (connected && session.error != null) View.VISIBLE else View.GONE
        if (connected) workspaceError.failure(session.error, session::reload)
        navigationNotice.removeAllViews()
        navigationNotice.visibility = if (session.navigationNotice != null) View.VISIBLE else View.GONE
        session.navigationNotice?.let {
            navigationNotice.addView(label(it, 14f, true).apply { accessibilityLiveRegion = View.ACCESSIBILITY_LIVE_REGION_POLITE })
            if (session.hasProtectedWork) {
                navigationNotice.addView(button("Return to draft", action = session::resumeUnsentWork))
                navigationNotice.addView(button("Discard local unsent work", action = ::confirmDiscardUnsentWork))
            }
            val actions = LinearLayout(this)
            if (session.pendingDestination != null) actions.addView(button("Retry link", action = session::retryNavigation))
            actions.addView(button("Dismiss", action = session::dismissNavigationNotice))
            navigationNotice.addView(actions)
        }
        if (!connected) { toki.render(false); login.render(session.busy, session.error); display(login) }
        else {
            val thread = session.toki.active.takeIf { session.tab == "Toki" }
            toolbar.title = if (thread == null) nativeText(session.tab) else if (!thread.created) nativeText("New conversation")
                else thread.conversation?.optionalString("title") ?: nativeText("Conversation")
            if (thread != null) toolbar.setNavigationIcon(R.drawable.ic_back) else toolbar.navigationIcon = null
            toolbar.navigationContentDescription = nativeText("Back to conversations")
            toolbar.subtitle = listOfNotNull(session.organization, session.project).joinToString(" / ").ifBlank { nativeText("Choose a workspace").toString() }
            toolbar.menu.findItem(R.id.choose_workspace).isEnabled = !session.busy
            toolbar.menu.findItem(R.id.refresh).isEnabled = !session.busy
            bindingNavigation = true
            navigation.selectedItemId = destinations.entries.first { it.value == session.tab }.key
            bindingNavigation = false
            val ready = session.organization != null && session.project != null
            toolbar.menu.findItem(R.id.compose_conversation).apply {
                isVisible = session.tab == "Toki" && thread == null
                isEnabled = ready && !session.busy
            }
            when (session.tab) {
                "Toki" -> { toki.render(ready); display(toki) }
                "Translations" -> if (session.translation.id != null) display(features.translation(session.translation,
                    session::loadTranslation, { session.back() }, session::discussTranslation, ::shareTranslation,
                    session::loadTranslationReviews, session::openReviewConversation))
                    else display(features.translations(session.translations, ready,
                        { session.loadPage(session.translations, refresh = true) }, { session.loadPage(session.translations) }, session::showTranslation))
                "Analytics" -> display(features.analytics(session.analytics, ready, session::setAnalyticsDays, session::loadAnalytics))
                "Profile" -> display(features.profile(session.profile, session.server, session.organization, session.project,
                    session::loadProfile, { session.signOut() }, session.push, session.fluentLanguages,
                    session::editFluentLanguages, session::saveFluentLanguages, session::discardFluentLanguages))
            }
        }
        renderWorkspacePicker()
        session.authorizationURL?.let { url ->
            session.authorizationURL = null
            try { startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)).addCategory(Intent.CATEGORY_BROWSABLE)) }
            catch (_: Exception) { themed(MaterialAlertDialogBuilder(this).setMessage(nativeText("No browser is available for secure sign-in.")).setPositiveButton(nativeText("OK"), null).show()) }
        }
        appearance.apply(this, findViewById(R.id.root))
        if (Build.VERSION.SDK_INT >= 33 && lifecycle.currentState.isAtLeast(androidx.lifecycle.Lifecycle.State.STARTED) &&
            session.push.takePermissionRequest()) {
            pushPermission.launch(Manifest.permission.POST_NOTIFICATIONS)
        }
        if (Build.VERSION.SDK_INT >= 33 && lifecycle.currentState.isAtLeast(androidx.lifecycle.Lifecycle.State.STARTED) &&
            session.takeNotificationPermissionRequest()) {
            notificationPermission.launch(Manifest.permission.POST_NOTIFICATIONS)
        }
    }

    private fun display(view: View) {
        if (screen.getChildAt(0) === view) return
        val oldScroll = (screen.getChildAt(0) as? android.widget.ScrollView)?.scrollY ?: 0
        val sameFeature = screen.tag == session.tab
        val reviewInput = currentFocus as? TextInputEditText
        val reviewTag = (reviewInput?.tag as? String)?.takeIf { it.startsWith("review:") }
        val selection = reviewInput?.selectionStart ?: 0
        screen.removeAllViews()
        screen.addView(view, FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT))
        screen.tag = if (session.server == null) "Login" else session.tab
        if (sameFeature && reviewTag != null) {
            view.findViewWithTag<TextInputEditText>(reviewTag)?.takeIf { it.isEnabled }?.let {
                it.requestFocus(); it.setSelection(selection.coerceIn(0, it.length()))
            }
        }
        if (sameFeature && view is android.widget.ScrollView) view.post { view.scrollTo(0, oldScroll) }
    }

    private fun inputWorkspace() = listOf(session.server, session.organization, session.project, session.toki.activeId).joinToString("\u0000")

    private fun startDictation() {
        val thread = session.toki.active ?: return
        if (thread.goalClosed || thread.pending != null || thread.resolving || thread.decision != null || thread.inputActive) return
        voiceThread = thread; voiceWorkspace = inputWorkspace(); voice.start()
    }

    private fun chooseTextFile() {
        val thread = session.toki.active ?: return
        if (thread.goalClosed || thread.pending != null || thread.resolving || thread.decision != null || thread.inputActive) return
        importRevision += 1; importingThread = thread; importingWorkspace = inputWorkspace(); thread.inputActive = true
        textFile.launch(arrayOf("text/*", "application/json", "application/xml", "application/octet-stream"))
        toki.render(true)
    }

    private fun selfHosted() {
        val form = layoutInflater.inflate(R.layout.dialog_server, null)
        (form as com.google.android.material.textfield.TextInputLayout).hint = nativeText("Server address")
        val input = form.findViewById<TextInputEditText>(R.id.server_address)
        themed(MaterialAlertDialogBuilder(this).setTitle(nativeText("Self-hosted server"))
            .setMessage(nativeText("Enter your Glossia server’s HTTPS address.")).setView(form)
            .setPositiveButton(nativeText("Sign in")) { _, _ -> session.signIn(input.text.toString()) }
            .setNegativeButton(nativeText("Cancel"), null).show())
    }

    private fun confirmDiscardUnsentWork() {
        themed(MaterialAlertDialogBuilder(this).setTitle(nativeText("Discard local unsent work?"))
            .setMessage(nativeText("This clears all local Toki drafts and unconfirmed retries. Messages already received by the server may still complete. This does not delete conversations or cancel server work."))
            .setPositiveButton(nativeText("Discard local work")) { _, _ ->
                voice.cancel(); importRevision += 1; importingThread?.inputActive = false; importingThread = null; importingWorkspace = null
                session.toki.active?.inputActive = false; session.discardUnsentWork()
            }
            .setNegativeButton(nativeText("Keep drafts"), null).show())
    }

    private fun shareTranslation() {
        session.shareTranslation { url ->
            if (!isFinishing && !isDestroyed && lifecycle.currentState.isAtLeast(androidx.lifecycle.Lifecycle.State.STARTED)) {
                try { startActivity(GlossiaIntents.shareTranslation(url)) }
                catch (_: android.content.ActivityNotFoundException) {
                    themed(MaterialAlertDialogBuilder(this).setMessage(nativeText("No app is available to share this translation link.")).setPositiveButton(nativeText("OK"), null).show())
                }
            }
        }
    }

    private fun renderWorkspacePicker() {
        if (!session.workspacePicker.open) {
            workspaceDialog?.dismiss(); workspaceDialog = null; workspacePickerView = null
            return
        }
        if (workspaceDialog == null) {
            val view = WorkspacePickerView(this, session.workspacePicker, session.organizations,
                session::browseOrganization, session::selectWorkspaceProject)
            workspacePickerView = view
            workspaceDialog = MaterialAlertDialogBuilder(this).setTitle(nativeText("Switch workspace"))
                .setView(view).setNegativeButton(nativeText("Cancel")) { _, _ -> session.closeWorkspacePicker() }
                .setOnCancelListener { session.closeWorkspacePicker() }.create()
            workspaceDialog?.show()
            workspaceDialog?.let { themed(it) }
        }
        workspacePickerView?.render(session.organization, session.project)
    }
}
