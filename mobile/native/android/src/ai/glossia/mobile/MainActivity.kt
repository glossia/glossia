package ai.glossia.mobile

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.ListView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import com.google.android.material.appbar.MaterialToolbar
import com.google.android.material.bottomnavigation.BottomNavigationView
import com.google.android.material.button.MaterialButton
import com.google.android.material.color.MaterialColors
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.google.android.material.textfield.TextInputEditText
import org.json.JSONArray

class MainActivity : AppCompatActivity() {
    private val session get() = (application as GlossiaApplication).session
    private lateinit var toolbar: MaterialToolbar
    private lateinit var navigation: BottomNavigationView
    private lateinit var content: ListView
    private var bindingNavigation = false
    private val destinations = linkedMapOf(R.id.overview to "Overview", R.id.voice to "Voice", R.id.glossary to "Glossary", R.id.settings to "Settings")
    private val rows = mutableListOf<Row>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        setContentView(R.layout.activity_main)
        toolbar = findViewById(R.id.toolbar)
        navigation = findViewById(R.id.navigation)
        content = findViewById(R.id.content_list)
        content.adapter = ContentAdapter()
        content.setOnItemClickListener { _, _, position, _ ->
            when (rows[position].action) {
                Action.REFRESH -> session.reload()
                Action.RETRY_RESOURCE -> session.loadResource()
                Action.SIGN_OUT -> session.signOut()
                null -> Unit
            }
        }
        navigation.setOnItemSelectedListener { item ->
            if (!bindingNavigation) destinations[item.itemId]?.let(session::selectTab)
            true
        }
        toolbar.setOnMenuItemClickListener { item ->
            when (item.itemId) {
                R.id.choose_workspace -> chooseWorkspace()
                R.id.refresh -> session.reload()
            }
            true
        }
        findViewById<MaterialButton>(R.id.sign_in).setOnClickListener { session.signIn("https://glossia.ai") }
        findViewById<MaterialButton>(R.id.self_hosted).setOnClickListener { selfHosted() }
        findViewById<MaterialButton>(R.id.retry_session).setOnClickListener { session.retryRestore() }
        findViewById<MaterialButton>(R.id.reset_sign_in).setOnClickListener { session.signOut(resetRegistration = true) }
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.root)) { view, insets ->
            val bars = insets.getInsets(WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout())
            view.setPadding(bars.left, bars.top, bars.right, if (session.server == null) bars.bottom else 0)
            insets // BottomNavigationView handles its own bottom system-bar inset.
        }
        session.listener = { render() }
        render()
        session.restore()
        consumeCallback(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        consumeCallback(intent)
    }

    override fun onDestroy() {
        session.listener = null
        super.onDestroy()
    }

    private fun consumeCallback(intent: Intent) {
        val uri = intent.data ?: return
        intent.data = null
        if (uri.scheme == "glossia" && uri.host == "oauth" && uri.path == "/callback") session.callback(uri.toString())
    }

    private fun render() {
        val connected = session.server != null
        toolbar.visibility = if (connected) View.VISIBLE else View.GONE
        navigation.visibility = toolbar.visibility
        content.visibility = toolbar.visibility
        findViewById<View>(R.id.login).visibility = if (connected) View.GONE else View.VISIBLE
        findViewById<View>(R.id.workspace_progress).visibility = if (connected && (session.busy || session.resourceBusy)) View.VISIBLE else View.GONE
        findViewById<View>(R.id.login_progress).visibility = if (!connected && session.busy) View.VISIBLE else View.GONE
        findViewById<TextView>(R.id.login_error).apply {
            text = session.error
            visibility = if (session.error != null) View.VISIBLE else View.GONE
        }
        findViewById<MaterialButton>(R.id.retry_session).visibility = if (session.error != null) View.VISIBLE else View.GONE
        listOf(R.id.sign_in, R.id.self_hosted, R.id.retry_session, R.id.reset_sign_in).forEach { findViewById<View>(it).isEnabled = !session.busy }
        if (connected) {
            toolbar.title = session.tab
            toolbar.subtitle = listOfNotNull(session.organization, session.project).joinToString(" / ")
            toolbar.menu.findItem(R.id.choose_workspace).isEnabled = !session.busy
            toolbar.menu.findItem(R.id.refresh).isEnabled = !session.busy
            bindingNavigation = true
            navigation.selectedItemId = destinations.entries.first { it.value == session.tab }.key
            bindingNavigation = false
            rows.clear()
            session.error?.let { rows.add(Row("Could not load workspace", it)); rows.add(Row("Retry", action = Action.REFRESH)) }
            if (session.busy) rows.add(Row("Loading workspace…"))
            else when (session.tab) {
                "Overview" -> overview()
                "Voice", "Glossary" -> resource()
                "Settings" -> settings()
            }
            (content.adapter as ContentAdapter).notifyDataSetChanged()
        }
        ViewCompat.requestApplyInsets(findViewById(R.id.root))
        session.authorizationURL?.let { url ->
            session.authorizationURL = null
            try { startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)).addCategory(Intent.CATEGORY_BROWSABLE)) }
            catch (_: Exception) { MaterialAlertDialogBuilder(this).setMessage("No browser is available for secure sign-in.").setPositiveButton("OK", null).show() }
        }
    }

    private fun selfHosted() {
        val form = layoutInflater.inflate(R.layout.dialog_server, null)
        val input = form.findViewById<TextInputEditText>(R.id.server_address)
        MaterialAlertDialogBuilder(this).setTitle("Self-hosted server")
            .setMessage("Enter your Glossia server’s HTTPS address.").setView(form)
            .setPositiveButton("Sign in") { _, _ -> session.signIn(input.text.toString()) }
            .setNegativeButton("Cancel", null).show()
    }

    private fun chooseWorkspace() {
        MaterialAlertDialogBuilder(this).setTitle("Workspace")
            .setItems(arrayOf("Organization · ${session.organization ?: "None"}", "Project · ${session.project ?: "None"}")) { _, index ->
                if (index == 0) choose("Organization", session.organizations, session.organization, session::selectOrganization)
                else choose("Project", session.projects, session.project, session::selectProject)
            }.setNegativeButton("Cancel", null).show()
    }

    private fun choose(title: String, items: JSONArray, selected: String?, select: (String) -> Unit) {
        val options = (0 until items.length()).map { items.getJSONObject(it) }
        MaterialAlertDialogBuilder(this).setTitle(title)
            .setSingleChoiceItems(options.map { it.optString("name", it.getString("handle")) }.toTypedArray(), options.indexOfFirst { it.optString("handle") == selected }) { dialog, index ->
                dialog.dismiss()
                select(options[index].getString("handle"))
            }.setNegativeButton("Cancel", null).show()
    }

    private fun overview() {
        if (session.organization == null) {
            rows.add(Row("No organizations yet", "Create or join an organization on Glossia to get started."))
            return
        }
        val project = (0 until session.projects.length()).map { session.projects.getJSONObject(it) }.firstOrNull { it.optString("handle") == session.project }
        if (project == null) rows.add(Row("No projects yet", "Voice and glossary are still available for this organization."))
        else {
            rows.add(Row("Project", project.optString("name", session.project ?: "Project")))
            rows.add(Row("Organization", session.organization))
            project.optionalString("setup_status")?.let { rows.add(Row("Setup", it)) }
            project.optionalString("github_repo_full_name")?.let { rows.add(Row("Repository", it)) }
        }
    }

    private fun resource() {
        rows.add(Row("Organization", session.organization ?: "None"))
        rows.add(Row("Organization-wide", "Shared by every project in this organization."))
        if (session.organization == null) { rows.add(Row("Choose an organization first")); return }
        if (session.resourceBusy) { rows.add(Row("Loading ${session.tab.lowercase()}…")); return }
        session.resourceError?.let {
            rows.add(Row("Could not load ${session.tab.lowercase()}", it))
            rows.add(Row("Retry", action = Action.RETRY_RESOURCE))
            return
        }
        val resource = session.resource
        if (resource == null) {
            rows.add(Row("No ${session.tab.lowercase()} configured", "Configure your organization’s ${session.tab.lowercase()} on Glossia."))
            return
        }
        if (resource.has("version")) rows.add(Row("Version", resource.optInt("version").toString()))
        if (session.tab == "Voice") {
            listOf("tone" to "Tone", "formality" to "Formality", "target_audience" to "Target audience", "guidelines" to "Guidelines").forEach { (key, title) ->
                resource.optionalString(key)?.let { rows.add(Row(title, it)) }
            }
        } else {
            val entries = resource.optJSONArray("entries") ?: JSONArray()
            if (entries.length() == 0) rows.add(Row("No glossary entries yet"))
            for (index in 0 until entries.length()) {
                val entry = entries.getJSONObject(index)
                rows.add(Row(entry.optString("term"), entry.optString("definition")))
            }
        }
    }

    private fun settings() {
        rows.add(Row("Server", session.server))
        rows.add(Row("Organization", session.organization ?: "None"))
        rows.add(Row("Project", session.project ?: "None"))
        rows.add(Row("Secure storage", "Your credentials are encrypted with a key protected by Android Keystore."))
        rows.add(Row("Sign out", action = Action.SIGN_OUT))
    }

    private enum class Action { REFRESH, RETRY_RESOURCE, SIGN_OUT }
    private data class Row(val title: String, val detail: String? = null, val action: Action? = null)

    private inner class ContentAdapter : ArrayAdapter<Row>(this@MainActivity, android.R.layout.simple_list_item_2, rows) {
        override fun areAllItemsEnabled() = false
        override fun isEnabled(position: Int) = getItem(position)?.action != null

        override fun getView(position: Int, recycled: View?, parent: ViewGroup): View {
            val view = recycled ?: layoutInflater.inflate(android.R.layout.simple_list_item_2, parent, false)
            val row = getItem(position)!!
            view.findViewById<TextView>(android.R.id.text1).apply {
                text = row.title
                setTextAppearance(com.google.android.material.R.style.TextAppearance_Material3_TitleMedium)
                setTextColor(MaterialColors.getColor(this, when (row.action) {
                    Action.SIGN_OUT -> com.google.android.material.R.attr.colorError
                    null -> com.google.android.material.R.attr.colorOnSurface
                    else -> com.google.android.material.R.attr.colorPrimary
                }))
            }
            view.findViewById<TextView>(android.R.id.text2).apply {
                text = row.detail
                visibility = if (row.detail == null) View.GONE else View.VISIBLE
                setTextAppearance(com.google.android.material.R.style.TextAppearance_Material3_BodyMedium)
                setTextColor(MaterialColors.getColor(this, com.google.android.material.R.attr.colorOnSurfaceVariant))
            }
            return view
        }
    }
}
