package ai.glossia.mobile

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.animation.ValueAnimator
import android.content.Context
import android.database.ContentObserver
import android.graphics.Canvas
import android.graphics.Rect
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.provider.Settings
import android.view.View
import android.view.ViewTreeObserver
import android.view.accessibility.AccessibilityNodeInfo
import android.view.animation.LinearInterpolator
import androidx.core.view.ViewCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.findViewTreeLifecycleOwner

/** A local presentation rig. Greeting Toki never edits a draft or calls the session. */
class TokiCompanionView(context: Context) : View(context) {
    private data class Pose(val right: Float = 0f, val left: Float = 0f,
        val tilt: Float = 0f, val drop: Float = 0f) {
        fun towards(other: Pose, fraction: Float): Pose {
            val t = fraction * fraction * (3 - 2 * fraction)
            fun mix(a: Float, b: Float) = a + (b - a) * t
            return Pose(mix(right, other.right), mix(left, other.left), mix(tilt, other.tilt), mix(drop, other.drop))
        }
    }

    // All three transparent textures occupy the same 512 x 512 canvas.
    private val body = context.getDrawable(R.drawable.toki_body)!!.mutate()
    private val leftArm = context.getDrawable(R.drawable.toki_left_arm)!!.mutate()
    private val rightArm = context.getDrawable(R.drawable.toki_right_arm)!!.mutate()
    private val wave = context.getDrawable(R.drawable.toki_wave)!!.mutate()
    private val delighted = context.getDrawable(R.drawable.toki_delighted)!!.mutate()
    private var pose = Pose()
    private var animator: ValueAnimator? = null
    private var lifecycle: Lifecycle? = null
    private var greeting = false
    private var alternate = false
    private var staticReaction = false
    private var deadline = 0L
    private var observing = false
    private var windowVisible = false
    private val visibleBounds = Rect()
    private val settle = Runnable { stopGreeting() }
    private val visibilityChanged = ViewTreeObserver.OnScrollChangedListener { checkVisibility() }
    private val layoutChanged = ViewTreeObserver.OnGlobalLayoutListener { checkVisibility() }
    private val lifecycleChanged = LifecycleEventObserver { _, _ -> checkVisibility() }
    private val motionChanged = object : ContentObserver(Handler(Looper.getMainLooper())) {
        override fun onChange(selfChange: Boolean) {
            if (greeting && !motionEnabled()) {
                cancelAnimator()
                pose = Pose()
                staticReaction = true
                invalidate()
            }
        }
    }

    init {
        isClickable = true; isFocusable = true
        contentDescription = "Toki"
        minimumWidth = context.dp(48); minimumHeight = context.dp(48)
        importantForAccessibility = IMPORTANT_FOR_ACCESSIBILITY_YES
        ViewCompat.setStateDescription(this, "Ready to help")
        val attributes = context.obtainStyledAttributes(intArrayOf(android.R.attr.selectableItemBackgroundBorderless))
        background = attributes.getDrawable(0)
        attributes.recycle()
        listOf(body, leftArm, rightArm, wave, delighted).forEach { it.setBounds(0, 0, 512, 512) }
    }

    override fun onInitializeAccessibilityNodeInfo(info: AccessibilityNodeInfo) {
        super.onInitializeAccessibilityNodeInfo(info)
        info.className = "android.widget.Button"
        info.hintText = "Say hello to Toki"
        info.addAction(AccessibilityNodeInfo.AccessibilityAction(AccessibilityNodeInfo.ACTION_CLICK, "Say hello"))
    }

    override fun performClick(): Boolean {
        if (!isEnabled || !canPresent()) return false
        super.performClick()
        // Keep the rendered pose on a repeated tap, rather than restarting at rest.
        val initial = pose
        cancelAnimator()
        removeCallbacks(settle)
        greeting = true
        alternate = !alternate
        deadline = SystemClock.uptimeMillis() + DURATION
        staticReaction = !motionEnabled()
        ViewCompat.setStateDescription(this, if (alternate) "Waving hello" else "Happy to see you")
        if (staticReaction) {
            pose = Pose()
        } else {
            animator = ValueAnimator.ofFloat(0f, 1f).apply {
                duration = DURATION
                interpolator = LinearInterpolator()
                addUpdateListener {
                    if (!canPresent()) stopGreeting() else {
                        pose = greetingPose(it.animatedFraction * 2.4f, initial)
                        invalidate()
                    }
                }
                addListener(object : AnimatorListenerAdapter() {
                    override fun onAnimationEnd(animation: Animator) { stopGreeting() }
                })
                start()
            }
        }
        // Also bounds the static, reduced-motion greeting. This is one delayed
        // settlement, not a frame loop, and is removed whenever we leave screen.
        postDelayed(settle, (deadline - SystemClock.uptimeMillis()).coerceAtLeast(0))
        invalidate()
        return true
    }

    private fun greetingPose(elapsed: Float, initial: Pose): Pose {
        val frames = arrayOf(
            0f to initial,
            .16f to Pose(-30f, 3f, -1f, 3f),
            .46f to Pose(-115f, 8f, 1.8f, 0f),
            .70f to Pose(-96f, 7f, 1f, .8f),
            .94f to Pose(-122f, 8f, 1.2f, 1.8f),
            1.18f to Pose(-98f, 6f, .5f, .8f),
            1.42f to Pose(-116f, 5f, .2f, 0f),
            1.80f to Pose(-32f, 2f, -.8f, 1f),
            2.10f to Pose(3f, -1f, .4f, .3f),
            2.4f to Pose()
        )
        for (index in 1 until frames.size) {
            val (end, target) = frames[index]
            if (elapsed <= end) {
                val (start, previous) = frames[index - 1]
                return previous.towards(target, ((elapsed - start) / (end - start)).coerceIn(0f, 1f))
            }
        }
        return Pose()
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val size = minOf(width - paddingLeft - paddingRight, height - paddingTop - paddingBottom).toFloat()
        if (size <= 0) return
        val saved = canvas.save()
        canvas.translate((width - size) / 2, (height - size) / 2)
        canvas.scale(size / 512, size / 512)
        if (staticReaction && greeting) {
            (if (alternate) wave else delighted).draw(canvas)
        } else {
            canvas.translate(0f, pose.drop)
            canvas.rotate(pose.tilt, 256f, 300f)
            val left = canvas.save()
            canvas.rotate(pose.left, 137f, 250f)
            leftArm.draw(canvas)
            canvas.restoreToCount(left)
            val right = canvas.save()
            canvas.rotate(pose.right, 375f, 250f)
            rightArm.draw(canvas)
            canvas.restoreToCount(right)
            body.draw(canvas)
        }
        canvas.restoreToCount(saved)
    }

    private fun motionEnabled() = ValueAnimator.areAnimatorsEnabled() &&
        Settings.Global.getFloat(context.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) > 0f

    private fun canPresent() = isAttachedToWindow && isShown && windowVisible &&
        lifecycle?.currentState?.isAtLeast(Lifecycle.State.RESUMED) != false && getGlobalVisibleRect(visibleBounds)

    private fun checkVisibility() { if (greeting && !canPresent()) stopGreeting() }

    private fun cancelAnimator() {
        animator?.removeAllListeners()
        animator?.removeAllUpdateListeners()
        animator?.cancel()
        animator = null
    }

    private fun stopGreeting() {
        cancelAnimator()
        removeCallbacks(settle)
        greeting = false; staticReaction = false; pose = Pose()
        ViewCompat.setStateDescription(this, "Ready to help")
        invalidate()
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        lifecycle = findViewTreeLifecycleOwner()?.lifecycle
        lifecycle?.addObserver(lifecycleChanged)
        context.contentResolver.registerContentObserver(Settings.Global.getUriFor(Settings.Global.ANIMATOR_DURATION_SCALE), false, motionChanged)
        observing = true
        viewTreeObserver.addOnScrollChangedListener(visibilityChanged)
        viewTreeObserver.addOnGlobalLayoutListener(layoutChanged)
    }

    override fun onDetachedFromWindow() {
        stopGreeting()
        lifecycle?.removeObserver(lifecycleChanged); lifecycle = null
        if (observing) context.contentResolver.unregisterContentObserver(motionChanged)
        observing = false
        if (viewTreeObserver.isAlive) {
            viewTreeObserver.removeOnScrollChangedListener(visibilityChanged)
            viewTreeObserver.removeOnGlobalLayoutListener(layoutChanged)
        }
        super.onDetachedFromWindow()
    }

    override fun onWindowVisibilityChanged(visibility: Int) {
        super.onWindowVisibilityChanged(visibility)
        windowVisible = visibility == VISIBLE
        checkVisibility()
    }

    override fun onVisibilityChanged(changedView: View, visibility: Int) {
        super.onVisibilityChanged(changedView, visibility)
        // View's constructor can call this before our fields are initialized.
        if (visibility != VISIBLE && greeting) stopGreeting()
    }

    private companion object { const val DURATION = 2400L }
}
