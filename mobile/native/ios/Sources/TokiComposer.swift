import SwiftUI

// Atlas's final rounded glass composer, adapted for Glossia's text-only API.
struct TokiComposer: View {
    @Binding var draft: String
    let enabled: Bool
    let canSend: Bool
    @ObservedObject var voice: TokiVoiceInput
    let start: () -> Void
    let stop: () -> Void
    let cancel: () -> Void
    let send: () -> Void
    let importText: () -> Void
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.dynamicTypeSize) private var size
    private var recording: Bool { voice.phase != .idle }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let error = voice.error { Text(error).font(.caption).foregroundStyle(.secondary) }
            HStack(alignment: .bottom, spacing: 4) {
                if !recording {
                    Menu {
                        Text("Import a UTF-8 text file into your editable draft. Nothing sends automatically. Image uploads are unavailable.")
                        Button("Photo Library", systemImage: "photo.on.rectangle") {}.disabled(true)
                        Button("Choose Files", systemImage: "doc", action: importText).disabled(!enabled)
                    } label: { utility("plus") }
                    .buttonStyle(.plain).accessibilityLabel("Import text file; images unavailable")
                    .accessibilityIdentifier("thread-attach")
                }
                Group {
                    if voice.phase == .requesting {
                        Text("Waiting for permission…").font(.callout).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    } else if voice.phase == .recording {
                        HStack(spacing: 3) {
                            ForEach(voice.levels.indices, id: \.self) { index in
                                Capsule().fill(.tint).frame(maxWidth: .infinity).frame(height: 4 + voice.levels[index] * 24)
                            }
                        }.frame(height: 44).animation(reduceMotion ? nil : .linear(duration: 0.05), value: voice.levels)
                            .accessibilityElement(children: .ignore).accessibilityLabel("Recording on this device")
                    } else {
                        TextField("Message Toki…", text: $draft, axis: .vertical)
                            .lineLimit(1...(size.isAccessibilitySize ? 3 : 6)).textFieldStyle(.plain)
                            .padding(.vertical, 11).disabled(!enabled).accessibilityIdentifier("toki-composer")
                    }
                }.padding(.leading, recording ? 52 : 0).padding(.trailing, recording ? 8 : 44)
                if recording {
                    Button(action: cancel) { utility("xmark") }.buttonStyle(.plain)
                        .accessibilityLabel("Discard dictation").accessibilityIdentifier("thread-voice-cancel")
                } else {
                    Button(action: send) { Image(systemName: "arrow.up").font(.system(size: 20, weight: .bold)).frame(width: 44, height: 44) }
                        .buttonStyle(TokiComposerSendStyle()).disabled(!canSend)
                        .accessibilityLabel("Send message").accessibilityIdentifier("thread-send")
                }
            }
            .overlay(alignment: recording ? .bottomLeading : .bottomTrailing) {
                ZStack {
                    Circle().fill(recording ? Color.red.opacity(0.1) : Color(uiColor: .tertiarySystemFill)).padding(4)
                    Image(systemName: recording ? "stop.fill" : "mic.fill").font(.system(size: 18, weight: .medium))
                        .foregroundStyle(recording ? Color.red : Color.secondary)
                    TokiMicrophoneTarget(active: recording, enabled: enabled || recording, start: start, stop: stop, cancel: cancel)
                }.frame(width: 44, height: 44).padding(.trailing, recording ? 0 : 48)
            }
            .padding(4).foregroundStyle(.primary).background { surface }
        }
        .frame(maxWidth: 688).padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 10).frame(maxWidth: .infinity)
    }
    private func utility(_ symbol: String) -> some View {
        Image(systemName: symbol).font(.system(size: 20)).frame(width: 44, height: 44).foregroundStyle(.secondary)
            .background { Circle().fill(Color(uiColor: .tertiarySystemFill)).padding(4) }
    }
    @ViewBuilder private var surface: some View {
        let shape = RoundedRectangle(cornerRadius: 28)
        if reduceTransparency || contrast == .increased {
            shape.fill(Color(uiColor: .secondarySystemBackground)).overlay { shape.strokeBorder(Color(uiColor: .separator), lineWidth: 1) }
        } else if #available(iOS 26.0, *) { shape.fill(.clear).glassEffect(.regular, in: shape) }
        else { shape.fill(.regularMaterial) }
    }
}

private struct TokiComposerSendStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    @Environment(\.glossiaTokens) private var tokens
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.foregroundStyle(tokens.onAccent).background { Circle().fill(.tint).padding(4) }
            .contentShape(Rectangle()).opacity(enabled ? (configuration.isPressed ? 0.7 : 1) : 0.3)
    }
}

enum TokiTextImport {
    static let maxBytes = 16_384
    static func appending(_ data: Data, to draft: String) throws -> String {
        guard data.count <= maxBytes else { throw GlossiaFailure(kind: "invalid_input", message: String(localized: "Choose a UTF-8 text file no larger than 16 KB.")) }
        guard var text = String(data: data, encoding: .utf8) else {
            throw GlossiaFailure(kind: "invalid_input", message: String(localized: "Choose a UTF-8 text file. Binary files and images are unsupported."))
        }
        if text.first == "\u{FEFF}" { text.removeFirst() }
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              text.unicodeScalars.allSatisfy({ $0.value >= 32 || [9, 10, 13].contains($0.value) }) else {
            throw GlossiaFailure(kind: "invalid_input", message: String(localized: "Choose a non-empty UTF-8 text file. Binary files and images are unsupported."))
        }
        let result = draft + (draft.isEmpty || draft.last == "\n" ? "" : "\n") + text
        guard result.unicodeScalars.count <= 4000 else {
            throw GlossiaFailure(kind: "invalid_input", message: String(localized: "The imported text and draft must fit within 4,000 characters. Your draft is unchanged."))
        }
        return result
    }
}

private struct TokiMicrophoneTarget: UIViewRepresentable {
    let active: Bool
    let enabled: Bool
    let start: () -> Void
    let stop: () -> Void
    let cancel: () -> Void
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .custom)
        button.addTarget(context.coordinator, action: #selector(Coordinator.tap), for: .touchUpInside)
        let hold = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.hold))
        hold.minimumPressDuration = 0.5; hold.allowableMovement = 60; hold.cancelsTouchesInView = true
        button.addGestureRecognizer(hold); updateUIView(button, context: context); return button
    }
    func updateUIView(_ button: UIButton, context: Context) {
        context.coordinator.parent = self
        if button.isEnabled != enabled { button.isEnabled = enabled; button.gestureRecognizers?.forEach { $0.isEnabled = enabled } }
        button.accessibilityLabel = active ? String(localized: "Stop dictation") : String(localized: "Transcribe a voice message")
        button.accessibilityHint = String(localized: "Tap to start or stop, or hold and release to add editable text. Nothing sends automatically.")
        button.accessibilityIdentifier = "thread-microphone"
    }
    final class Coordinator: NSObject {
        var parent: TokiMicrophoneTarget
        private var holding = false
        init(_ parent: TokiMicrophoneTarget) { self.parent = parent }
        @objc func tap() { guard parent.enabled else { return }; if parent.active { parent.stop() } else { parent.start() } }
        @objc func hold(_ recognizer: UILongPressGestureRecognizer) {
            switch recognizer.state {
            case .began:
                guard parent.enabled else { return }
                if parent.active { parent.stop(); return }; holding = true; parent.start()
            case .ended, .cancelled, .failed:
                guard holding else { return }; holding = false
                if recognizer.state == .ended { parent.stop() } else { parent.cancel() }
            default: break
            }
        }
    }
}
