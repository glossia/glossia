import XCTest
import UIKit

final class WorkspaceUITests: XCTestCase {
    func testProjectSelectionEmptyStatesAreCenteredAcrossTabs() {
        let app = XCUIApplication(bundleIdentifier: "ai.glossia.mobile.preview")
        app.launchArguments = ["no-project"]
        app.launch()
        for tab in ["Toki", "Translations", "Analytics"] {
            app.tabBars.buttons[tab].tap()
            let title = app.staticTexts["Choose a project"]
            XCTAssertTrue(title.waitForExistence(timeout: 5))
            let contentMidpoint = (app.navigationBars[tab].frame.maxY + app.tabBars.firstMatch.frame.minY) / 2
            XCTAssertEqual(title.frame.midY, contentMidpoint, accuracy: 65, tab)
            XCTAssertFalse(app.buttons["toki-mascot"].exists)
            let capture = XCTAttachment(screenshot: app.screenshot())
            capture.name = "ios-no-project-\(tab.lowercased())"
            capture.lifetime = .keepAlways
            add(capture)
        }
    }

    func testTokiReactsWithoutSendingOrChangingTheDraft() {
        let app = XCUIApplication(bundleIdentifier: "ai.glossia.mobile.preview")
        app.launchArguments = ["empty"]
        app.launch()
        let mascot = app.buttons["toki-mascot"]
        let composer = app.descendants(matching: .any)["toki-composer"].firstMatch
        let compose = app.buttons["new-conversation"]
        XCTAssertTrue(compose.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["No conversations yet"].waitForExistence(timeout: 5))
        XCTAssertFalse(mascot.exists)
        XCTAssertFalse(composer.exists)
        let contentMidpoint = (app.navigationBars["Toki"].frame.maxY + app.tabBars.firstMatch.frame.minY) / 2
        XCTAssertEqual(app.staticTexts["No conversations yet"].frame.midY, contentMidpoint, accuracy: 65)
        let empty = XCTAttachment(screenshot: app.screenshot())
        empty.name = "ios-toki-empty-history"; empty.lifetime = .keepAlways; add(empty)
        compose.tap()
        XCTAssertTrue(mascot.waitForExistence(timeout: 5))
        XCTAssertTrue(app.navigationBars["New conversation"].exists)
        XCTAssertFalse(app.buttons["toki-translation-source"].exists)
        let fresh = XCTAttachment(screenshot: app.screenshot())
        fresh.name = "ios-toki-new-conversation"; fresh.lifetime = .keepAlways; add(fresh)
        mascot.press(forDuration: 1.5)
        let settled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "Ready to help"), object: mascot)
        XCTAssertEqual(XCTWaiter.wait(for: [settled], timeout: 4), .completed)
        composer.tap(); composer.typeText("Keep our linguistic decisions")
        XCTAssertEqual(mascot.value as? String, "Ready to help")
        mascot.tap()
        XCTAssertEqual(mascot.value as? String, "Waving hello")
        mascot.tap()
        XCTAssertEqual(mascot.value as? String, "Happy to see you")
        let firstFrame = mascot.screenshot().pngRepresentation
        Thread.sleep(forTimeInterval: 0.25)
        let secondFrame = mascot.screenshot().pngRepresentation
        if UIAccessibility.isReduceMotionEnabled {
            XCTAssertEqual(firstFrame, secondFrame, "Reduce Motion must use a static expression")
        } else {
            XCTAssertNotEqual(firstFrame, secondFrame, "The arms must animate, not just swap a static pose")
        }
        let capture = XCTAttachment(screenshot: app.screenshot())
        capture.name = UIAccessibility.isReduceMotionEnabled ? "ios-toki-reduced-motion" : "ios-toki-greeting"
        capture.lifetime = .keepAlways
        add(capture)
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "Ready to help"), object: mascot)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 4), .completed)
        mascot.tap()
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertEqual(mascot.value as? String, "Ready to help")
        XCTAssertEqual(composer.value as? String, "Keep our linguistic decisions")
        XCTAssertFalse(app.staticTexts["You"].exists)
    }

    func testConversationHistoryOpensExistingThreadsAndResumesUnsentSuggestions() {
        let app = XCUIApplication(bundleIdentifier: "ai.glossia.mobile.preview")
        app.launchArguments = ["toki"]
        app.launch()
        let existing = app.buttons["conversation-93cf36a3-802e-4f91-9112-77d8a919efc5"]
        XCTAssertTrue(existing.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["toki-mascot"].exists)
        let composer = app.descendants(matching: .any)["toki-composer"].firstMatch
        XCTAssertFalse(composer.exists)
        let history = XCTAttachment(screenshot: app.screenshot())
        history.name = "ios-toki-conversation-history"; history.lifetime = .keepAlways; add(history)
        existing.tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Of course. Gather")).firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["toki-mascot"].exists)
        app.navigationBars.buttons["Toki"].tap()
        app.buttons["new-conversation"].tap()
        XCTAssertTrue(app.buttons["toki-mascot"].waitForExistence(timeout: 5))
        let suggestion = "Which languages does this project support?"
        app.buttons[suggestion].tap()
        XCTAssertEqual(composer.value as? String, suggestion)
        XCTAssertFalse(app.staticTexts["You"].exists)
        app.navigationBars.buttons["Toki"].tap()
        XCTAssertFalse(composer.exists)
        XCTAssertFalse(app.buttons["toki-mascot"].exists)
        XCTAssertTrue(existing.exists)
        app.tabBars.buttons["Profile"].tap()
        app.tabBars.buttons["Toki"].tap()
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Draft conversation")).firstMatch.tap()
        XCTAssertTrue(composer.waitForExistence(timeout: 5))
        XCTAssertEqual(composer.value as? String, suggestion)
        XCTAssertFalse(app.buttons["toki-translation-source"].exists)
        XCTAssertFalse(app.staticTexts["You"].exists)
    }

    func testWorkspaceBrowsingIsStagedAndProjectSelectionApplies() {
        let app = XCUIApplication(bundleIdentifier: "ai.glossia.mobile.preview")
        app.launchArguments = ["empty"]
        app.launch()
        let switcher = app.buttons["workspace-switcher"]
        XCTAssertTrue(switcher.waitForExistence(timeout: 10))
        switcher.tap()
        let organization = app.buttons["workspace-organization"]
        XCTAssertTrue(organization.waitForExistence(timeout: 5))
        organization.tap()
        app.buttons["Other team"].tap()
        XCTAssertTrue(app.buttons["workspace-project-docs"].waitForExistence(timeout: 5))
        app.buttons["Cancel"].tap()
        XCTAssertTrue(switcher.label.contains("acme"))
        XCTAssertTrue(switcher.label.contains("website"))
        switcher.tap()
        XCTAssertTrue(app.buttons["workspace-project-docs"].waitForExistence(timeout: 5))
        app.buttons["workspace-project-docs"].tap()
        XCTAssertTrue(switcher.waitForExistence(timeout: 5))
        XCTAssertTrue(switcher.label.contains("acme"))
        XCTAssertTrue(switcher.label.contains("docs"))
        XCTAssertTrue(app.tabBars.buttons["Profile"].exists)
    }

    func testSelfHostedURLIsEditableBeforeAuthentication() {
        let app = XCUIApplication(bundleIdentifier: "ai.glossia.mobile.preview")
        app.launchArguments = ["login"]
        app.launch()
        XCTAssertFalse(app.buttons["Toki"].exists)
        app.buttons["Self-hosted server"].tap()
        let address = app.textFields.firstMatch
        XCTAssertTrue(address.waitForExistence(timeout: 5))
        address.tap()
        address.typeText("glossia.example.com")
        XCTAssertTrue((address.value as? String ?? "").contains("glossia.example.com"))
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.buttons["Sign in with Glossia"].exists)
    }

    func testAppLanguageOverridePreservesDraftsAndPersistsAfterRelaunch() {
        let app = XCUIApplication(bundleIdentifier: "ai.glossia.mobile.preview")
        app.launchArguments = ["language-rtl", "--reset-app-language", "-AppleLocale", "de_DE"]
        app.launch()
        XCTAssertTrue(app.buttons["new-conversation"].waitForExistence(timeout: 10))
        app.buttons["new-conversation"].tap()
        let composer = app.descendants(matching: .any)["toki-composer"].firstMatch
        XCTAssertTrue(composer.waitForExistence(timeout: 5))
        composer.tap(); composer.typeText("Keep this unsent draft")
        app.navigationBars.buttons["Toki"].tap()
        app.tabBars.buttons["Profile"].tap()
        let picker = app.buttons["app-language"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        XCTAssertLessThan(app.tabBars.buttons["Profile"].frame.midX, app.tabBars.buttons["Toki"].frame.midX)
        captureLanguage(app, "ios-language-system-default-rtl")
        picker.tap()
        XCTAssertTrue(app.buttons["English"].waitForExistence(timeout: 5))
        captureLanguage(app, "ios-language-choices")
        app.buttons["English"].tap()
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        XCTAssertTrue(picker.label.contains("English") || (picker.value as? String)?.contains("English") == true)
        XCTAssertLessThan(app.tabBars.buttons["Toki"].frame.midX, app.tabBars.buttons["Profile"].frame.midX)
        captureLanguage(app, "ios-language-english-ltr")
        app.tabBars.buttons["Toki"].tap()
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Draft conversation")).firstMatch.tap()
        XCTAssertTrue(composer.waitForExistence(timeout: 5))
        XCTAssertEqual(composer.value as? String, "Keep this unsent draft")
        app.navigationBars.buttons["Toki"].tap()
        app.tabBars.buttons["Analytics"].tap()
        let summary = app.staticTexts["analytics-traffic-summary"]
        XCTAssertTrue(summary.waitForExistence(timeout: 10))
        XCTAssertTrue(summary.label.contains("12,480 pageviews"))
        XCTAssertTrue(summary.label.contains("3,206 unique visitors"))
        captureLanguage(app, "ios-language-english-numbers-on-german-device")
        app.terminate()
        app.launchArguments = ["profile", "-AppleLocale", "de_DE"]
        app.launch()
        XCTAssertTrue(picker.waitForExistence(timeout: 10))
        XCTAssertTrue(picker.label.contains("English") || (picker.value as? String)?.contains("English") == true)
        captureLanguage(app, "ios-language-english-restored")
        picker.tap()
        app.buttons["System default"].tap()
        XCTAssertTrue(picker.label.contains("System default") || (picker.value as? String)?.contains("System default") == true)
    }

    private func captureLanguage(_ app: XCUIApplication, _ name: String) {
        let capture = XCTAttachment(screenshot: app.screenshot())
        capture.name = name; capture.lifetime = .keepAlways; add(capture)
    }

    func testChatOpensAtLatestReplyAndShowsGenerationStatus() {
        let app = XCUIApplication(bundleIdentifier: "ai.glossia.mobile.preview")
        for (screen, text) in [
            ("chat", "Of course. Gather your product names, navigation labels, and the terms people see during onboarding. We can decide which to translate and which to keep."),
            ("thinking", "Toki is thinking…"),
            ("failed", "Toki couldn't finish")
        ] {
            app.launchArguments = [screen]
            app.launch()
            let message = app.staticTexts.matching(NSPredicate(format: "label == %@", text)).firstMatch
            XCTAssertTrue(message.waitForExistence(timeout: 5), screen)
            XCTAssertTrue(message.isHittable, screen)
            let composer = app.descendants(matching: .any)["toki-composer"].firstMatch
            XCTAssertTrue(composer.exists, screen)
            XCTAssertLessThanOrEqual(message.frame.maxY, composer.frame.minY, screen)
            app.terminate()
        }
    }

    func testTokiWorkStatusShowsTruthfulStatesAndExplainsStaleObservations() {
        let app = XCUIApplication(bundleIdentifier: "ai.glossia.mobile.preview")
        for (state, title) in [("running", "Toki is thinking…"), ("completed", "Toki finished"),
                               ("failed", "Toki couldn't finish"), ("stale", "Open Glossia to check Toki")] {
            app.launchArguments = ["activity-\(state)"]
            app.launch()
            let status = app.buttons["toki-work-status"]
            XCTAssertTrue(status.waitForExistence(timeout: 10), state)
            let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@", title), object: status)
            XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 5), .completed, state)
            status.tap()
            XCTAssertEqual(status.value as? String, "Expanded")
            if state == "stale" { XCTAssertTrue(app.buttons["toki-check-status"].exists) }
            let capture = XCTAttachment(screenshot: app.screenshot())
            capture.name = "ios-toki-work-\(state)"; capture.lifetime = .keepAlways; add(capture)
            if state == "running" {
                XCUIDevice.shared.press(.home)
                let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
                XCTAssertTrue(springboard.wait(for: .runningForeground, timeout: 5))
                // SpringBoard reports foreground before the home animation settles.
                Thread.sleep(forTimeInterval: 2)
                let compact = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
                compact.name = "ios-toki-live-activity-compact"; compact.lifetime = .keepAlways; add(compact)
                springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.04)).press(forDuration: 1)
                Thread.sleep(forTimeInterval: 1)
                let expanded = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
                expanded.name = "ios-toki-live-activity-expanded"; expanded.lifetime = .keepAlways; add(expanded)
            }
            app.terminate()
        }
    }

    func testTranslationProgressUpdatesWithoutManualRefresh() {
        let app = XCUIApplication(bundleIdentifier: "ai.glossia.mobile.preview")
        app.launchArguments = ["translation-live"]
        app.launch()
        XCTAssertTrue(app.staticTexts["1 of 3 files translated"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["locales/es/welcome.json"].exists)
        let running = XCTAttachment(screenshot: app.screenshot())
        running.name = "ios-translation-progress-running"; running.lifetime = .keepAlways; add(running)
        XCTAssertTrue(app.staticTexts["3 of 3 files translated"].waitForExistence(timeout: 10))
        let status = app.descendants(matching: .any)["translation-status"].firstMatch
        XCTAssertTrue(status.label.contains("Completed") || (status.value as? String)?.contains("Completed") == true)
        XCTAssertFalse(app.staticTexts["Reconnecting to live progress…"].exists)
        let completed = XCTAttachment(screenshot: app.screenshot())
        completed.name = "ios-translation-progress-completed"; completed.lifetime = .keepAlways; add(completed)
    }

    func testTranslationDiscussionKeepsSourceAndConversationAcrossTabs() {
        let app = XCUIApplication(bundleIdentifier: "ai.glossia.mobile.preview")
        app.launchArguments = ["translations"]
        app.launch()
        let translation = app.buttons["translation-abc12345-802e-4f91-9112-77d8a919efc5"]
        XCTAssertTrue(translation.waitForExistence(timeout: 10))
        translation.tap()
        let discuss = app.buttons["discuss-translation"]
        XCTAssertTrue(app.staticTexts["Refresh the welcome experience"].waitForExistence(timeout: 5))
        app.swipeUp()
        XCTAssertTrue(discuss.waitForExistence(timeout: 5))
        let disclosure = app.staticTexts["Start a private conversation linked to this translation. No changes are applied automatically."]
        for _ in 0..<3 {
            if disclosure.isHittable && disclosure.frame.maxY <= app.tabBars.firstMatch.frame.minY + 0.5 { break }
            app.swipeUp()
        }
        XCTAssertTrue(disclosure.isHittable)
        XCTAssertLessThanOrEqual(disclosure.frame.maxY, app.tabBars.firstMatch.frame.minY + 0.5)
        let detail = XCTAttachment(screenshot: app.screenshot())
        detail.name = "ios-navigation-translation-detail"
        detail.lifetime = .keepAlways
        add(detail)
        discuss.tap()
        let source = app.buttons["toki-translation-source"]
        XCTAssertTrue(source.waitForExistence(timeout: 5))
        let draft = XCTAttachment(screenshot: app.screenshot())
        draft.name = "ios-navigation-source-draft"
        draft.lifetime = .keepAlways
        add(draft)
        let composer = app.descendants(matching: .any)["toki-composer"].firstMatch
        XCTAssertTrue(composer.exists)
        composer.tap(); composer.typeText("Use a warmer onboarding voice")
        app.buttons["Send message"].tap()
        XCTAssertTrue(app.staticTexts["Use a warmer onboarding voice"].waitForExistence(timeout: 5))
        let reply = XCTAttachment(screenshot: app.screenshot())
        reply.name = "ios-navigation-source-reply"
        reply.lifetime = .keepAlways
        add(reply)
        source.tap()
        XCTAssertTrue(discuss.waitForExistence(timeout: 5))
        app.tabBars.buttons["Toki"].tap()
        XCTAssertTrue(app.staticTexts["Use a warmer onboarding voice"].waitForExistence(timeout: 5))
    }

    func testColdAndWarmLinksOpenDirectRecordsWithNativeBack() {
        let app = XCUIApplication(bundleIdentifier: "ai.glossia.mobile.preview")
        app.launchArguments = ["empty"]
        app.launch()
        XCTAssertTrue(app.staticTexts["No conversations yet"].waitForExistence(timeout: 10))
        app.terminate()
        XCTAssertTrue(app.wait(for: .notRunning, timeout: 5))
        let suffix = "?server=https%3A%2F%2Fglossia.example.com%2F"
        XCUIDevice.shared.system.open(URL(string: "glossia://navigate/acme/website/translations/abc12345-802e-4f91-9112-77d8a919efc5" + suffix)!)
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        XCTAssertTrue(app.staticTexts["Refresh the welcome experience"].waitForExistence(timeout: 10))
        app.swipeUp()
        XCTAssertTrue(app.buttons["discuss-translation"].waitForExistence(timeout: 10))
        app.navigationBars.buttons["Translations"].tap()
        XCTAssertTrue(app.buttons["translation-abc12345-802e-4f91-9112-77d8a919efc5"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Profile"].tap()
        XCUIDevice.shared.system.open(URL(string: "glossia://navigate/acme/website/toki/new" + suffix + "&translation_id=abc12345-802e-4f91-9112-77d8a919efc5")!)
        XCTAssertTrue(app.buttons["toki-translation-source"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Toki is thinking…"].exists)
    }

    func testHiddenDraftBlocksLinksAndCanBeResumed() {
        let app = XCUIApplication(bundleIdentifier: "ai.glossia.mobile.preview")
        app.launchArguments = ["source-chat"]
        app.launch()
        let composer = app.descendants(matching: .any)["toki-composer"].firstMatch
        XCTAssertTrue(composer.waitForExistence(timeout: 10))
        composer.tap(); composer.typeText("Keep this linguistic decision")
        app.navigationBars.buttons["Toki"].tap()
        app.tabBars.buttons["Profile"].tap()
        XCUIDevice.shared.system.open(URL(string: "glossia://navigate/acme/website/analytics?server=https%3A%2F%2Fglossia.example.com%2F")!)
        let notice = app.alerts["Glossia link"]
        XCTAssertTrue(notice.waitForExistence(timeout: 5))
        notice.buttons["OK"].tap()
        XCTAssertTrue(app.navigationBars["Profile"].exists)
        app.tabBars.buttons["Toki"].tap()
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Draft conversation")).firstMatch.tap()
        XCTAssertTrue(composer.waitForExistence(timeout: 5))
        XCTAssertTrue((composer.value as? String ?? "").contains("Keep this linguistic decision"))
    }
}
