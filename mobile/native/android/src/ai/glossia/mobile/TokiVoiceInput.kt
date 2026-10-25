package ai.glossia.mobile

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import androidx.core.content.ContextCompat
import java.util.Locale

internal interface TokiVoiceCapture {
    val supported: Boolean
    fun start(level: (Float) -> Unit, transcript: (String, Boolean) -> Unit, failed: () -> Unit)
    fun cancel()
}

// All recognizer calls and callbacks are main-thread owned. No audio or transcript
// is uploaded by Glossia, persisted, sent to Toki, or restored from view state.
internal class TokiVoiceInput(
    private val capture: TokiVoiceCapture,
    private val allowed: () -> Boolean,
    private val askPermission: (Int) -> Unit,
    private val accepted: (String) -> Unit,
    private val changed: () -> Unit,
    private val localize: (String) -> String = { it },
) {
    enum class Phase { IDLE, REQUESTING, RECORDING }
    var phase = Phase.IDLE; private set
    var error: String? = null; private set
    val supported get() = capture.supported
    val busy get() = phase != Phase.IDLE
    val levels = MutableList(24) { 0f }
    private var generation = 0
    private var text = ""
    private val main = Handler(Looper.getMainLooper())
    private var timeout: Runnable? = null

    fun start() {
        if (busy) return
        if (!supported) { error = localize("On-device dictation is unavailable on this device. You can still type."); changed(); return }
        val ticket = ++generation
        error = null; text = ""; levels.indices.forEach { levels[it] = 0f }; phase = Phase.REQUESTING; changed()
        if (allowed()) permissionResult(ticket, true) else askPermission(ticket)
    }

    fun permissionResult(ticket: Int, granted: Boolean) {
        if (ticket != generation || phase != Phase.REQUESTING) return
        if (!granted) { fail("Allow microphone access in Android Settings to use on-device dictation."); return }
        phase = Phase.RECORDING
        try {
            capture.start({ rms ->
                if (ticket == generation && phase == Phase.RECORDING) {
                    levels.removeAt(0); levels.add(if (rms.isFinite()) ((rms + 2f) / 12f).coerceIn(0f, 1f) else 0f); changed()
                }
            }, { value, final ->
                if (ticket == generation && phase == Phase.RECORDING) {
                    text = value
                    if (final) finish()
                }
            }, { if (ticket == generation) fail("Dictation stopped. Your typed draft is unchanged; try again.") })
            if (ticket == generation && busy) {
                timeout = Runnable { if (ticket == generation) fail("Dictation reached its time limit. Your typed draft is unchanged.") }.also { main.postDelayed(it, 60_000) }
            }
            changed()
        } catch (_: Exception) { if (ticket == generation) fail("On-device dictation is unavailable for this language or device. You can still type.") }
    }

    fun finish() {
        val value = text.trim()
        val recording = phase == Phase.RECORDING
        cancel()
        if (!recording) return
        if (value.isEmpty()) { error = localize("No speech was captured. Your typed draft is unchanged."); changed() }
        else accepted(value)
    }

    fun cancel() {
        generation += 1; timeout?.let(main::removeCallbacks); timeout = null
        phase = Phase.IDLE; text = ""; levels.indices.forEach { levels[it] = 0f }
        capture.cancel(); changed()
    }
    private fun fail(message: String) { cancel(); error = localize(message); changed() }
}

internal class AndroidTokiVoiceCapture(private val context: Context) : TokiVoiceCapture {
    private var recognizer: SpeechRecognizer? = null
    override val supported get() = Build.VERSION.SDK_INT >= 31 && SpeechRecognizer.isOnDeviceRecognitionAvailable(context)
    override fun start(level: (Float) -> Unit, transcript: (String, Boolean) -> Unit, failed: () -> Unit) {
        if (Build.VERSION.SDK_INT < 31 || !supported) { failed(); return }
        val recognizer = SpeechRecognizer.createOnDeviceSpeechRecognizer(context)
        this.recognizer = recognizer
        recognizer.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) = Unit
            override fun onBeginningOfSpeech() = Unit
            override fun onRmsChanged(rmsdB: Float) { level(rmsdB) }
            override fun onBufferReceived(buffer: ByteArray?) = Unit
            override fun onEndOfSpeech() = Unit
            override fun onError(error: Int) { failed() }
            override fun onResults(results: Bundle?) { results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()?.let { transcript(it, true) } ?: failed() }
            override fun onPartialResults(partialResults: Bundle?) { partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()?.let { transcript(it, false) } }
            override fun onEvent(eventType: Int, params: Bundle?) = Unit
        })
        recognizer.startListening(Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault().toLanguageTag())
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
        })
    }
    override fun cancel() { recognizer?.let { recognizer = null; it.cancel(); it.destroy() } }
}

internal fun Context.microphoneAllowed() = ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
