package ai.glossia.mobile

import java.nio.ByteBuffer
import java.nio.charset.CodingErrorAction

internal object TokiTextImport {
    const val MAX_BYTES = 16_384
    fun append(bytes: ByteArray, draft: String, localize: (String) -> String = { it }): String {
        require(bytes.size <= MAX_BYTES) { localize("Choose a UTF-8 text file no larger than 16 KB.") }
        val text = try {
            Charsets.UTF_8.newDecoder().onMalformedInput(CodingErrorAction.REPORT).onUnmappableCharacter(CodingErrorAction.REPORT)
                .decode(ByteBuffer.wrap(bytes)).toString().removePrefix("\uFEFF")
        } catch (_: Exception) { throw IllegalArgumentException(localize("Choose a UTF-8 text file. Binary files and images are unsupported.")) }
        require(text.isNotBlank() && text.none { it.code < 32 && it !in "\t\n\r" }) { localize("Choose a non-empty UTF-8 text file. Binary files and images are unsupported.") }
        val result = draft + (if (draft.isEmpty() || draft.last() == '\n') "" else "\n") + text
        require(result.codePointCount(0, result.length) <= 4000) { localize("The imported text and draft must fit within 4,000 characters. Your draft is unchanged.") }
        return result
    }
}
