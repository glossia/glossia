import XCTest

final class TranslationReviewsUITests: XCTestCase {
    func testSharedGoalStatesAndReviewedResolution() {
        let app = XCUIApplication(bundleIdentifier: "ai.glossia.mobile.preview")
        for state in ["active", "editing", "resolved", "stale", "error", "permission", "denied", "closed-draft", "rtl", "hebrew", "rtl-large"] {
            app.launchArguments = ["goal-\(state)"]
            app.launch()
            XCTAssertTrue(app.navigationBars[["editing", "error", "permission", "closed-draft"].contains(state) ? "Resolve goal" : "Toki"].waitForExistence(timeout: 10))
            if state == "denied" {
                XCTAssertTrue(app.staticTexts["You do not have permission to view this shared conversation."].waitForExistence(timeout: 5))
            } else if ["editing", "error", "permission", "closed-draft"].contains(state) {
                XCTAssertTrue(app.navigationBars["Resolve goal"].waitForExistence(timeout: 5))
                XCTAssertTrue(app.textFields["goal-decision"].exists || app.textViews["goal-decision"].exists)
                XCTAssertTrue(app.switches["goal-reusable"].exists)
                XCTAssertTrue(app.textFields["goal-guidance"].exists || app.textViews["goal-guidance"].exists)
                app.swipeUp()
                XCTAssertEqual(app.buttons["goal-save"].isEnabled, state == "editing")
            } else {
                XCTAssertTrue(app.staticTexts["Shared linguistic goal"].waitForExistence(timeout: 5))
                XCTAssertFalse(app.staticTexts["Connecting to live progress…"].exists)
                XCTAssertFalse(app.staticTexts["Private Toki conversation"].exists)
                if state == "resolved" {
                    XCTAssertTrue(app.staticTexts["Saved decision"].exists)
                    XCTAssertTrue(app.buttons["goal-resumed"].exists)
                    XCTAssertFalse(app.buttons["goal-resolve"].exists)
                    XCTAssertFalse(app.textFields["toki-composer"].exists)
                }
                if state == "stale" { XCTAssertFalse(app.buttons["goal-resolve"].exists) }
            }
            capture(app, "ios-goal-\(state)")
            if ["active", "rtl", "hebrew"].contains(state) {
                let context = app.buttons["Source and translation context"].firstMatch
                XCTAssertTrue(context.exists); context.tap()
                XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "locales/en/welcome.json")).firstMatch.waitForExistence(timeout: 5))
                capture(app, "ios-goal-context-\(state)")
                context.tap()
            }
            if state == "active" {
                app.swipeUp()
                XCTAssertTrue(app.staticTexts["Sam"].exists)
                XCTAssertTrue(app.staticTexts["Alex"].exists)
                XCTAssertFalse(app.staticTexts["Linguist"].exists)
                let helper = app.staticTexts["Keep chatting until you agree on a decision. Resolution requires a completed Toki reply and no unsent draft."]
                XCTAssertTrue(helper.isHittable)
                capture(app, "ios-goal-active-bottom")
            }
            if state == "resolved" {
                if !app.buttons["goal-resumed"].isHittable { app.swipeUp() }
                app.buttons["goal-resumed"].tap()
                XCTAssertTrue(app.staticTexts["Resumed translation"].waitForExistence(timeout: 5))
            }
            if state == "rtl" {
                let input = app.textFields["toki-composer"]
                XCTAssertTrue(input.exists); input.tap(); input.typeText("L10N/ar.md")
                XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
                capture(app, "ios-goal-rtl-keyboard")
            }
            app.terminate()
        }
    }

    func testTranslationRowsNeverShowOldInlineAnswerFormOrHistoricalConnection() {
        let app = XCUIApplication(bundleIdentifier: "ai.glossia.mobile.preview")
        for state in ["open", "answered", "stale", "denied"] {
            app.launchArguments = ["review-\(state)"]; app.launch()
            XCTAssertTrue(app.navigationBars["Translation"].waitForExistence(timeout: 10))
            XCTAssertFalse(app.staticTexts["Connecting to live progress…"].exists)
            XCTAssertFalse(app.buttons["review-submit"].exists)
            capture(app, "ios-review-row-\(state)"); app.terminate()
        }
    }

    func testFluencyAndSupportedTextImportMenuUseProductionViews() {
        let app = XCUIApplication(bundleIdentifier: "ai.glossia.mobile.preview")
        app.launchArguments = ["profile"]; app.launch()
        let fluency = app.buttons["Fluent languages"]
        XCTAssertTrue(fluency.waitForExistence(timeout: 10)); fluency.tap()
        let input = app.textFields["fluent-languages"]
        XCTAssertTrue(input.waitForExistence(timeout: 5)); input.tap(); input.typeText("ar, he, es")
        capture(app, "ios-fluency-keyboard"); app.terminate()
        app.launchArguments = ["goal-active"]; app.launch()
        let attach = app.buttons["thread-attach"]
        XCTAssertTrue(attach.waitForExistence(timeout: 10)); attach.tap()
        XCTAssertTrue(app.buttons["Choose Files"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Photo Library"].isEnabled)
        capture(app, "ios-goal-text-import-menu"); app.terminate()
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
