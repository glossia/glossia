import AVFoundation
import Combine
import Speech

// Adapted from Tuist AtlasVoiceInput at 9af36c01be (MIT).
@MainActor
protocol TokiVoiceCapturing: AnyObject {
    func start(update: @escaping @MainActor (TokiVoiceUpdate) -> Void) throws
    func stop()
}
enum TokiVoiceUpdate { case level(CGFloat), transcript(String, final: Bool), failed }

@MainActor
final class TokiVoiceInput: ObservableObject {
    enum Phase { case idle, requesting, recording }
    @Published private(set) var phase: Phase = .idle
    @Published private(set) var levels: [CGFloat] = Array(repeating: 0, count: 24)
    @Published private(set) var error: String?
    private var transcript = ""
    private let capture: any TokiVoiceCapturing
    private let permission: () async -> Bool
    private let localize: (String.LocalizationValue) -> String
    private var generation = UUID()
    private var ended = false
    private var completed: ((String) -> Void)?
    private var timeout: Task<Void, Never>?
    var busy: Bool { phase != .idle }
    init(capture: (any TokiVoiceCapturing)? = nil, permission: @escaping () async -> Bool = {
        let speech = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        guard speech == .authorized else { return false }
        return await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { continuation.resume(returning: $0) }
        }
    }, localize: @escaping (String.LocalizationValue) -> String = { String(localized: $0) }) {
        self.capture = capture ?? TokiOnDeviceCapture(); self.permission = permission; self.localize = localize
    }

    func start(completed: ((String) -> Void)? = nil) async {
        guard !busy, !Task.isCancelled else { return }
        self.completed = completed
        generation = UUID(); let ticket = generation
        phase = .requesting; transcript = ""; error = nil; ended = false
        levels = Array(repeating: 0, count: 24)
        let allowed = await permission()
        guard ticket == generation else { return }
        guard allowed, !Task.isCancelled else { fail("Allow microphone and speech recognition in Settings to use on-device dictation."); return }
        do {
            phase = .recording
            try capture.start { [weak self] update in self?.receive(update, ticket: ticket) }
            timeout = Task { [weak self] in
                do { try await Task.sleep(for: .seconds(60)) } catch { return }
                guard self?.generation == ticket else { return }
                self?.fail("Dictation reached its time limit. Your typed draft is unchanged.")
            }
        } catch { fail("On-device dictation is unavailable for this language or device. You can still type.") }
    }
    private func receive(_ update: TokiVoiceUpdate, ticket: UUID) {
        guard generation == ticket, phase == .recording, !ended else { return }
        switch update {
        case .level(let level): levels.removeFirst(); levels.append(level.isFinite ? min(1, max(0, level)) : 0)
        case .transcript(let text, let final):
            transcript = text
            if final { let completed = self.completed; finish { completed?($0) } }
        case .failed: fail("Dictation stopped. Your typed draft is unchanged; try again.")
        }
    }
    func finish(accepted: (String) -> Void) {
        guard phase == .recording else { cancel(); return }
        let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        cancel()
        guard !text.isEmpty else { error = localize("No speech was captured. Your typed draft is unchanged."); return }
        accepted(text)
    }
    func cancel() {
        generation = UUID(); timeout?.cancel(); timeout = nil; capture.stop()
        phase = .idle; transcript = ""; completed = nil; ended = false; levels = Array(repeating: 0, count: 24)
    }
    private func fail(_ message: String.LocalizationValue) { cancel(); error = localize(message) }
    static func appending(_ text: String, to draft: String) -> String {
        draft + (draft.isEmpty || draft.last?.isWhitespace == true ? "" : " ") + text
    }
    nonisolated static func level(_ buffer: AVAudioPCMBuffer) -> CGFloat {
        guard let channels = buffer.floatChannelData, buffer.frameLength > 0, buffer.format.channelCount > 0 else { return 0 }
        var energy = 0.0
        for channel in 0..<Int(buffer.format.channelCount) {
            let samples = buffer.format.isInterleaved ? channels[0] + channel : channels[channel]
            for frame in 0..<Int(buffer.frameLength) {
                let sample = Double(samples[frame * buffer.stride]); if sample.isFinite { energy += sample * sample }
            }
        }
        let mean = energy / Double(Int(buffer.frameLength) * Int(buffer.format.channelCount))
        return mean > 0 ? CGFloat(min(1, max(0, (10 * log10(mean) + 60) / 48))) : 0
    }
}

@MainActor
private final class TokiOnDeviceCapture: TokiVoiceCapturing {
    private let engine = AVAudioEngine()
    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognition: SFSpeechRecognitionTask?
    private var hasTap = false
    private var audioActive = false
    func start(update: @escaping @MainActor (TokiVoiceUpdate) -> Void) throws {
        guard let recognizer = SFSpeechRecognizer(locale: .current), recognizer.isAvailable, recognizer.supportsOnDeviceRecognition else {
            throw GlossiaFailure(kind: "unavailable", message: String(localized: "On-device dictation is unavailable."))
        }
        self.recognizer = recognizer
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = true; request.shouldReportPartialResults = true; request.taskHint = .dictation
        self.request = request
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers); try session.setActive(true); audioActive = true
        let input = engine.inputNode, format = engine.inputNode.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else { throw GlossiaFailure(kind: "unavailable", message: String(localized: "Microphone unavailable.")) }
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer); let level = TokiVoiceInput.level(buffer)
            Task { @MainActor in update(.level(level)) }
        }
        hasTap = true
        recognition = recognizer.recognitionTask(with: request) { result, failure in
            let text = result?.bestTranscription.formattedString, final = result?.isFinal == true, failed = failure != nil
            Task { @MainActor in
                if let text { update(.transcript(text, final: final)) }
                if failed && !final { update(.failed) }
            }
        }
        engine.prepare(); try engine.start()
    }
    func stop() {
        engine.stop(); if hasTap { engine.inputNode.removeTap(onBus: 0); hasTap = false }
        request?.endAudio(); recognition?.cancel(); recognition = nil; request = nil; recognizer = nil
        if audioActive { try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation); audioActive = false }
    }
}
