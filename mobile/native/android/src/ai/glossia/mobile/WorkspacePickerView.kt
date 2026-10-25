package ai.glossia.mobile

import android.content.Context
import android.text.Editable
import android.text.TextWatcher
import android.view.View
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.CheckedTextView
import android.widget.LinearLayout
import android.widget.ListView
import android.widget.TextView
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.google.android.material.textfield.TextInputEditText
import com.google.android.material.textfield.TextInputLayout
import org.json.JSONArray
import org.json.JSONObject

// Candidate state is application-owned. This dialog is only a projection of it;
// no organization switch becomes active before the user chooses a project.
class WorkspacePickerView(context: Context, private val model: WorkspacePickerModel,
    private val organizations: JSONArray, private val browse: (String) -> Unit,
    private val commit: (String) -> Unit) : LinearLayout(context) {
    private val current = context.label("", 13f, true)
    private val organizationButton = context.button("Organization") { chooseOrganization() }
    private val search = TextInputEditText(context).apply {
        isSingleLine = true; isSaveEnabled = false
        importantForAutofill = View.IMPORTANT_FOR_AUTOFILL_NO_EXCLUDE_DESCENDANTS
        setText(model.search)
    }
    private val status = context.label("", 14f, true)
    private val retry = context.button("Retry loading projects") { model.organization?.let(browse) }
    private val adapter = object : ArrayAdapter<String>(context, android.R.layout.simple_list_item_1, mutableListOf()) {
        override fun getView(position: Int, convertView: View?, parent: ViewGroup): View =
            (super.getView(position, convertView, parent) as TextView).themed {
                setTextColor(GlossiaAppearance.states(context.token(R.color.glossia_text)))
            }
    }
    private val list = ListView(context).apply { adapter = this@WorkspacePickerView.adapter; divider = null }
    private var projects = listOf<JSONObject>()
    private var activeOrganization: String? = null
    private var activeProject: String? = null

    init {
        orientation = VERTICAL
        setPadding(context.dp(24), context.dp(8), context.dp(24), 0)
        addSpaced(current)
        addSpaced(organizationButton, 8)
        addSpaced(TextInputLayout(context, null, com.google.android.material.R.attr.textInputOutlinedStyle).apply {
            hint = context.nativeText("Search projects"); addView(search)
        })
        addView(status); addView(retry)
        addView(list, LayoutParams(LayoutParams.MATCH_PARENT, context.dp(240)))
        list.setOnItemClickListener { _, _, index, _ -> if (!model.busy) commit(projects[index].getString("handle")) }
        search.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) = Unit
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) { model.search = s.toString(); updateProjects() }
            override fun afterTextChanged(s: Editable?) = Unit
        })
    }

    fun render(organization: String?, project: String?) {
        activeOrganization = organization; activeProject = project
        current.text = context.nativeFormat("Current: %1\$s / %2\$s", organization ?: context.nativeText("No organization"), project ?: context.nativeText("No project"))
        organizationButton.text = context.nativeFormat("Organization: %1\$s ▾", model.organization ?: context.nativeText("Choose"))
        organizationButton.isEnabled = organizations.length() > 0
        if (search.text.toString() != model.search) search.setText(model.search)
        retry.visibility = if (model.error == null) View.GONE else View.VISIBLE
        updateProjects()
    }

    private fun updateProjects() {
        projects = (0 until model.projects.length()).map { model.projects.getJSONObject(it) }.filter {
            "${it.optString("name")} ${it.optString("handle")}".contains(model.search, ignoreCase = true)
        }
        adapter.clear()
        adapter.addAll(projects.map {
            val check = if (model.organization == activeOrganization && it.optString("handle") == activeProject) "✓  " else ""
            "$check${it.optionalString("name") ?: it.getString("handle")}\n${model.organization} / ${it.optString("handle")}"
        })
        list.isEnabled = !model.busy && model.error == null
        status.text = when {
            model.busy -> context.nativeText("Loading projects…")
            model.error != null -> model.error
            model.organization == null -> context.nativeText("Choose an organization to see its projects.")
            model.projects.length() == 0 -> context.nativeText("No projects in this organization. Choose another organization or create a project on Glossia.")
            projects.isEmpty() -> context.nativeText("No matching projects.")
            else -> context.nativeText("Select a project to switch workspace.")
        }
        status.accessibilityLiveRegion = View.ACCESSIBILITY_LIVE_REGION_POLITE
    }

    private fun chooseOrganization() {
        val options = (0 until organizations.length()).map { organizations.getJSONObject(it) }
        val choices = object : ArrayAdapter<String>(context, android.R.layout.simple_list_item_single_choice,
            options.map { "${it.optionalString("name") ?: it.optString("handle")} (${it.optString("handle")})" }) {
            override fun getView(position: Int, convertView: View?, parent: ViewGroup): View =
                (super.getView(position, convertView, parent) as CheckedTextView).themed {
                    setTextColor(GlossiaAppearance.states(context.token(R.color.glossia_text)))
                    checkMarkTintList = GlossiaAppearance.states(context.token(R.color.glossia_primary))
                }
        }
        context.themed(MaterialAlertDialogBuilder(context).setTitle(context.nativeText("Organization"))
            .setSingleChoiceItems(choices,
                options.indexOfFirst { it.optString("handle") == model.organization }) { dialog, index ->
                dialog.dismiss(); browse(options[index].getString("handle"))
            }.setNegativeButton(context.nativeText("Cancel"), null).show())
    }
}
