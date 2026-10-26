package ai.glossia.mobile

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.os.Build
import androidx.core.content.ContextCompat
import androidx.core.content.edit
import androidx.core.graphics.createBitmap
import androidx.core.net.toUri
import java.util.Locale

// A native, last-observed status surface, not a background worker. The OS owns
// its timer; no service, inference, wake lock, socket or background poll is added.
internal class TokiNotifications(private val context: Context,
    private val color: () -> Int,
    private val canonicalLink: (String, (String?) -> Unit) -> Unit) {
    private val manager = context.getSystemService(NotificationManager::class.java)
    private val preferences = context.getSharedPreferences("glossia.notifications", Context.MODE_PRIVATE)
    private val entries = mutableMapOf<String, Entry>()
    private var observing: String? = null
    private var permissionCandidate = false

    private class Entry(val id: String, val turnId: String, var status: String, val observedAt: Long) {
        var endedAt: Long? = null
        var url: String? = null
        var fingerprint: String? = null
        var uncertain = false
    }

    init {
        manager.createNotificationChannel(NotificationChannel(CHANNEL, context.nativeText("Toki activity"), NotificationManager.IMPORTANCE_LOW).apply {
            description = context.nativeText("Last observed Toki work. Open Glossia to refresh when the app is not active.").toString()
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            setShowBadge(false)
        })
        // Never leave a previous process's status pretending to be current.
        clear()
    }

    fun update(threads: Collection<ConversationModel>, observedId: String?) {
        observing = observedId
        val accessible = threads.filter { it.created && !it.unavailable && it.workTurnId != null }.associateBy { it.id }
        entries.keys.filter { it !in accessible }.toList().forEach(::remove)
        accessible.values.forEach { thread ->
            var entry = entries[thread.id]
            val turnId = thread.workTurnId ?: return@forEach
            val status = thread.workStatus ?: return@forEach
            val running = status in listOf("queued", "running")
            if (entry == null || entry.turnId != turnId) {
                entry = Entry(thread.id, turnId, status, System.currentTimeMillis())
                entries[thread.id] = entry
                val pending = entry
                canonicalLink(thread.id) { url ->
                    if (entries[thread.id] === pending) {
                        pending.url = url
                        publish(pending)
                    }
                }
            }
            if (running && entry.endedAt != null) return@forEach
            entry.status = status
            entry.uncertain = thread.error != null || !thread.workObservationCurrent
            if (!running && status in listOf("completed", "failed") && entry.endedAt == null) {
                entry.endedAt = System.currentTimeMillis()
            }
            publish(entry)
        }
        permissionCandidate = entries.values.any { it.status in listOf("queued", "running") }
    }

    fun takePermissionRequest(): Boolean {
        if (Build.VERSION.SDK_INT < 33 || !permissionCandidate || hasPermission() || preferences.getBoolean("asked", false)) return false
        preferences.edit { putBoolean("asked", true) }
        return true // Ask once, in context. Denial never blocks sending or reading.
    }

    private fun hasPermission() = Build.VERSION.SDK_INT < 33 || ContextCompat.checkSelfPermission(context,
        Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED

    private fun allowed() = hasPermission() && manager.areNotificationsEnabled()

    private fun publish(entry: Entry) {
        val url = entry.url ?: return
        if (!allowed()) { manager.cancel(tag(entry.id), ID); entry.fingerprint = null; return }
        val active = entry.status in listOf("queued", "running")
        val current = active && observing == entry.id && !entry.uncertain
        val fingerprint = "${entry.status}:$current:${entry.uncertain}:${color()}"
        if (entry.fingerprint == fingerprint) return
        val text = when (entry.status) {
            "queued" -> "Queued"
            "running" -> "Working"
            "completed" -> "Completed"
            "failed" -> "Failed"
            else -> { remove(entry.id); return }
        }
        val intent = Intent(context, MainActivity::class.java).setAction(Intent.ACTION_VIEW).setData(url.toUri())
            .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        val pending = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val description = if (active && !current) context.nativeFormat("Last known: %1\$s. Open Glossia to refresh.", context.nativeText(text))
            else if (entry.status == "completed") context.nativeText("Your response is ready. Open the conversation.").toString()
            else if (entry.status == "failed") context.nativeText("Toki could not finish. Open the conversation.").toString()
            else context.nativeFormat("Last observed: %1\$s", context.nativeText(text))
        val elapsed = ((entry.endedAt ?: System.currentTimeMillis()) - entry.observedAt).coerceAtLeast(0) / 1000
        val clock = String.format(Locale.ROOT, "%d:%02d", elapsed / 60, elapsed % 60)
        // Even unlocked content is generic: no title, prompt, model output,
        // workspace name or error detail can leak onto a lockscreen.
        val public = Notification.Builder(context, CHANNEL).setSmallIcon(R.drawable.ic_toki)
            .setContentTitle(context.nativeText("Toki activity")).setContentText(context.nativeText("Open Glossia to view the latest status."))
            .setVisibility(Notification.VISIBILITY_PUBLIC).setContentIntent(pending).build()
        val notification = Notification.Builder(context, CHANNEL).setSmallIcon(R.drawable.ic_toki)
            .setLargeIcon(mark(current)).setColor(color())
            .setContentTitle(context.nativeFormat("Toki · %1\$s", context.nativeText(text))).setContentText(description)
            .setStyle(Notification.BigTextStyle().bigText(description))
            .setSubText(if (current) context.nativeText("Observed") else context.nativeFormat("Observed for %1\$s", clock))
            .setWhen(entry.observedAt).setShowWhen(current).setUsesChronometer(current)
            .setOnlyAlertOnce(true).setOngoing(active).setAutoCancel(!active)
            .setCategory(if (active) Notification.CATEGORY_PROGRESS else Notification.CATEGORY_STATUS)
            .setVisibility(Notification.VISIBILITY_PRIVATE).setPublicVersion(public).setContentIntent(pending)
            .apply { if (!active) setTimeoutAfter(COMPLETION_TIMEOUT_MS) }.build()
        try {
            manager.notify(tag(entry.id), ID, notification)
            entry.fingerprint = fingerprint
        } catch (_: SecurityException) {
            entry.fingerprint = null // Revocation between checking and posting is harmless.
        }
    }

    private fun mark(current: Boolean): Bitmap {
        val size = context.dp(64)
        val bitmap = createBitmap(size, size)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = color(); style = Paint.Style.STROKE; strokeWidth = context.dp(2).toFloat() }
        val inset = context.dp(3).toFloat()
        val ring = RectF(inset, inset, size - inset, size - inset)
        if (current) canvas.drawArc(ring, -90f, 270f, false, paint) else canvas.drawOval(ring, paint)
        val mascot = BitmapFactory.decodeResource(context.resources, R.drawable.toki_body)
        val padding = context.dp(8).toFloat()
        canvas.drawBitmap(mascot, null, RectF(padding, padding, size - padding, size - padding), null)
        mascot.recycle()
        return bitmap
    }

    private fun tag(id: String) = "$PREFIX$id"
    private fun remove(id: String) { entries.remove(id); manager.cancel(tag(id), ID) }

    fun clear() {
        entries.clear(); observing = null; permissionCandidate = false
        manager.activeNotifications.filter { it.tag?.startsWith(PREFIX) == true }.forEach { manager.cancel(it.tag, it.id) }
    }

    companion object {
        private const val CHANNEL = "toki_activity"
        private const val PREFIX = "glossia.toki."
        private const val ID = 1
        private const val COMPLETION_TIMEOUT_MS = 60 * 60 * 1000L
    }
}
