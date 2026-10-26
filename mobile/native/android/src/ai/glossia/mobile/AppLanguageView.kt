package ai.glossia.mobile

import android.content.Context
import android.view.View
import androidx.appcompat.app.AppCompatDelegate
import androidx.core.os.LocaleListCompat
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import org.xmlpull.v1.XmlPullParser
import java.util.Locale

// Read only Glossia's packaged catalogs. AssetManager.locales also contains
// Material/AppCompat translations, which do not translate the app itself.
internal fun Context.appLanguageTags(): List<String> = resources.getXml(R.xml.app_locales).use { xml ->
    buildList {
        while (xml.next() != XmlPullParser.END_DOCUMENT) {
            if (xml.eventType == XmlPullParser.START_TAG && xml.name == "locale") {
                add(Locale.forLanguageTag(xml.getAttributeValue("http://schemas.android.com/apk/res/android", "name")).toLanguageTag())
            }
        }
    }
}

internal fun Context.appLanguageView(): View = card {
    val tags = listOf("") + appLanguageTags()
    val names = tags.map { tag ->
        if (tag.isEmpty()) nativeText("System default").toString()
        else Locale.forLanguageTag(tag).let { it.getDisplayName(it) }
    }
    val selected = tags.indexOf(AppCompatDelegate.getApplicationLocales()[0]?.toLanguageTag() ?: "")
    addSpaced(heading("App language", 18f), 8)
    addSpaced(label("Choose the language for this app. This does not change your fluent languages.", muted = true), 8)
    addView(button("App language") {
        themed(MaterialAlertDialogBuilder(this@appLanguageView).setTitle(nativeText("App language"))
            .setSingleChoiceItems(names.toTypedArray(), selected) { dialog, index ->
                dialog.dismiss()
                // AppCompat recreates the Activity, including resources and layout
                // direction. Session and unsaved models belong to the Application.
                AppCompatDelegate.setApplicationLocales(LocaleListCompat.forLanguageTags(tags[index]))
            }.setNegativeButton(nativeText("Cancel"), null).show())
    }.apply {
        text = names.getOrNull(selected) ?: AppCompatDelegate.getApplicationLocales()[0]?.let { it.getDisplayName(it) }
        contentDescription = nativeFormat("App language: %1\$s", text)
    })
}
