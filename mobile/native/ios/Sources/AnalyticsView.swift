import SwiftUI

@MainActor
final class AnalyticsModel: ObservableObject {
    @Published var value: [String: Any]?
    @Published var days = 30
    @Published var busy = false
    @Published var error: String?
    private let request: GlossiaRequest
    private var sequence = 0

    init(request: @escaping GlossiaRequest) { self.request = request }

    func load() async {
        sequence += 1
        let ticket = sequence
        busy = true; error = nil; value = nil
        defer { if ticket == sequence { busy = false } }
        do {
            let result = try await request(["operation": "resource", "resource": "analytics", "days": days])
            try Task.checkCancellation()
            if ticket == sequence { value = result }
        } catch is CancellationError { }
        catch { if ticket == sequence { self.error = error.localizedDescription } }
    }
}

struct AnalyticsView: View {
    @StateObject private var model: AnalyticsModel
    @Environment(\.glossiaTokens) private var tokens
    let hasProject: Bool

    init(request: @escaping GlossiaRequest, hasProject: Bool) {
        _model = StateObject(wrappedValue: AnalyticsModel(request: request))
        self.hasProject = hasProject
    }

    var body: some View {
        List {
            if !hasProject {
                ContentUnavailableView("Choose a project", systemImage: "folder")
            } else {
                Picker("Period", selection: $model.days) {
                    Text("7 days").tag(7); Text("30 days").tag(30); Text("90 days").tag(90)
                }.pickerStyle(.segmented).listRowBackground(Color.clear)
                if model.busy { ProgressView("Loading analytics…") }
                if let error = model.error { GlossiaErrorView(message: error) { Task { await model.load() } } }
                if let value = model.value, let summary = value["summary"] as? [String: Any] {
                    Section("Audience · last \(model.days) days") {
                        metric("Pageviews", value: summary["pageviews"])
                        metric("Unique visitors", value: summary["unique_visitors"])
                        metric("Visits with a language gap", value: summary["locale_gap_visits"])
                    }.listRowBackground(tokens.surface)
                    if summary["pageviews"] as? Int == 0 {
                        VStack(spacing: 12) {
                            TokiSprite(pose: "Globe").frame(height: 144)
                            Text("Meet your global audience").font(.headline)
                            Text("No visits in this period. Install the Glossia tracker on your website to start learning where your readers are.")
                                .font(.callout).foregroundStyle(tokens.muted).multilineTextAlignment(.center)
                        }.frame(maxWidth: .infinity).padding(.vertical, 16).listRowBackground(Color.clear)
                    }
                    Section("Around the world") {
                        LabeledContent("Top country", value: nonempty(summary["top_country"]))
                        LabeledContent("Top browser language", value: nonempty(summary["top_browser_language"]))
                    }.listRowBackground(tokens.surface)
                    if let pages = value["top_pages"] as? [[String: Any]], !pages.isEmpty {
                        Section("Top pages") {
                            ForEach(pages.indices, id: \.self) { index in
                                LabeledContent(pages[index]["pathname"] as? String ?? "/",
                                               value: String(pages[index]["pageviews"] as? Int ?? 0))
                            }
                        }.listRowBackground(tokens.surface)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden).background(tokens.canvas)
        .task(id: model.days) { if hasProject { await model.load() } }
        .refreshable { if hasProject { await model.load() } }
    }

    private func nonempty(_ value: Any?) -> String {
        guard let text = value as? String, !text.isEmpty else { return "Not available" }
        return text
    }

    private func metric(_ title: String, value: Any?) -> some View {
        LabeledContent(title) { Text((value as? Int ?? 0).formatted()).font(.title3.monospacedDigit()) }
    }
}
