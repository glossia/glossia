package ai.glossia.mobile

import android.content.Context
import android.text.Editable
import android.text.InputType
import android.text.TextWatcher
import android.view.View
import com.google.android.material.textfield.TextInputEditText
import com.google.android.material.textfield.TextInputLayout

internal fun Context.fluentLanguagesView(model: FluentLanguagesModel, save: () -> Unit, discard: () -> Unit): View = column(20).apply {
    addSpaced(heading("Fluent languages"), 12)
    addSpaced(label("These languages help invite authorized linguists into the same shared review conversation. They do not change the app language or grant project access.", muted = true), 12)
    addSpaced(TextInputLayout(this@fluentLanguagesView, null, com.google.android.material.R.attr.textInputOutlinedStyle).apply {
        hint = nativeText("Language tags")
        helperText = nativeText("BCP47 tags, for example es, ar, zh-Hant")
        boxBackgroundMode = TextInputLayout.BOX_BACKGROUND_OUTLINE
        addView(TextInputEditText(context).apply {
            inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS
            isSaveEnabled = false; importantForAutofill = View.IMPORTANT_FOR_AUTOFILL_NO_EXCLUDE_DESCENDANTS
            textDirection = View.TEXT_DIRECTION_LTR; isEnabled = !model.saving
            setText(model.draft)
            addTextChangedListener(object : TextWatcher {
                override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) = Unit
                override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) { model.draft = s.toString() }
                override fun afterTextChanged(s: Editable?) = Unit
            })
        })
    }, 12)
    addSpaced(label("Separate language tags with commas. Leave empty to remove your fluent languages.", 12f, true), 12)
    model.error?.let { addSpaced(label(it, verbatim = true), 12) }
    if (model.saving) loading("Saving fluent languages…")
    addSpaced(button("Save fluent languages", true, save).apply { isEnabled = !model.saving }, 8)
    addView(button("Discard changes", action = discard).apply { isEnabled = !model.saving })
}
