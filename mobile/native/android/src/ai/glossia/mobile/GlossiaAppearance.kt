package ai.glossia.mobile

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.content.res.ColorStateList
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.provider.Settings
import android.view.View
import android.view.ViewGroup
import android.widget.EditText
import android.widget.TextView
import androidx.appcompat.app.AlertDialog
import androidx.core.graphics.ColorUtils
import androidx.core.view.WindowCompat
import com.google.android.material.appbar.MaterialToolbar
import com.google.android.material.bottomnavigation.BottomNavigationView
import com.google.android.material.button.MaterialButton
import com.google.android.material.card.MaterialCardView
import com.google.android.material.chip.Chip
import com.google.android.material.progressindicator.BaseProgressIndicator
import com.google.android.material.textfield.TextInputLayout
import org.json.JSONObject
import java.lang.ref.WeakReference
import java.net.URI
import java.util.Locale
import java.util.concurrent.Executors

internal interface AppearanceOwner { val appearance: GlossiaAppearance }

internal val Context.appearance: GlossiaAppearance?
    get() = when (this) {
        is AppearanceOwner -> appearance
        is ContextWrapper -> baseContext.appearance
        else -> null
    }

// Only explicit semantic bindings are repainted. Error labels, selectable text,
// button foregrounds and Material's internal TextViews keep their own roles.
internal fun <T : View> T.themed(binding: T.() -> Unit): T = apply {
    setTag(R.id.appearance_binding, { binding() })
    binding()
}

internal fun Context.themed(dialog: AlertDialog): AlertDialog = dialog.also {
    it.window?.decorView?.layoutDirection = android.text.TextUtils.getLayoutDirectionFromLocale(nativeLocale)
    appearance?.watch(it)
}

internal fun View.readableErrorColor(): Int {
    val error = com.google.android.material.color.MaterialColors.getColor(this, com.google.android.material.R.attr.colorError)
    return if (listOf(R.color.glossia_background, R.color.glossia_surface).all {
        ColorUtils.calculateContrast(error, context.token(it)) >= 4.5
    }) error else context.token(R.color.glossia_text)
}

class GlossiaAppearance internal constructor(context: Context,
    private val bridge: (String) -> String = { GlossiaCore.execute(it) },
    private val now: () -> Long = { SystemClock.elapsedRealtime() }) {
    private val context = context.applicationContext
    private val preferences = context.getSharedPreferences("glossia.appearance", Context.MODE_PRIVATE)
    // Independent of credential rotation AND feature traffic. An old origin's
    // slow request cannot delay loading a newly selected origin's catalog.
    private val worker = Executors.newFixedThreadPool(2)
    private val main = Handler(Looper.getMainLooper())
    private var generation = 0
    private var loading = false
    private var refreshedAt: Long? = null
    private var closed = false
    private val dialogs = mutableListOf<WeakReference<AlertDialog>>()
    var listener: (() -> Unit)? = null
    var server: String? = null
        private set
    var catalog: JSONObject? = null
        private set
    private val theme: JSONObject?
        get() = catalog?.let { value ->
            val themes = value.getJSONArray("themes")
            (0 until themes.length()).map { themes.getJSONObject(it) }
                .firstOrNull { it.getString("id") == value.getString("default_theme_id") }
        }

    fun configure(address: String) {
        if (closed) return
        val origin = normalizeOrigin(address) ?: return
        if (server == origin) { refresh(); return }
        server = origin; generation += 1; catalog = null; refreshedAt = null; loading = true
        listener?.invoke()
        val ticket = generation
        val cached = runCatching { preferences.getString("$origin.catalog", null) }.getOrNull()
        worker.execute {
            val saved = cached?.takeIf { it.length <= 65_536 }?.let {
                runCatching { command(JSONObject().put("operation", "validate_themes").put("catalog", JSONObject(it))) }.getOrNull()
            }
            main.post {
                if (!closed && ticket == generation) {
                    catalog = saved; loading = false
                    listener?.invoke()
                    refresh()
                }
            }
        }
    }

    fun refresh() {
        val origin = server ?: return
        if (closed || loading || refreshedAt?.let { now() - it < 300_000 } == true) return
        loading = true
        val ticket = generation
        worker.execute {
            val result = runCatching { command(JSONObject().put("operation", "themes").put("server", origin)) }.getOrNull()
            main.post {
                if (!closed && ticket == generation) {
                    loading = false; refreshedAt = now()
                    if (result != null) {
                        preferences.edit().putString("$origin.catalog", result.toString()).apply()
                        if (catalog?.toString() != result.toString()) { catalog = result; listener?.invoke() }
                    }
                }
            }
        }
    }

    private fun command(request: JSONObject) = JSONObject(bridge(request.toString())).getJSONObject("ok")

    internal fun close() {
        closed = true; generation += 1; listener = null; dialogs.clear(); worker.shutdownNow()
    }

    internal fun color(resources: Context, id: Int): Int? {
        val dark = resources.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK == Configuration.UI_MODE_NIGHT_YES
        val key = when (id) {
            R.color.glossia_background -> "background"
            R.color.glossia_surface, R.color.glossia_login_panel -> "surface"
            R.color.glossia_subtle, R.color.glossia_accent_soft -> "subtle"
            R.color.glossia_text -> "text"
            R.color.glossia_muted -> "secondary_text"
            R.color.glossia_border -> "border"
            R.color.glossia_primary, R.color.glossia_atmosphere -> "accent"
            R.color.glossia_on_primary -> "on_accent"
            else -> return null
        }
        val palette = theme?.getJSONObject(if (dark) "dark" else "light") ?: return null
        val contrast = Settings.Secure.getInt(context.contentResolver, "high_text_contrast_enabled", 0) == 1
        if (contrast && key in listOf("text", "secondary_text")) return if (dark) Color.WHITE else Color.BLACK
        if (contrast && key in listOf("background", "surface", "subtle")) return if (dark) Color.BLACK else Color.WHITE
        val value = Color.parseColor(palette.getString(key))
        return if (id == R.color.glossia_atmosphere) ColorUtils.setAlphaComponent(value, 80) else value
    }

    private fun tint(context: Context): Int {
        val dark = context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK == Configuration.UI_MODE_NIGHT_YES
        return theme?.getJSONObject(if (dark) "dark" else "light")?.getString("tint")?.let(Color::parseColor)
            ?: context.token(R.color.glossia_primary)
    }

    internal fun apply(activity: Activity, root: View) {
        root.setBackgroundColor(root.context.token(R.color.glossia_background))
        paint(root)
        val background = root.context.token(R.color.glossia_background)
        @Suppress("DEPRECATION")
        activity.window.apply { statusBarColor = background; navigationBarColor = background }
        WindowCompat.getInsetsController(activity.window, root).apply {
            isAppearanceLightStatusBars = ColorUtils.calculateLuminance(background) > 0.5
            isAppearanceLightNavigationBars = isAppearanceLightStatusBars
        }
        dialogs.removeAll { it.get() == null }
        dialogs.mapNotNull { it.get() }.filter { it.isShowing }.forEach(::paintDialog)
    }

    internal fun watch(dialog: AlertDialog) {
        dialogs.add(WeakReference(dialog)); paintDialog(dialog)
    }

    private fun paintDialog(dialog: AlertDialog) {
        val root = dialog.window?.decorView ?: return
        val context = root.context
        dialog.window?.setBackgroundDrawable(GradientDrawable().apply {
            setColor(context.token(R.color.glossia_surface)); cornerRadius = radius(context, "card_radius", 20)
        })
        paint(root, dialog = true)
        listOf(AlertDialog.BUTTON_POSITIVE, AlertDialog.BUTTON_NEGATIVE, AlertDialog.BUTTON_NEUTRAL).forEach {
            dialog.getButton(it)?.setTextColor(states(tint(context)))
        }
    }

    internal fun radius(context: Context, key: String, fallback: Int) =
        (theme?.optDouble(key, fallback.toDouble()) ?: fallback.toDouble()).toFloat() * context.resources.displayMetrics.density

    internal fun paint(view: View, dialog: Boolean = false) {
        val context = view.context
        fun color(id: Int) = context.token(id)
        val text = color(R.color.glossia_text); val muted = color(R.color.glossia_muted)
        val surface = color(R.color.glossia_surface); val border = color(R.color.glossia_border)
        val accent = color(R.color.glossia_primary); val tint = tint(context)
        @Suppress("UNCHECKED_CAST")
        (view.getTag(R.id.appearance_binding) as? (() -> Unit))?.invoke()
        when (view) {
            is MaterialToolbar -> {
                view.setBackgroundColor(surface); view.setTitleTextColor(text); view.setSubtitleTextColor(muted)
                view.navigationIcon?.setTint(tint); view.overflowIcon?.setTint(tint)
                for (index in 0 until view.menu.size()) view.menu.getItem(index).icon?.mutate()?.setTintList(states(tint))
                return
            }
            is BottomNavigationView -> {
                view.setBackgroundColor(color(R.color.glossia_background))
                val colors = ColorStateList(arrayOf(intArrayOf(-android.R.attr.state_enabled), intArrayOf(android.R.attr.state_checked), intArrayOf()),
                    intArrayOf(ColorUtils.setAlphaComponent(muted, 97), tint, muted))
                view.itemTextColor = colors; view.itemIconTintList = colors
                view.itemActiveIndicatorColor = ColorStateList.valueOf(color(R.color.glossia_subtle))
                view.itemRippleColor = ColorStateList.valueOf(ColorUtils.setAlphaComponent(tint, 40))
                return
            }
            is MaterialButton -> {
                val primary = view.getTag(R.id.appearance_primary) == true
                val outlined = view.getTag(R.id.appearance_surface) == true
                view.cornerRadius = radius(context, "button_radius", 12).toInt()
                view.backgroundTintList = states(if (primary) accent else if (outlined || view.isChecked) surface else Color.TRANSPARENT)
                view.setTextColor(states(if (primary) color(R.color.glossia_on_primary) else if (outlined) text else tint))
                if (view.iconTint != null) view.iconTint = states(if (primary) color(R.color.glossia_on_primary) else tint)
                view.strokeColor = states(border)
                view.rippleColor = ColorStateList.valueOf(ColorUtils.setAlphaComponent(if (primary) color(R.color.glossia_on_primary) else tint, 40))
                @Suppress("UNCHECKED_CAST")
                (view.getTag(R.id.appearance_binding) as? (() -> Unit))?.invoke()
                return
            }
            is MaterialCardView -> {
                view.radius = if (view.getTag(R.id.appearance_surface) == "composer") context.dp(28).toFloat() else radius(context, "card_radius", 20)
                view.strokeColor = border
                view.setCardBackgroundColor(color(if (view.getTag(R.id.appearance_surface) == "subtle") R.color.glossia_subtle else R.color.glossia_surface))
            }
            is Chip -> {
                view.chipBackgroundColor = states(color(R.color.glossia_subtle)); view.setTextColor(states(text))
                view.chipStrokeColor = states(border); view.rippleColor = states(ColorUtils.setAlphaComponent(tint, 40))
                view.chipIconTint = states(tint); view.checkedIconTint = states(tint)
                view.shapeAppearanceModel = view.shapeAppearanceModel.toBuilder().setAllCornerSizes(radius(context, "button_radius", 12)).build()
                return
            }
            is TextInputLayout -> {
                view.defaultHintTextColor = states(muted); view.hintTextColor = states(tint)
                view.setHelperTextColor(states(muted)); view.setCounterTextColor(states(muted))
                view.setErrorTextColor(states(view.readableErrorColor()))
                view.setCounterOverflowTextColor(states(view.readableErrorColor()))
                view.setStartIconTintList(states(tint)); view.setEndIconTintList(states(tint))
                view.setErrorIconTintList(states(view.readableErrorColor()))
                view.boxBackgroundColor = surface
                view.setBoxStrokeColorStateList(ColorStateList(arrayOf(intArrayOf(-android.R.attr.state_enabled), intArrayOf(android.R.attr.state_focused), intArrayOf()),
                    intArrayOf(ColorUtils.setAlphaComponent(border, 97), tint, border)))
                val radius = radius(context, "button_radius", 20)
                view.setBoxCornerRadii(radius, radius, radius, radius)
                // Material owns the hint, helper, counter and error TextViews.
                view.editText?.let {
                    paint(it)
                    // Its background may be Material's outlined box drawable,
                    // not an underline. Tinting it paints the entire input accent.
                    it.backgroundTintList = null
                }
                return
            }
            is EditText -> {
                view.setTextColor(states(text)); view.setHintTextColor(states(muted)); view.backgroundTintList = states(tint)
                if (android.os.Build.VERSION.SDK_INT >= 29) view.textCursorDrawable?.mutate()?.setTint(tint)
            }
            is BaseProgressIndicator<*> -> { view.setIndicatorColor(accent); view.trackColor = border }
            is TextView -> if (dialog && view.getTag(R.id.appearance_binding) == null &&
                view.id != com.google.android.material.R.id.textinput_error) view.setTextColor(states(text))
        }
        view.invalidate()
        if (view is ViewGroup) for (index in 0 until view.childCount) paint(view.getChildAt(index), dialog)
    }

    companion object {
        // This only constructs a cache identity. Rust validates the URL and every
        // cached/network catalog before any tokens are accepted.
        internal fun normalizeOrigin(address: String): String? = runCatching {
            val uri = URI(address.trim())
            require(uri.scheme.equals("https", ignoreCase = true) && uri.host != null && uri.rawUserInfo == null &&
                uri.rawQuery == null && uri.rawFragment == null && uri.rawPath in listOf("", "/") &&
                (uri.port == -1 || uri.port in 1..65535))
            URI("https", null, uri.host.lowercase(Locale.ROOT), if (uri.port == 443) -1 else uri.port, null, null, null).toASCIIString()
        }.getOrNull()

        internal fun states(color: Int) = ColorStateList(arrayOf(intArrayOf(-android.R.attr.state_enabled), intArrayOf()),
            intArrayOf(ColorUtils.setAlphaComponent(color, Color.alpha(color) * 38 / 100), color))
    }
}
