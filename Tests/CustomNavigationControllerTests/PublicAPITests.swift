import XCTest
import UIKit
import CustomNavigationController

// Deliberately use a normal import: clients must not need @testable access.
@MainActor
final class PublicAPITests: XCTestCase {
    func testHeaderHeightAndInvalidInput() {
        let header = NavigationHeaderView()
        header.title = "Home"
        let cases: [(CGFloat, CGFloat)] = [(44, 44), (66, 66), (88, 88), (-1, 44), (.nan, 66), (.infinity, 66)]
        for (input, expected) in cases {
            header.customHeight = input
            let size = header.systemLayoutSizeFitting(
                CGSize(width: 390, height: 0),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )
            XCTAssertEqual(size.height, expected, accuracy: 0.5)
        }
    }

    func testTitleIsAnAccessibleHeadingAndOnlyBecomesAButtonWhenItHasAnAction() {
        let header = NavigationHeaderView()
        header.title = "Account"
        XCTAssertEqual(header.titleControl.accessibilityLabel, "Account")
        XCTAssertTrue(header.titleControl.accessibilityTraits.contains(.header))
        XCTAssertFalse(header.titleControl.accessibilityTraits.contains(.button))
        XCTAssertFalse(header.titleControl.isUserInteractionEnabled)

        var taps = 0
        header.onTitleTap = { taps += 1 }
        header.titleControl.sendActions(for: .touchUpInside)
        XCTAssertEqual(taps, 1)
        XCTAssertTrue(header.titleControl.accessibilityTraits.contains(.button))
        XCTAssertTrue(header.titleControl.isUserInteractionEnabled)

        header.onTitleTap = nil
        header.titleControl.sendActions(for: .touchUpInside)
        XCTAssertEqual(taps, 1)
        XCTAssertFalse(header.titleControl.accessibilityTraits.contains(.button))
    }

    func testExistingControllerIsContainedBelowTheHeader() throws {
        let content = UIViewController()
        content.title = "Existing screen"
        let navigation = CustomNavigationController(contentViewController: content)
        let screen = try XCTUnwrap(navigation.topViewController as? CustomNavigationViewController)
        XCTAssertTrue(screen.contentViewController === content)

        screen.loadViewIfNeeded()
        screen.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        screen.view.layoutIfNeeded()

        XCTAssertTrue(content.parent === screen)
        XCTAssertTrue(content.navigationController === navigation)
        XCTAssertEqual(screen.children.count, 1)
        XCTAssertEqual(screen.header.title, "Existing screen")
        XCTAssertEqual(content.view.frame.minY, screen.header.frame.maxY, accuracy: 0.5)
        XCTAssertEqual(content.view.frame, screen.contentLayoutGuide.layoutFrame)
        XCTAssertTrue(screen.header.backButton.isHidden)
    }

    func testWrapperCopiesLazyTitleButPreservesAnExplicitTitle() {
        let lazy = CustomNavigationViewController(contentViewController: LazyTitleController())
        lazy.loadViewIfNeeded()
        XCTAssertEqual(lazy.title, "Loaded title")
        XCTAssertEqual(lazy.header.title, "Loaded title")

        let explicit = CustomNavigationViewController(contentViewController: LazyTitleController())
        explicit.title = "Custom title"
        explicit.loadViewIfNeeded()
        XCTAssertEqual(explicit.header.title, "Custom title")
    }

    func testWrapperUsesStoryboardNavigationItemTitleAsAnInitialFallback() {
        let content = UIViewController()
        content.navigationItem.title = "Storyboard title"
        let screen = CustomNavigationViewController(contentViewController: content)
        screen.loadViewIfNeeded()
        XCTAssertEqual(screen.header.title, "Storyboard title")
    }

    func testPushHelperReusesHeaderScreensAndReturnsTheActualStackEntry() throws {
        let root = ClientScreen()
        let navigation = CustomNavigationController(contentViewController: root)
        navigation.loadViewIfNeeded()
        root.loadViewIfNeeded()
        XCTAssertTrue(navigation.topViewController === root)
        XCTAssertTrue(root.didLoadContent)
        XCTAssertNil(root.contentViewController)

        let content = UIViewController()
        let wrapper = navigation.pushContentViewController(content, animated: false)
        wrapper.loadViewIfNeeded()
        XCTAssertTrue(navigation.topViewController === wrapper)
        XCTAssertTrue(wrapper.contentViewController === content)
        XCTAssertFalse(wrapper.header.backButton.isHidden)
        XCTAssertTrue(navigation.popViewController(animated: false) === wrapper)
        XCTAssertTrue(navigation.topViewController === root)

        let detail = ClientScreen()
        XCTAssertTrue(navigation.pushContentViewController(detail, animated: false) === detail)
    }

    func testThemeAndHeightUpdatesReachLoadedScreensAndBackActionPops() {
        let root = ClientScreen()
        let navigation = CustomNavigationController(rootViewController: root)
        navigation.loadViewIfNeeded()
        root.loadViewIfNeeded()
        let detail = navigation.pushContentViewController(UIViewController(), animated: false)
        detail.loadViewIfNeeded()
        navigation.headerHeight = 88
        navigation.headerBackgroundColor = .systemYellow
        navigation.headerTintColor = .black
        navigation.backButtonAccessibilityLabel = "Return"

        for screen in [root, detail] {
            XCTAssertEqual(screen.header.customHeight, 88)
            XCTAssertEqual(screen.header.backgroundColor, .systemYellow)
            XCTAssertEqual(screen.header.tintColor, .black)
        }
        XCTAssertEqual(detail.header.backButton.accessibilityLabel, "Return")
        detail.header.backButton.sendActions(for: .touchUpInside)
        XCTAssertTrue(navigation.topViewController === root)
    }
}

@MainActor
private final class LazyTitleController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Loaded title"
    }
}

// Subclassing and layout access are compiled from outside the library module.
@MainActor
private final class ClientScreen: CustomNavigationViewController {
    private(set) var didLoadContent = false

    override func viewDidLoad() {
        super.viewDidLoad()
        let content = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor),
            content.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor)
        ])
        didLoadContent = true
    }
}
