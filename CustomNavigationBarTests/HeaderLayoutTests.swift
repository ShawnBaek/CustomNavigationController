import XCTest
import UIKit
import CustomNavigationController
@testable import CustomNavigationBar

@MainActor
final class HeaderLayoutTests: XCTestCase {
    func testHeaderUsesConfiguredContentHeightAtStandardTextSize() {
        for expectedHeight: CGFloat in [44, 66, 88] {
            let header = NavigationHeaderView()
            header.title = "Sample"
            header.customHeight = expectedHeight

            XCTAssertEqual(
                fittedHeight(of: header, width: 390),
                expectedHeight,
                accuracy: 0.5,
                "The public height setting should describe the header below the safe area."
            )
        }
    }

    func testStoryboardKeepsCustomNavigationControllerAndScreenIdentifiers() throws {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle(for: ViewController.self))
        let navigationController = try XCTUnwrap(
            storyboard.instantiateInitialViewController() as? CustomNavigationController
        )

        XCTAssertTrue(navigationController.viewControllers.first is ViewController)
        XCTAssertTrue(
            storyboard.instantiateViewController(withIdentifier: "SecondViewController")
                is SecondViewController
        )
    }

    func testStoryboardHeaderBeginsAtSafeAreaAndContentBeginsAfterHeader() throws {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle(for: ViewController.self))
        let navigationController = try XCTUnwrap(
            storyboard.instantiateInitialViewController() as? CustomNavigationController
        )
        let screen = try XCTUnwrap(navigationController.viewControllers.first as? HeaderViewController)
        let window = try host(navigationController, size: CGSize(width: 390, height: 844))
        defer { window.isHidden = true }

        screen.additionalSafeAreaInsets.top = 44
        layout(window)

        let content = try XCTUnwrap(descendant(in: screen.view, identifier: "sampleContent"))
        XCTAssertGreaterThanOrEqual(screen.view.safeAreaLayoutGuide.layoutFrame.minY, 44)
        XCTAssertEqual(
            screen.header.frame.minY,
            screen.view.safeAreaLayoutGuide.layoutFrame.minY,
            accuracy: 0.5
        )
        XCTAssertEqual(screen.header.frame.height, 66, accuracy: 0.5)
        XCTAssertEqual(content.frame.minY, screen.header.frame.maxY, accuracy: 0.5)
    }

    func testAccessibilityTextCanGrowHeaderAndKeepsControlsTappable() throws {
        let screen = HeaderViewController()
        screen.title = "A deliberately long navigation title that needs more than one line"
        screen.loadViewIfNeeded()
        screen.header.title = screen.title ?? ""

        let hostController = UIViewController()
        hostController.addChild(screen)
        hostController.view.addSubview(screen.view)
        screen.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            screen.view.topAnchor.constraint(equalTo: hostController.view.topAnchor),
            screen.view.leadingAnchor.constraint(equalTo: hostController.view.leadingAnchor),
            screen.view.trailingAnchor.constraint(equalTo: hostController.view.trailingAnchor),
            screen.view.bottomAnchor.constraint(equalTo: hostController.view.bottomAnchor)
        ])
        screen.didMove(toParent: hostController)
        hostController.setOverrideTraitCollection(
            UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge),
            forChild: screen
        )
        let window = try host(hostController, size: CGSize(width: 320, height: 568))
        defer { window.isHidden = true }
        layout(window)

        XCTAssertGreaterThan(screen.header.frame.height, 66)
        XCTAssertGreaterThanOrEqual(screen.header.backButton.bounds.height, 44)
        XCTAssertGreaterThanOrEqual(screen.header.backButton.bounds.width, 44)
        XCTAssertGreaterThanOrEqual(screen.header.titleControl.bounds.height, 44)
        XCTAssertEqual(screen.header.titleControl.accessibilityLabel, screen.title)
        XCTAssertTrue(screen.header.titleControl.accessibilityTraits.contains(.button))
        XCTAssertTrue(screen.header.titleControl.accessibilityTraits.contains(.header))
    }

    func testBackControlMovesToTheLeadingEdgeInRightToLeftLayout() {
        let header = NavigationHeaderView()
        header.title = "Title"
        header.semanticContentAttribute = .forceRightToLeft
        header.frame = CGRect(x: 0, y: 0, width: 390, height: 66)
        header.setNeedsLayout()
        header.layoutIfNeeded()

        XCTAssertGreaterThan(header.backButton.frame.midX, header.titleControl.frame.midX)
        XCTAssertEqual(header.backButton.frame.maxX, header.bounds.maxX - 8, accuracy: 0.5)
    }

    func testInteractivePopGestureRequiresASecondScreen() throws {
        let root = HeaderViewController()
        let navigationController = CustomNavigationController(rootViewController: root)
        navigationController.loadViewIfNeeded()
        let gesture = try XCTUnwrap(navigationController.interactivePopGestureRecognizer)

        XCTAssertTrue(navigationController.isNavigationBarHidden)
        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertFalse(navigationController.gestureRecognizerShouldBegin(gesture))

        navigationController.pushViewController(HeaderViewController(), animated: false)

        XCTAssertEqual(navigationController.viewControllers.count, 2)
        XCTAssertTrue(navigationController.gestureRecognizerShouldBegin(gesture))
    }

    private func fittedHeight(of header: NavigationHeaderView, width: CGFloat) -> CGFloat {
        header.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
    }

    private func host(_ root: UIViewController, size: CGSize) throws -> UIWindow {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(origin: .zero, size: size)
        window.rootViewController = root
        window.makeKeyAndVisible()
        layout(window)
        return window
    }

    private func layout(_ window: UIWindow) {
        window.rootViewController?.view.frame = window.bounds
        window.rootViewController?.view.setNeedsLayout()
        window.rootViewController?.view.layoutIfNeeded()
    }

    private func descendant(in view: UIView, identifier: String) -> UIView? {
        if view.accessibilityIdentifier == identifier { return view }
        for subview in view.subviews {
            if let match = descendant(in: subview, identifier: identifier) { return match }
        }
        return nil
    }
}
