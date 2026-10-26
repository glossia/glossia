package ai.glossia.mobile

import android.content.Context
import androidx.core.content.ContextCompat
import java.security.MessageDigest

// Application-owned sessions and notifications need the compat context on API
// 26–32; unlike Activities, their resources aren't updated by AppCompat.
// Activity resources are already current, even while auto-storage is pending.
private val Context.nativeResources get() =
    if (this === applicationContext) ContextCompat.getContextForLanguage(this).resources else resources

internal val Context.nativeLocale get() = nativeResources.configuration.locales[0]

// Only use for UI copy, never server questions, messages, names, paths or tags.
internal fun Context.nativeText(english: CharSequence): CharSequence {
    val value = english.toString()
    val key = "native_" + MessageDigest.getInstance("SHA-256").digest(value.toByteArray(Charsets.UTF_8))
        .take(8).joinToString("") { "%02x".format(it) }
    val id = resources.getIdentifier(key, "string", packageName)
    return if (id == 0) english else nativeResources.getString(id)
}

internal fun Context.nativeFormat(english: String, vararg arguments: Any): String =
    String.format(nativeLocale, nativeText(english).toString(), *arguments)
