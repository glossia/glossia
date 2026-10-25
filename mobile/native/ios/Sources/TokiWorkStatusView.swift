import SwiftUI

// A compact status, not fabricated progress. Expansion explains the observation
// boundary rather than inventing backend steps, percentages or pause controls.
struct TokiWorkStatusView: View {
    let state: TokiActivityAttributes.ContentState
    var refresh: (() -> Void)?
    @Environment(\.glossiaTokens) private var tokens
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var expanded = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let stale = state.phase.active && timeline.date.timeIntervalSince(state.observedAt) >= 60
            let phase: TokiWorkPhase = stale ? .disconnected : state.phase
            VStack(alignment: .leading, spacing: 12) {
                Button { expanded.toggle() } label: {
                    HStack(spacing: 12) {
                        TimelineView(.animation(minimumInterval: 1.0 / 30,
                                                paused: reduceMotion || scenePhase != .active || !phase.active)) { animation in
                            mark(phase, at: animation.date)
                        }.frame(width: 44, height: 44)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(phase == .running ? String(localized: "Toki is thinking…") : phase.label)
                                .font(.callout.weight(.medium)).foregroundStyle(tokens.ink)
                            if state.endedAt == nil || state.endedAt! > state.startedAt.addingTimeInterval(1) {
                                Text(elapsed(at: timeline.date, stale: stale))
                                    .font(.caption.monospacedDigit()).foregroundStyle(tokens.muted)
                            }
                        }
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.down").font(.caption)
                            .rotationEffect(.degrees(expanded ? 180 : 0)).foregroundStyle(tokens.muted)
                    }.contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("toki-work-status")
                .accessibilityValue(expanded ? "Expanded" : "Collapsed")
                .accessibilityHint("Shows when Toki's status was last checked")
                if expanded {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(explanation(phase)).font(.caption).foregroundStyle(tokens.muted)
                        Text("Last checked \(state.observedAt.formatted(date: .omitted, time: .shortened))")
                            .font(.caption).foregroundStyle(tokens.muted)
                        if phase == .disconnected, let refresh {
                            Button("Check status", action: refresh).font(.callout)
                                .accessibilityIdentifier("toki-check-status")
                        }
                    }.padding(.leading, 56)
                }
            }
            .padding(16)
            .background(tokens.surface, in: RoundedRectangle(cornerRadius: tokens.radius))
            .overlay(RoundedRectangle(cornerRadius: tokens.radius).stroke(tokens.subtle, lineWidth: 1))
        }
    }

    private func mark(_ phase: TokiWorkPhase, at date: Date) -> some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                Circle().stroke(tokens.tint.opacity(0.16), lineWidth: 2)
                if phase.active {
                    Circle().trim(from: 0, to: 0.24)
                        .stroke(tokens.tint, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .rotationEffect(.degrees(reduceMotion || scenePhase != .active ? -90 : date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3) * 120))
                }
                TokiSprite(pose: phase == .completed ? "Delighted" : "Focused")
                    .padding(6)
            }.frame(width: 44, height: 44)
            if !phase.active {
                Image(systemName: phase == .completed ? "checkmark.circle.fill" : phase == .failed ? "xmark.circle.fill" : "questionmark.circle.fill")
                    .font(.caption).symbolRenderingMode(.palette)
                    .foregroundStyle(phase == .failed ? tokens.ink : tokens.tint, tokens.surface)
                    .offset(x: 3, y: 3)
            }
        }.accessibilityHidden(true)
    }

    private func elapsed(at date: Date, stale: Bool) -> String {
        let end = state.endedAt ?? min(date, state.observedAt.addingTimeInterval(60))
        let seconds = max(0, Int(end.timeIntervalSince(state.startedAt)))
        let clock = String(format: "%d:%02d", seconds / 60, seconds % 60)
        return stale || state.phase == .disconnected ? String(localized: "\(clock) observed") : String(localized: "\(clock) since observed")
    }

    private func explanation(_ phase: TokiWorkPhase) -> String {
        switch phase {
        case .queued: String(localized: "Your message is queued. Toki hasn't started replying yet.")
        case .running: String(localized: "Toki is preparing a reply. Time is measured from when Glossia first observed this work.")
        case .completed: String(localized: "The server reports that Toki finished this reply.")
        case .failed: String(localized: "Toki couldn't finish this reply. You can send a follow-up to try again.")
        case .disconnected: String(localized: "The latest status isn't available. Work may still be running. Open Glossia and check again.")
        }
    }
}

// The app-owned work remains discoverable after leaving the conversation.
// Open uses the existing conversation navigation, not another URL grammar.
struct TokiWorkOverview: View {
    @ObservedObject var work: TokiWorkController
    let open: (String) -> Void

    private var latest: TokiWorkSnapshot? {
        work.snapshots.values.sorted {
            if $0.state.phase.active != $1.state.phase.active { return $0.state.phase.active }
            return $0.state.observedAt > $1.state.observedAt
        }.first
    }

    var body: some View {
        if let snapshot = latest {
            VStack(alignment: .leading, spacing: 8) {
                TokiWorkStatusView(state: snapshot.state) { open(snapshot.id) }
                Button("Open conversation") { open(snapshot.id) }
                    .font(.callout).accessibilityIdentifier("toki-open-work-conversation")
            }
        }
    }
}
