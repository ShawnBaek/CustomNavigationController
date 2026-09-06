import XCTest

final class NavigationUITests: XCTestCase {
    @MainActor private func launch(_ arguments: [String] = []) -> XCUIApplication {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()
        waitForTitle("Main", in: app)
        return app
    }

    @MainActor private func waitForTitle(_ title: String, in app: XCUIApplication) {
        // A sheet leaves the presenting screen in the accessibility tree.
        let button = app.buttons.matching(identifier: "headerTitle")
            .matching(NSPredicate(format: "label == %@", title)).firstMatch
        let predicate = NSPredicate(format: "exists == true AND hittable == true")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: button)], timeout: 5), .completed, app.debugDescription)
    }

    @MainActor private func screenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor func testPushBackAndTitleAction() {
        let app = launch()
        XCTAssertFalse(app.buttons["headerBack"].exists)
        screenshot("main-default-height")
        app.buttons["pushDetail"].tap()
        waitForTitle("Second", in: app)
        app.buttons["headerTitle"].tap()
        XCTAssertEqual(app.staticTexts["titleFeedback"].label, "Second title tapped.")
        screenshot("second-screen")
        app.buttons["headerBack"].tap()
        waitForTitle("Main", in: app)
        app.buttons["headerTitle"].tap()
        XCTAssertEqual(app.staticTexts["titleFeedback"].label, "Main title tapped.")
    }

    @MainActor func testModalDismissalPreservesHeaderAndNavigation() {
        let app = launch()
        app.buttons["pushDetail"].tap()
        waitForTitle("Second", in: app)
        for identifier in ["presentSheet", "presentFullScreen"] {
            app.buttons[identifier].tap()
            screenshot(identifier)
            waitForTitle("Modal", in: app)
            let close = app.buttons.matching(identifier: "headerBack")
                .matching(NSPredicate(format: "label == %@", "Close")).firstMatch
            XCTAssertTrue(close.isHittable)
            close.tap()
            waitForTitle("Second", in: app)
            app.buttons["headerTitle"].tap()
            XCTAssertEqual(app.staticTexts["titleFeedback"].label, "Second title tapped.")
        }
        screenshot("after-modal-dismissal")
        app.buttons["headerBack"].tap()
        waitForTitle("Main", in: app)
    }

    @MainActor func testCompletedAndCancelledInteractivePop() {
        let app = launch()
        // Swiping at the root must not wedge a subsequent push.
        edgeDrag(in: app, to: 0.7)
        waitForTitle("Main", in: app)
        app.buttons["pushDetail"].tap()
        waitForTitle("Second", in: app)
        edgeDrag(in: app, to: 0.18)
        waitForTitle("Second", in: app)
        app.buttons["headerTitle"].tap()
        XCTAssertEqual(app.staticTexts["titleFeedback"].label, "Second title tapped.")
        screenshot("cancelled-edge-pop")
        edgeDrag(in: app, to: 0.85)
        waitForTitle("Main", in: app)
        // A completed gesture must leave the stack ready for the next transition.
        app.buttons["pushDetail"].tap()
        waitForTitle("Second", in: app)
        app.buttons["headerBack"].tap()
        waitForTitle("Main", in: app)
    }

    @MainActor private func edgeDrag(in app: XCUIApplication, to fraction: CGFloat) {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.003, dy: 0.55))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: fraction, dy: 0.55))
        start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.4)
    }

    @MainActor func testHeightStatusBarRotationAndScrolling() {
        let app = launch()
        let header = app.otherElements["navigationHeader"]
        XCTAssertTrue(header.exists)
        XCTAssertEqual(header.frame.height, 66, accuracy: 1)
        app.segmentedControls["heightPicker"].buttons["88 pt"].tap()
        XCTAssertEqual(header.frame.height, 88, accuracy: 1)
        app.buttons["toggleStatusBar"].tap()
        XCTAssertEqual(header.frame.height, 88, accuracy: 1)
        XCTAssertGreaterThanOrEqual(app.scrollViews["sampleContent"].frame.minY, header.frame.maxY - 1)
        XCUIDevice.shared.orientation = .landscapeLeft
        let landscapeLayout = NSPredicate { _, _ in
            let frame = app.windows.firstMatch.frame
            return frame.width > frame.height && abs(header.frame.width - frame.width) < 1
                && abs(header.frame.height - 88) < 1
        }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: landscapeLayout, object: app)], timeout: 5), .completed)
        XCTAssertTrue(app.buttons["headerTitle"].isHittable)
        XCTAssertEqual(header.frame.height, 88, accuracy: 1)
        XCTAssertGreaterThanOrEqual(app.scrollViews["sampleContent"].frame.minY, header.frame.maxY - 1)
        screenshot("landscape-status-bar")
        app.scrollViews["sampleContent"].swipeUp()
        XCTAssertTrue(app.buttons["headerTitle"].isHittable)
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor func testAccessibilityTextAndRightToLeftLayout() {
        let app = launch(["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL", "-AppleLanguages", "(ar)", "-AppleLocale", "ar", "-NSForceRightToLeftWritingDirection", "YES"])
        let title = app.buttons["headerTitle"]
        XCTAssertGreaterThanOrEqual(title.frame.height, 44)
        XCTAssertTrue(title.isHittable)
        screenshot("accessibility-rtl")
        app.scrollViews["sampleContent"].swipeUp()
        let push = app.buttons["pushDetail"]
        if !push.isHittable { app.scrollViews["sampleContent"].swipeDown() }
        push.tap()
        waitForTitle("Second", in: app)
        let back = app.buttons["headerBack"]
        XCTAssertGreaterThan(back.frame.midX, title.frame.midX)
        XCTAssertGreaterThanOrEqual(back.frame.width, 44)
        XCTAssertGreaterThanOrEqual(back.frame.height, 44)
        back.tap()
        waitForTitle("Main", in: app)
    }
}
