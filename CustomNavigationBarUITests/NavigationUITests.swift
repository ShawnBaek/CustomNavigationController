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

    @MainActor private func launchFeatures(_ arguments: [String] = []) -> XCUIApplication {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["--navigation-features"] + arguments
        app.launch()
        let large = app.descendants(matching: .any).matching(identifier: "largeHeaderTitle").firstMatch
        XCTAssertTrue(large.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["featureDone"].isHittable)
        return app
    }

    @MainActor private func reveal(_ element: XCUIElement, in scroll: XCUIElement) {
        for _ in 0..<6 where !element.isHittable { scroll.swipeUp() }
        XCTAssertTrue(element.isHittable)
    }

    @MainActor func testNativeItemsActionsMenusAndPositioning() {
        let app = launchFeatures()
        let done = app.buttons["featureDone"]
        let back = app.buttons["headerBack"]
        let scroll = app.scrollViews["featureContent"]
        let originalDone = done.frame
        let originalBack = back.frame
        done.tap()
        XCTAssertEqual(app.staticTexts["featureFeedback"].label, "Done tapped.")
        app.buttons["featureMore"].tap()
        app.buttons["Mark favorite"].tap()
        XCTAssertEqual(app.staticTexts["featureFeedback"].label, "Favorite selected.")
        // Glass buttons can have smaller visual bounds than their native touch target.
        // Older bars already expose a full-height frame; test within that 44-point area.
        let upperTargetEdge = originalDone.midY - 21 // One point inside a centered 44-point target.
        done.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0))
            .withOffset(CGVector(dx: 0, dy: upperTargetEdge - originalDone.minY)).tap()
        XCTAssertEqual(app.staticTexts["featureFeedback"].label, "Done tapped.")
        app.segmentedControls["leadingSpacing"].buttons["16"].tap()
        app.segmentedControls["trailingSpacing"].buttons["16"].tap()
        app.segmentedControls["verticalPosition"].buttons["+8"].tap()
        XCTAssertEqual(back.frame.minX - originalBack.minX, 16, accuracy: 1)
        XCTAssertEqual(done.frame.maxX - originalDone.maxX, -16, accuracy: 1)
        XCTAssertEqual(done.frame.midY - originalDone.midY, 8, accuracy: 1)
        screenshot("items-positioned-large-title")

        let toggle = app.buttons["toggleDone"]
        reveal(toggle, in: scroll)
        toggle.tap()
        XCTAssertFalse(done.isEnabled)
        toggle.tap()
        XCTAssertTrue(done.isEnabled)
        app.buttons["replaceDone"].tap()
        XCTAssertEqual(done.label, "Save")
        done.tap()
        XCTAssertEqual(app.staticTexts["featureFeedback"].label, "Saved.")
        let modal = app.buttons["featureModal"]
        reveal(modal, in: scroll)
        modal.tap()
        XCTAssertTrue(app.buttons["modalDone"].waitForExistence(timeout: 5))
        screenshot("native-done-modal")
        app.buttons["modalDone"].tap()
        XCTAssertTrue(done.waitForExistence(timeout: 5))
        XCTAssertEqual(done.label, "Save")
        back.tap()
        waitForTitle("Main", in: app)
        app.buttons["rootInfo"].tap()
        XCTAssertEqual(app.staticTexts["titleFeedback"].label, "Native navigation item tapped.")
    }

    @MainActor func testLargeTitleCollapseRotationAndCancelledPop() {
        let app = launchFeatures()
        let scroll = app.scrollViews["featureContent"]
        let header = app.otherElements["navigationHeader"]
        let expandedHeight = header.frame.height
        XCTAssertGreaterThan(expandedHeight, 66)
        screenshot("large-title-expanded")
        scroll.swipeUp()
        let compact = NSPredicate { _, _ in abs(header.frame.height - 66) < 1 }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: compact, object: header)], timeout: 5), .completed)
        XCTAssertTrue(app.buttons["featureDone"].isHittable)
        screenshot("large-title-collapsed")
        edgeDrag(in: app, to: 0.18)
        XCTAssertTrue(app.buttons["featureDone"].isHittable)
        XCTAssertEqual(header.frame.height, 66, accuracy: 1)
        let push = app.buttons["featurePush"]
        reveal(push, in: scroll)
        push.tap()
        let detailTitle = app.descendants(matching: .any).matching(identifier: "headerTitle").firstMatch
        let isDetail = NSPredicate(format: "label == 'Detail' AND hittable == true")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: isDetail, object: detailTitle)], timeout: 5), .completed)
        app.buttons["headerBack"].tap()
        XCTAssertTrue(app.buttons["featureDone"].waitForExistence(timeout: 5))
        XCTAssertEqual(header.frame.height, 66, accuracy: 1)
        XCUIDevice.shared.orientation = .landscapeLeft
        let landscape = NSPredicate { _, _ in app.windows.firstMatch.frame.width > app.windows.firstMatch.frame.height }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: landscape, object: app)], timeout: 5), .completed)
        XCTAssertTrue(app.buttons["featureDone"].isHittable)
        screenshot("native-items-landscape")
        XCUIDevice.shared.orientation = .portrait
        let portrait = NSPredicate { _, _ in
            let frame = app.windows.firstMatch.frame
            return frame.width < frame.height && abs(header.frame.width - frame.width) < 1
        }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: portrait, object: app)], timeout: 5), .completed)
        for _ in 0..<5 where header.frame.height < expandedHeight - 1 { scroll.swipeDown() }
        XCTAssertEqual(header.frame.height, expandedHeight, accuracy: 1)
        XCTAssertTrue(app.buttons["featureDone"].isHittable)
    }

    @MainActor func testLargeTitleAccessibilityAndDirectionalItems() {
        let app = launchFeatures(["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL", "-AppleLanguages", "(ar)", "-AppleLocale", "ar", "-NSForceRightToLeftWritingDirection", "YES"])
        let back = app.buttons["headerBack"]
        let done = app.buttons["featureDone"]
        screenshot("large-title-accessibility-rtl")
        XCTAssertGreaterThan(back.frame.midX, done.frame.midX)
        XCTAssertGreaterThanOrEqual(back.frame.height, 44)
        XCTAssertTrue(done.isHittable)
        let large = app.descendants(matching: .any).matching(identifier: "largeHeaderTitle").firstMatch
        XCTAssertEqual(large.label, "Navigation controls")
        app.scrollViews["featureContent"].swipeUp()
        XCTAssertTrue(done.isHittable)
    }

    @MainActor func testCapture88PointNavigationExample() {
        let app = launch()
        let header = app.otherElements["navigationHeader"]
        let height88 = app.segmentedControls["heightPicker"].buttons["88 pt"]
        height88.tap()
        XCTAssertEqual(header.frame.height, 88, accuracy: 1)
        XCTAssertTrue(height88.isSelected)
        screenshot("88pt-main")

        let openFeatures = app.buttons["showNavigationFeatures"]
        reveal(openFeatures, in: app.scrollViews["sampleContent"])
        openFeatures.tap()
        let done = app.buttons["featureDone"]
        XCTAssertTrue(done.waitForExistence(timeout: 5))
        XCTAssertTrue(done.isHittable)
        XCTAssertGreaterThan(header.frame.height, 88)
        let compactCenterY = header.frame.minY + 44
        XCTAssertEqual(app.buttons["headerBack"].frame.midY, compactCenterY, accuracy: 1)
        XCTAssertEqual(done.frame.midY, compactCenterY, accuracy: 1)
        screenshot("88pt-large-title-centered-buttons")
        done.tap()
        XCTAssertEqual(app.staticTexts["featureFeedback"].label, "Done tapped.")

        let scroll = app.scrollViews["featureContent"]
        scroll.swipeUp()
        let compact = NSPredicate { _, _ in abs(header.frame.height - 88) < 1 }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: compact, object: header)], timeout: 5), .completed)
        XCTAssertEqual(app.buttons["headerBack"].frame.midY, header.frame.midY, accuracy: 1)
        XCTAssertEqual(done.frame.midY, header.frame.midY, accuracy: 1)
        screenshot("88pt-collapsed-centered-buttons")

        let push = app.buttons["featurePush"]
        reveal(push, in: scroll)
        let pushPosition = push.frame.minY
        push.tap()
        let detailTitle = app.descendants(matching: .any).matching(identifier: "headerTitle").firstMatch
        let isDetail = NSPredicate(format: "label == 'Detail' AND hittable == true")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: isDetail, object: detailTitle)], timeout: 5), .completed)
        XCTAssertEqual(app.buttons["headerBack"].frame.midY, compactCenterY, accuracy: 1)
        screenshot("88pt-pushed-detail")
        app.buttons["headerBack"].tap()
        XCTAssertTrue(done.waitForExistence(timeout: 5))
        XCTAssertTrue(done.isHittable)
        XCTAssertEqual(header.frame.height, 88, accuracy: 1)
        XCTAssertEqual(done.frame.midY, header.frame.midY, accuracy: 1)
        XCTAssertEqual(push.frame.minY, pushPosition, accuracy: 1)
        screenshot("88pt-back-preserves-collapse-and-scroll")

        app.buttons["headerBack"].tap()
        waitForTitle("Main", in: app)
        XCTAssertEqual(header.frame.height, 88, accuracy: 1)
        let mainScroll = app.scrollViews["sampleContent"]
        for _ in 0..<4 where !height88.isHittable { mainScroll.swipeDown() }
        XCTAssertTrue(height88.isHittable)
        XCTAssertTrue(height88.isSelected)
        screenshot("88pt-returned-main")
    }

}
