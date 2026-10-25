package ai.glossia.mobile

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.view.View

// No timer or decorative animation: every height comes from SpeechRecognizer RMS.
internal class TokiWaveformView(context: Context) : View(context) {
    var levels: List<Float> = emptyList()
        set(value) { field = value; invalidate() }
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    init { contentDescription = context.nativeText("Recording on this device") }
    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        paint.color = context.token(R.color.glossia_primary)
        val step = width.toFloat() / levels.size.coerceAtLeast(1)
        levels.forEachIndexed { index, level ->
            val bar = context.dp(4) + context.dp(24) * level.coerceIn(0f, 1f)
            val position = if (layoutDirection == LAYOUT_DIRECTION_RTL) levels.lastIndex - index else index
            val left = position * step + context.dp(1)
            canvas.drawRoundRect(left, (height - bar) / 2, left + (step - context.dp(2)).coerceAtLeast(1f), (height + bar) / 2, context.dp(2).toFloat(), context.dp(2).toFloat(), paint)
        }
    }
}
