package ai.glossia.mobile

import android.app.Application
import android.content.res.Configuration
import android.os.Looper
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import java.util.Locale

internal class TestTokiVoiceCapture : TokiVoiceCapture {
    override var supported = true
    var level: ((Float) -> Unit)? = null
    var transcript: ((String, Boolean) -> Unit)? = null
    var failed: (() -> Unit)? = null
    var starts = 0
    var stops = 0
    override fun start(level: (Float) -> Unit, transcript: (String, Boolean) -> Unit, failed: () -> Unit) {
        starts += 1; this.level = level; this.transcript = transcript; this.failed = failed
    }
    override fun cancel() { stops += 1 }
}

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35], application = Application::class)
class TokiInputTest {
    @Test fun dictationUsesMeasuredRmsReturnsEditableTextAndFencesCancelledCallbacks() {
        val capture = TestTokiVoiceCapture()
        var permission = 0; var accepted = "draft"
        val voice = TokiVoiceInput(capture, { false }, { permission = it }, { accepted += " $it" }, {})
        voice.start(); assertEquals(TokiVoiceInput.Phase.REQUESTING, voice.phase)
        voice.cancel(); voice.permissionResult(permission, true); assertEquals(0, capture.starts)
        voice.start(); voice.permissionResult(permission, true); assertEquals(TokiVoiceInput.Phase.RECORDING, voice.phase)
        capture.level!!(7f); assertEquals(0.75f, voice.levels.last(), 0.001f)
        capture.transcript!!("مرحبا", false); assertEquals("draft", accepted)
        voice.finish(); assertEquals("draft مرحبا", accepted); assertFalse(voice.busy)
        capture.transcript!!("late", true); capture.failed!!(); assertEquals("draft مرحبا", accepted); assertNull(voice.error)
        voice.start(); voice.permissionResult(permission, true)
        capture.transcript!!("שלום", true); assertEquals("draft مرحبا שלום", accepted); assertFalse(voice.busy)
        voice.start(); voice.permissionResult(permission, false); assertNotNull(voice.error); assertFalse(voice.busy)
        capture.supported = false; voice.start(); assertFalse(voice.busy); assertEquals(2, capture.starts)
        shadowOf(Looper.getMainLooper()).idle()
    }

    @Test fun strictBoundedTextImportAppendsWithoutSendingAndRejectsInvalidFiles() {
        assertEquals("draft\nمرحبا", TokiTextImport.append("مرحبا".toByteArray(), "draft"))
        for (bytes in listOf(byteArrayOf(0xff.toByte(), 0xfe.toByte()), byteArrayOf(0, 1), ByteArray(16_385))) {
            assertThrows(IllegalArgumentException::class.java) { TokiTextImport.append(bytes, "unchanged") }
        }
        assertThrows(IllegalArgumentException::class.java) { TokiTextImport.append("hello".toByteArray(), "字".repeat(4000)) }
    }

    @Test fun staticButtonModelErrorAndFormatArgumentsUseRuntimeResources() {
        val sentinel = System.getProperty("nativeLocalizationSentinel") == "true"
        val context = RuntimeEnvironment.getApplication().createConfigurationContext(Configuration().apply { setLocale(Locale(if (sentinel) "de" else "en")) })
        assertEquals(if (sentinel) "Dateien wählen SENTINEL" else "Choose Files", context.nativeText("Choose Files"))
        val capture = TestTokiVoiceCapture()
        var ticket = 0
        val voice = TokiVoiceInput(capture, { false }, { ticket = it }, {}, {}, { context.nativeText(it).toString() })
        voice.start(); voice.permissionResult(ticket, false)
        assertEquals(if (sentinel) "Mikrofon SENTINEL erlauben" else "Allow microphone access in Android Settings to use on-device dictation.", voice.error)
        assertEquals(if (sentinel) "Zeichen SENTINEL: 4001" else "Use at most 4,000 characters (4001).", context.nativeFormat("Use at most 4,000 characters (%1\$s).", 4001))
    }
}
