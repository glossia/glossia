package ai.glossia.mobile

import android.content.Context
import android.content.res.ColorStateList
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.ColorFilter
import android.graphics.Paint
import android.graphics.PixelFormat
import android.graphics.RadialGradient
import android.graphics.Shader
import android.graphics.Typeface
import android.graphics.drawable.Drawable
import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import androidx.core.content.ContextCompat
import com.google.android.material.button.MaterialButton
import com.google.android.material.card.MaterialCardView
import com.google.android.material.progressindicator.CircularProgressIndicator
import com.google.android.material.textview.MaterialTextView

internal fun Context.dp(value: Int) = (value * resources.displayMetrics.density).toInt()
internal fun Context.token(color: Int) = appearance?.color(this, color) ?: ContextCompat.getColor(this, color)
internal fun Context.column(padding: Int = 0) = LinearLayout(this).apply {
    orientation = LinearLayout.VERTICAL
    setPadding(dp(padding), dp(padding), dp(padding), dp(padding))
}
internal fun Context.label(value: CharSequence, size: Float = 14f, muted: Boolean = false) = MaterialTextView(this).apply {
    text = value; textSize = size
    themed { setTextColor(GlossiaAppearance.states(context.token(if (muted) R.color.glossia_muted else R.color.glossia_text))) }
    setLineSpacing(dp(3).toFloat(), 1f)
}
internal fun Context.heading(value: String, size: Float = 24f) = label(value, size).apply {
    typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
    androidx.core.view.ViewCompat.setAccessibilityHeading(this, true)
}
internal fun Context.button(value: String, primary: Boolean = false, action: () -> Unit) = MaterialButton(
    this, null, if (primary) com.google.android.material.R.attr.materialButtonStyle else com.google.android.material.R.attr.borderlessButtonStyle
).apply {
    text = value; isAllCaps = false; minHeight = dp(48); cornerRadius = dp(12)
    setTag(R.id.appearance_primary, primary)
    setOnClickListener { action() }
}
internal fun LinearLayout.addSpaced(view: View, gap: Int = 12) {
    addView(view, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply { bottomMargin = context.dp(gap) })
}
internal fun Context.card(body: LinearLayout.() -> Unit): MaterialCardView = MaterialCardView(this).apply {
    radius = dp(20).toFloat(); cardElevation = 0f; strokeWidth = dp(1)
    strokeColor = token(R.color.glossia_border); setCardBackgroundColor(token(R.color.glossia_surface))
    addView(column(20).apply(body))
}
internal fun Context.scroll(body: LinearLayout): ScrollView = ScrollView(this).apply {
    isFillViewport = true; clipToPadding = false
    addView(body, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
}
internal fun LinearLayout.loading(title: String) {
    val row = LinearLayout(context).apply { gravity = Gravity.CENTER_VERTICAL }
    row.addView(CircularProgressIndicator(context).apply {
        isIndeterminate = true; indicatorSize = context.dp(20); trackThickness = context.dp(2)
        contentDescription = title
    }, LinearLayout.LayoutParams(context.dp(32), context.dp(32)))
    row.addView(context.label(title, muted = true), LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
    addSpaced(row)
}
internal fun LinearLayout.failure(message: String?, retry: () -> Unit) {
    if (message == null) return
    addSpaced(context.card {
        addSpaced(context.label(message).apply {
            themed { setTextColor(readableErrorColor()) }
            accessibilityLiveRegion = View.ACCESSIBILITY_LIVE_REGION_POLITE
        }, 0)
        addView(context.button("Retry", action = retry))
    })
}
internal fun Context.mascot(image: Int, size: Int = 168) = ImageView(this).apply {
    setImageResource(image); scaleType = ImageView.ScaleType.FIT_CENTER
    importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
    layoutParams = LinearLayout.LayoutParams(dp(size), dp(size)).apply { gravity = Gravity.CENTER_HORIZONTAL }
}

// Atlas's weighted hero + bottom translucent sheet composition, using Glossia's
// warm stone and violet tokens. No provider UI unsupported by the Rust core.
class GlossiaLoginView(context: Context, hosted: () -> Unit, selfHosted: () -> Unit,
    retry: () -> Unit, reset: () -> Unit) : FrameLayout(context) {
    private val progress = context.column().apply { loading("Connecting securely…") }
    private val errorLabel = context.label("", muted = false).apply {
        gravity = Gravity.CENTER; accessibilityLiveRegion = View.ACCESSIBILITY_LIVE_REGION_POLITE
        themed { setTextColor(readableErrorColor()) }
    }
    private val hostedButton = context.button("Sign in with Glossia", true, hosted)
    private val selfHostedButton = context.button("Self-hosted server", action = selfHosted)
    private val retryButton = context.button("Retry saved session", action = retry)
    private val resetButton = context.button("Reset saved sign-in", action = reset)

    init {
        background = Atmosphere(context)
        val content = context.column()
        val hero = context.column().apply {
            gravity = Gravity.CENTER; minimumHeight = context.dp(320)
            setPadding(context.dp(24), context.dp(32), context.dp(24), context.dp(64))
            addView(ImageView(context).apply {
                setImageResource(R.drawable.glossia_mark); scaleType = ImageView.ScaleType.FIT_CENTER
                importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
            }, LinearLayout.LayoutParams(context.dp(72), context.dp(72)).apply { bottomMargin = context.dp(32) })
            addSpaced(context.heading("Welcome to Glossia", 28f).apply { gravity = Gravity.CENTER })
            addView(context.label("Sign in to access your workspace and\ncollaborate with your team", 14f).apply { gravity = Gravity.CENTER })
        }
        content.addView(hero, LinearLayout.LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT, 1f))
        val panel = context.column().apply {
            setPadding(context.dp(24), context.dp(32), context.dp(24), context.dp(16))
            themed {
                background = GradientDrawable().apply {
                    setColor(context.token(R.color.glossia_login_panel))
                    val radius = context.appearance?.radius(context, "card_radius", 32) ?: context.dp(32).toFloat()
                    cornerRadii = floatArrayOf(radius, radius, radius, radius, 0f, 0f, 0f, 0f)
                    setStroke(context.dp(1), context.token(R.color.glossia_surface))
                }
            }
            addView(progress); addSpaced(errorLabel)
            hostedButton.icon = ContextCompat.getDrawable(context, R.drawable.glossia_mark)
            hostedButton.iconTint = null
            hostedButton.iconSize = context.dp(20)
            hostedButton.iconGravity = MaterialButton.ICON_GRAVITY_TEXT_START
            addView(hostedButton, LinearLayout.LayoutParams(LayoutParams.MATCH_PARENT, context.dp(56)))
            val divider = LinearLayout(context).apply {
                gravity = Gravity.CENTER_VERTICAL; setPadding(0, context.dp(12), 0, context.dp(12))
                importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS
                fun line() = View(context).themed { setBackgroundColor(context.token(R.color.glossia_border)) }
                addView(line(), LinearLayout.LayoutParams(0, context.dp(1), 1f))
                addView(context.label("or", 12f, true).apply { setPadding(context.dp(12), 0, context.dp(12), 0) })
                addView(line(), LinearLayout.LayoutParams(0, context.dp(1), 1f))
            }
            addView(divider)
            selfHostedButton.apply {
                setTag(R.id.appearance_surface, true)
                backgroundTintList = ColorStateList.valueOf(context.token(R.color.glossia_surface))
                strokeWidth = context.dp(1); strokeColor = ColorStateList.valueOf(context.token(R.color.glossia_border))
                setTextColor(context.token(R.color.glossia_text))
                icon = ContextCompat.getDrawable(context, R.drawable.ic_workspace)
                iconTint = ColorStateList.valueOf(context.token(R.color.glossia_muted))
                iconGravity = MaterialButton.ICON_GRAVITY_TEXT_START
            }
            addView(selfHostedButton, LinearLayout.LayoutParams(LayoutParams.MATCH_PARENT, context.dp(56)))
            addView(retryButton); addView(resetButton)
            addView(context.label("Secure sign-in opens in your browser.", 12f, true).apply {
                gravity = Gravity.CENTER; setPadding(0, context.dp(16), 0, 0)
            })
        }
        content.addView(panel)
        addView(context.scroll(content), LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))
        render(false, null)
    }

    fun render(busy: Boolean, error: String?) {
        progress.visibility = if (busy) View.VISIBLE else View.GONE
        errorLabel.text = error; errorLabel.visibility = if (error == null) View.GONE else View.VISIBLE
        retryButton.visibility = errorLabel.visibility; resetButton.visibility = errorLabel.visibility
        listOf(hostedButton, selfHostedButton, retryButton, resetButton).forEach { it.isEnabled = !busy }
    }

    private class Atmosphere(val context: Context) : Drawable() {
        private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        override fun draw(canvas: Canvas) {
            canvas.drawColor(context.token(R.color.glossia_background))
            val width = bounds.width().toFloat(); val height = bounds.height().toFloat()
            paint.shader = RadialGradient(width * 0.9f, height * 0.68f, width * 1.05f,
                context.token(R.color.glossia_atmosphere), Color.TRANSPARENT, Shader.TileMode.CLAMP)
            canvas.drawRect(bounds, paint)
            paint.shader = RadialGradient(width * 0.06f, height * 0.14f, width * 0.8f,
                context.token(R.color.glossia_subtle), Color.TRANSPARENT, Shader.TileMode.CLAMP)
            canvas.drawRect(bounds, paint)
        }
        override fun setAlpha(alpha: Int) { paint.alpha = alpha }
        override fun setColorFilter(colorFilter: ColorFilter?) { paint.colorFilter = colorFilter }
        @Deprecated("Deprecated in Android") override fun getOpacity() = PixelFormat.OPAQUE
    }
}
