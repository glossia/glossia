import ActivityKit
import SwiftUI
import UIKit
import WidgetKit

@main
struct GlossiaWidgets: WidgetBundle {
    var body: some Widget { GlossiaActivity() }
}

struct GlossiaActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TokiActivityAttributes.self) { context in
            HStack(spacing: 12) {
                TokiActivityMark(phase: phase(context)).frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 4) {
                    Text(phase(context).label).font(.headline)
                    Text(context.isStale ? String(localized: "Status needs a fresh check") : String(localized: "Toki conversation"))
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                TokiActivityTimer(state: context.state, stale: context.isStale).font(.caption.monospacedDigit())
            }
            .padding(16)
            .activityBackgroundTint(Color(.systemBackground))
            .activitySystemActionForegroundColor(.primary)
            .widgetURL(context.attributes.conversationURL)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    TokiActivityMark(phase: phase(context)).frame(width: 40, height: 40)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TokiActivityTimer(state: context.state, stale: context.isStale)
                        .font(.caption.monospacedDigit())
                        .frame(width: 70, height: 40, alignment: .trailing).padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(phase(context).label).font(.headline)
                        Text(context.isStale ? String(localized: "Open Glossia to check the latest status") : String(localized: "Open conversation"))
                            .font(.caption).foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8).padding(.bottom, 8)
                }
            } compactLeading: {
                TokiActivityMark(phase: phase(context)).frame(width: 24, height: 24)
            } compactTrailing: {
                if context.isStale { Image(systemName: "questionmark.circle") }
                else { TokiActivityTimer(state: context.state, stale: false).font(.caption2.monospacedDigit()).frame(width: 42) }
            } minimal: {
                TokiActivityMark(phase: phase(context)).frame(width: 24, height: 24)
            }
            .widgetURL(context.attributes.conversationURL)
        }
    }

    private func phase(_ context: ActivityViewContext<TokiActivityAttributes>) -> TokiWorkPhase {
        context.isStale && context.state.phase.active ? .disconnected : context.state.phase
    }
}

private struct TokiActivityMark: View {
    let phase: TokiWorkPhase

    // Load the standalone PNG once and keep it below WidgetKit's compact-island
    // archive limit. 132 pixels covers the largest 44-point mark at 3x.
    private static let sprite = UIImage(contentsOfFile: Bundle.main.url(forResource: "TokiFocused", withExtension: "png")!.path)!
        .preparingThumbnail(of: CGSize(width: 132, height: 132))!

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                Circle().stroke(.secondary.opacity(0.3), lineWidth: 2)
                if phase.active {
                    // Widget rendering is system-owned. No continual animation
                    // or background process is needed for this activity mark.
                    Circle().trim(from: 0, to: 0.24).stroke(.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                }
                Image(uiImage: Self.sprite).resizable().scaledToFit().padding(4)
            }
            if !phase.active {
                Image(systemName: phase == .completed ? "checkmark.circle.fill" : phase == .failed ? "xmark.circle.fill" : "questionmark.circle.fill")
                    .font(.caption2).symbolRenderingMode(.palette).foregroundStyle(.primary, .background)
            }
        }.accessibilityLabel(phase.label)
    }
}

private struct TokiActivityTimer: View {
    let state: TokiActivityAttributes.ContentState
    let stale: Bool

    var body: some View {
        if state.phase.active && !stale {
            // The interval stops at the stale boundary even if the OS hasn't
            // scheduled a new render. Never count 'running' indefinitely.
            Text(timerInterval: state.startedAt...max(state.startedAt, state.observedAt.addingTimeInterval(60)), countsDown: false)
                .monospacedDigit().multilineTextAlignment(.trailing)
                .accessibilityLabel("Elapsed since observed")
        } else if let end = state.endedAt {
            let seconds = max(0, Int(end.timeIntervalSince(state.startedAt)))
            Text(String(format: "%d:%02d", seconds / 60, seconds % 60)).monospacedDigit()
        } else {
            Image(systemName: "questionmark.circle").accessibilityLabel("Status needs a fresh check")
        }
    }
}
