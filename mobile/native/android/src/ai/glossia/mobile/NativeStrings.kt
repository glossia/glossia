package ai.glossia.mobile

import android.content.Context
import java.security.MessageDigest

// Only use for UI copy, never server questions, messages, names, paths or tags.
internal fun Context.nativeText(english: CharSequence): CharSequence {
    val value = english.toString()
    val key = "native_" + MessageDigest.getInstance("SHA-256").digest(value.toByteArray(Charsets.UTF_8))
        .take(8).joinToString("") { "%02x".format(it) }
    val id = resources.getIdentifier(key, "string", packageName)
    return if (id == 0) english else getString(id)
}

internal fun Context.nativeFormat(english: String, vararg arguments: Any): String =
    String.format(resources.configuration.locales[0], nativeText(english).toString(), *arguments)
