import Charts
import SwiftUI

private struct AnalyticsTraffic: Decodable {
    struct Point: Decodable, Identifiable {
        let bucket: Date
        let pageviews: Int
        let uniqueVisitors: Int
        var id: Date { bucket }
    }

    let granularity: String
    let points: [Point]

    var intervalLabel: String {
        switch granularity {
        case "hour": String(localized: "Hourly totals · UTC")
        case "month": String(localized: "Monthly totals · UTC")
        default: String(localized: "Daily totals · UTC")
        }
    }

    var dateFormat: Date.FormatStyle {
        let format = Date.FormatStyle(timeZone: .gmt).month(.abbreviated).day()
        return granularity == "hour" ? format.hour() : format
    }

    static func decode(_ value: Any?) -> Self? {
        guard let value, JSONSerialization.isValidJSONObject(value),
              let data = try? JSONSerialization.data(withJSONObject: value) else { return nil }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(Self.self, from: data)
    }
}

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
            if hasProject {
                Picker("Period", selection: $model.days) {
                    Text("7 days").tag(7); Text("30 days").tag(30); Text("90 days").tag(90)
                }.pickerStyle(.segmented).listRowBackground(Color.clear)
                if model.busy { ProgressView("Loading analytics…") }
                if let error = model.error { GlossiaErrorView(message: error) { Task { await model.load() } } }
                if let value = model.value, let summary = value["summary"] as? [String: Any] {
                    Section("Traffic") {
                        if let traffic = AnalyticsTraffic.decode(value["traffic"]), !traffic.points.isEmpty {
                            trafficChart(traffic, summary: summary)
                        } else {
                            ContentUnavailableView {
                                Label("No traffic to chart", systemImage: "chart.xyaxis.line")
                            } description: {
                                Text(summary["pageviews"] as? Int == 0
                                     ? "No visits in this period. Install the Glossia tracker on your website to learn where your readers are."
                                     : "Time-series data isn't available from this server. Your audience totals are shown below.")
                            }
                            .accessibilityIdentifier("analytics-traffic-empty")
                        }
                    }.listRowBackground(tokens.surface)
                    Section("Audience · last \(model.days) days") {
                        metric("Pageviews", value: summary["pageviews"])
                        metric("Unique visitors", value: summary["unique_visitors"])
                        metric("Visits with a language gap", value: summary["locale_gap_visits"])
                    }.listRowBackground(tokens.surface)
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
        .overlay {
            if !hasProject {
                ContentUnavailableView("Choose a project", systemImage: "folder",
                                       description: Text("Select a project to see its audience and traffic."))
            }
        }
        .task(id: model.days) { if hasProject { await model.load() } }
        .refreshable { if hasProject { await model.load() } }
    }

    private func trafficChart(_ traffic: AnalyticsTraffic, summary: [String: Any]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(traffic.intervalLabel).font(.caption).foregroundStyle(tokens.muted)
            Chart(traffic.points) { point in
                LineMark(x: .value("Date", point.bucket), y: .value("Pageviews", point.pageviews))
                    .foregroundStyle(by: .value("Metric", "Pageviews"))
                    .symbol(.circle)
                    .interpolationMethod(.linear)
                    .accessibilityLabel(point.bucket.formatted(traffic.dateFormat))
                    .accessibilityValue("\(point.pageviews.formatted()) pageviews")
                LineMark(x: .value("Date", point.bucket), y: .value("Unique visitors", point.uniqueVisitors))
                    .foregroundStyle(by: .value("Metric", "Unique visitors"))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 3]))
                    .symbol(.square)
                    .interpolationMethod(.linear)
                    .accessibilityLabel(point.bucket.formatted(traffic.dateFormat))
                    .accessibilityValue("\(point.uniqueVisitors.formatted()) unique visitors")
            }
            .chartForegroundStyleScale(domain: ["Pageviews", "Unique visitors"], range: [tokens.accent, tokens.muted])
            .chartYScale(domain: 0...max(1, traffic.points.map(\.pageviews).max() ?? 0))
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine().foregroundStyle(tokens.border)
                    AxisValueLabel(format: traffic.dateFormat).foregroundStyle(tokens.muted)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(tokens.border)
                    AxisValueLabel().foregroundStyle(tokens.muted)
                }
            }
            .chartLegend(position: .bottom, alignment: .leading)
            .environment(\.timeZone, TimeZone(secondsFromGMT: 0)!)
            .frame(height: 220)
            .accessibilityLabel("Traffic over the last \(model.days) days")
            .accessibilityIdentifier("analytics-traffic-chart")
            Text("\((summary["pageviews"] as? Int ?? 0).formatted()) pageviews · \((summary["unique_visitors"] as? Int ?? 0).formatted()) unique visitors in this period")
                .font(.footnote).foregroundStyle(tokens.muted)
                .accessibilityIdentifier("analytics-traffic-summary")
            Text("Visitors are counted separately in each time bucket.")
                .font(.caption).foregroundStyle(tokens.muted)
        }
        .padding(.vertical, 8)
    }

    private func nonempty(_ value: Any?) -> String {
        guard let text = value as? String, !text.isEmpty else { return "Not available" }
        return text
    }

    private func metric(_ title: String, value: Any?) -> some View {
        LabeledContent(title) { Text((value as? Int ?? 0).formatted()).font(.title3.monospacedDigit()) }
    }
}
