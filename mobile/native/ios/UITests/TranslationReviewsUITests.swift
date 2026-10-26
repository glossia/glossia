import XCTest

final class TranslationReviewsUITests: XCTestCase {
    func testSharedGoalStatesAndReviewedResolution() {
        let app = XCUIApplication(bundleIdentifier: "ai.glossia.mobile.preview")
        for state in ["active", "dark", "editing", "resolved", "stale", "error", "permission", "denied", "closed-draft", "rtl", "hebrew", "rtl-large"] {
            app.launchArguments = ["goal-\(state)"]
            app.launch()
            XCTAssertTrue(app.navigationBars[["editing", "error", "permission", "closed-draft"].contains(state) ? "Review decision" : state == "denied" ? "Toki" : "Spanish onboarding"].waitForExistence(timeout: 10))
            if state == "denied" {
                XCTAssertTrue(app.staticTexts["You do not have permission to view this shared conversation."].waitForExistence(timeout: 5))
            } else if ["editing", "error", "permission", "closed-draft"].contains(state) {
                XCTAssertTrue(app.navigationBars["Review decision"].waitForExistence(timeout: 5))
                XCTAssertTrue(app.textFields["goal-decision"].exists || app.textViews["goal-decision"].exists)
                XCTAssertTrue(app.switches["goal-reusable"].exists)
                XCTAssertTrue(app.textFields["goal-guidance"].exists || app.textViews["goal-guidance"].exists)
                app.swipeUp()
                XCTAssertEqual(app.buttons["goal-save"].isEnabled, state == "editing")
            } else {
                XCTAssertTrue(app.buttons["goal-context"].firstMatch.waitForExistence(timeout: 5))
                XCTAssertFalse(app.staticTexts["Connecting to live progress…"].exists)
                XCTAssertFalse(app.staticTexts["Private Toki conversation"].exists)
                if state == "resolved" {
                    XCTAssertTrue(app.staticTexts["Approved decision"].exists)
                    XCTAssertTrue(app.staticTexts["Approved by Alex"].exists)
                    XCTAssertTrue(app.buttons["goal-resumed"].exists)
                    XCTAssertFalse(app.buttons["goal-resolve"].exists)
                    XCTAssertFalse(app.textFields["toki-composer"].exists)
                }
                if state == "stale" { XCTAssertFalse(app.buttons["goal-resolve"].exists) }
            }
            capture(app, "ios-goal-\(state)")
            if ["active", "rtl", "hebrew"].contains(state) {
                let context = app.buttons["goal-context"].firstMatch
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
                XCTAssertTrue(app.staticTexts["Only a person can approve this decision."].isHittable)
                capture(app, "ios-goal-active-bottom")
                app.buttons["goal-resolve"].tap()
                XCTAssertTrue(app.navigationBars["Review decision"].waitForExistence(timeout: 5))
                XCTAssertEqual(app.switches["goal-reusable"].value as? String, "0")
                let answer = app.textFields["goal-decision"].exists ? app.textFields["goal-decision"] : app.textViews["goal-decision"]
                answer.tap(); answer.typeText("Reviewed. ")
                app.buttons["goal-close"].tap()
                XCTAssertTrue(app.navigationBars["Spanish onboarding"].waitForExistence(timeout: 5))
                XCTAssertTrue(app.staticTexts["Decision draft"].exists)
                capture(app, "ios-goal-retained-draft")
                app.buttons["goal-resolve"].tap()
                XCTAssertTrue(app.navigationBars["Review decision"].waitForExistence(timeout: 5))
                XCTAssertTrue((answer.value as? String)?.contains("Reviewed.") == true)
                app.switches["goal-reusable"].switches.firstMatch.tap()
                XCTAssertEqual(app.switches["goal-reusable"].value as? String, "1")
                let rule = app.descendants(matching: .any).matching(identifier: "goal-guidance").firstMatch
                XCTAssertTrue(rule.waitForExistence(timeout: 5))
                rule.tap(); rule.typeText("Keep Spanish onboarding informal.")
                capture(app, "ios-goal-review-keyboard")
                app.buttons["goal-save"].tap()
                XCTAssertTrue(app.navigationBars["Spanish onboarding"].waitForExistence(timeout: 5))
                XCTAssertTrue(app.staticTexts["Approved by Alex"].waitForExistence(timeout: 5))
                XCTAssertFalse(app.textFields["toki-composer"].exists)
                app.swipeUp()
                let guidance = app.buttons["Guidance proposed for PR review"].firstMatch
                XCTAssertTrue(guidance.exists); guidance.tap()
                XCTAssertTrue(app.staticTexts["Keep Spanish onboarding informal."].waitForExistence(timeout: 5))
                app.swipeUp()
                XCTAssertTrue(app.buttons["goal-resumed"].isHittable)
                capture(app, "ios-goal-approved-after-save")
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
            if state == "rtl-large" {
                app.swipeUp()
                XCTAssertTrue(app.buttons["goal-resolve"].isHittable)
                capture(app, "ios-goal-rtl-large-proposal")
                app.buttons["goal-resolve"].tap()
                XCTAssertTrue(app.navigationBars["Review decision"].waitForExistence(timeout: 5))
                capture(app, "ios-goal-rtl-large-review")
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
