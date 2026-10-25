import XCTest

final class AnalyticsUITests: XCTestCase {
    func testTrafficChartPreservesServerTotalsAndReloadsTheSelectedPeriod() {
        let app = XCUIApplication(bundleIdentifier: "ai.glossia.mobile.preview")
        app.launchArguments = ["analytics", "-AppleLocale", "en_US"]
        app.launch()
        let chart = app.descendants(matching: .any)["analytics-traffic-chart"].firstMatch
        let summary = app.staticTexts["analytics-traffic-summary"]
        XCTAssertTrue(chart.waitForExistence(timeout: 10))
        XCTAssertTrue(chart.isHittable)
        XCTAssertTrue(summary.label.contains("12,480 pageviews"))
        XCTAssertTrue(summary.label.contains("3,206 unique visitors"))
        XCTAssertTrue(app.staticTexts["Daily totals · UTC"].exists)
        let capture = XCTAttachment(screenshot: app.screenshot())
        capture.name = "ios-analytics-traffic-30-days"; capture.lifetime = .keepAlways; add(capture)

        for (period, pageviews, visitors) in [("7 days", "10,980", "2,900"), ("90 days", "14,980", "3,900")] {
            app.segmentedControls.buttons[period].tap()
            let updated = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@",
                                       "\(pageviews) pageviews", "\(visitors) unique visitors"),
                object: summary)
            XCTAssertEqual(XCTWaiter.wait(for: [updated], timeout: 5), .completed, period)
            XCTAssertTrue(chart.exists, period)
            XCTAssertFalse(app.descendants(matching: .any)["analytics-traffic-empty"].firstMatch.exists, period)
        }
    }

    func testEmptyTrafficShowsSetupGuidanceWithoutAFabricatedTrend() {
        let app = XCUIApplication(bundleIdentifier: "ai.glossia.mobile.preview")
        app.launchArguments = ["analytics-empty"]
        app.launch()
        XCTAssertTrue(app.staticTexts["No traffic to chart"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Install the Glossia tracker")).firstMatch.exists)
        XCTAssertFalse(app.descendants(matching: .any)["analytics-traffic-chart"].firstMatch.exists)
        XCTAssertFalse(app.staticTexts["analytics-traffic-summary"].exists)
        let capture = XCTAttachment(screenshot: app.screenshot())
        capture.name = "ios-analytics-traffic-empty"; capture.lifetime = .keepAlways; add(capture)
        app.segmentedControls.buttons["7 days"].tap()
        XCTAssertTrue(app.staticTexts["No traffic to chart"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.descendants(matching: .any)["analytics-traffic-chart"].firstMatch.exists)
    }
}
