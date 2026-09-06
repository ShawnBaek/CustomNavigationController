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
// Deliberately uses a normal import so every assertion is available to clients.
@MainActor
final class NavigationItemsPublicAPITests: XCTestCase {
    func testDefaultButtonsStayVerticallyCenteredAtEveryHeaderHeight() {
        let navigation = CustomNavigationController(rootViewController: CustomNavigationViewController())
        let window = host(navigation)
        defer { window.isHidden = true }
        let content = UIViewController()
        content.title = "Detail"
        content.navigationItem.largeTitleDisplayMode = .always
        let done = button(title: "Done")
        content.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: done)
        let screen = navigation.pushContentViewController(content, animated: false)

        XCTAssertEqual(navigation.buttonLayout.verticalOffset, 0)
        for largeTitles in [false, true] {
            navigation.prefersLargeTitles = largeTitles
            for height: CGFloat in [44, 66, 88, 120, 200] {
                navigation.headerHeight = height
                layout(window)
                let compactHeight = screen.header.bounds.height - screen.header.expandedTitleHeight
                XCTAssertEqual(compactHeight, height, accuracy: 0.5)
                for control in [screen.header.backButton, done] {
                    let frame = control.convert(control.bounds, to: screen.header)
                    XCTAssertEqual(frame.midY, compactHeight / 2, accuracy: 0.5,
                                   "Default buttons must stay centered at height \(height), large titles: \(largeTitles).")
                }
            }
        }
    }

    func testWrappedItemsReloadAndFollowUIKitBackButtonPolicy() throws {
        let root = CustomNavigationViewController()
        let rootItem = button(title: "Root action")
        root.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rootItem)
        let content = UIViewController()
        let leading = button(title: "Leading")
        let trailing = button(title: "Trailing")
        content.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leading)
        content.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: trailing)
        content.navigationItem.hidesBackButton = true

        let navigation = CustomNavigationController(rootViewController: root)
        let window = host(navigation)
        defer { window.isHidden = true }
        root.reloadNavigationItems()
        layout(window)
        XCTAssertTrue(rootItem.isDescendant(of: root.header), "Header screens source their own navigation item.")

        let screen = navigation.pushContentViewController(content, animated: false)
        screen.loadViewIfNeeded()
        screen.reloadNavigationItems()
        layout(window)

        XCTAssertTrue(leading.isDescendant(of: screen.header))
        XCTAssertTrue(trailing.isDescendant(of: screen.header))
        XCTAssertTrue(screen.header.backButton.isHidden)

        content.navigationItem.hidesBackButton = false
        content.navigationItem.leftItemsSupplementBackButton = false
        screen.reloadNavigationItems()
        XCTAssertTrue(screen.header.backButton.isHidden, "A leading item replaces Back by default.")

        content.navigationItem.leftItemsSupplementBackButton = true
        screen.reloadNavigationItems()
        XCTAssertFalse(screen.header.backButton.isHidden, "Supplement mode keeps both Back and leading items.")

        let replacement = button(title: "Replacement")
        content.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: replacement)
        screen.reloadNavigationItems()
        layout(window)
        XCTAssertFalse(trailing.isDescendant(of: screen.header))
        XCTAssertTrue(replacement.isDescendant(of: screen.header))
    }

    func testLargeTitleInsetIsReversibleAndDoesNotTakeTheScrollDelegate() throws {
        let content = ScrollContentController()
        content.loadViewIfNeeded()
        content.navigationItem.largeTitleDisplayMode = .always
        content.scrollView.contentInset = UIEdgeInsets(top: 13, left: 2, bottom: 17, right: 3)
        let delegate = ScrollDelegate()
        content.scrollView.delegate = delegate

        let navigation = CustomNavigationController(contentViewController: content)
        navigation.prefersLargeTitles = true
        let screen = try XCTUnwrap(navigation.topViewController as? CustomNavigationViewController)
        screen.largeTitleScrollView = content.scrollView
        let window = host(navigation)
        defer { window.isHidden = true }
        screen.reloadNavigationItems()
        layout(window)

        let contribution = screen.header.expandedTitleHeight
        XCTAssertGreaterThan(contribution, 0)
        XCTAssertEqual(content.scrollView.contentInset.top, 13 + contribution, accuracy: 0.5)
        XCTAssertEqual(content.scrollView.contentInset.bottom, 17, accuracy: 0.5)
        XCTAssertTrue(content.scrollView.delegate === delegate)

        content.scrollView.contentOffset.y = 120
        let collapsedOffset = content.scrollView.contentOffset.y
        navigation.prefersLargeTitles = false
        layout(window)
        XCTAssertEqual(content.scrollView.contentOffset.y, collapsedOffset, accuracy: 0.5)
        navigation.prefersLargeTitles = true
        layout(window)
        XCTAssertEqual(content.scrollView.contentInset.top, 13 + contribution, accuracy: 0.5)
        XCTAssertEqual(content.scrollView.contentOffset.y, collapsedOffset, accuracy: 0.5)
        screen.largeTitleScrollView = nil
        screen.reloadNavigationItems()
        XCTAssertEqual(content.scrollView.contentInset.top, 13, accuracy: 0.5)
        XCTAssertEqual(content.scrollView.contentInset.bottom, 17, accuracy: 0.5)
        XCTAssertTrue(content.scrollView.delegate === delegate)
    }

    func testReplacingAReleasedScrollViewAddsAndRemovesItsOwnInsets() {
        let screen = CustomNavigationViewController()
        screen.title = "Library"
        let navigation = CustomNavigationController(rootViewController: screen)
        navigation.prefersLargeTitles = true
        let window = host(navigation)
        defer { window.isHidden = true }

        weak var released: UIScrollView?
        autoreleasepool {
            let original = UIScrollView()
            released = original
            screen.largeTitleScrollView = original
            layout(window)
            XCTAssertGreaterThan(original.contentInset.top, 0)
        }
        XCTAssertNil(released, "Selecting a primary scroll view must not retain it.")

        let replacement = UIScrollView()
        replacement.contentInset.top = 7
        replacement.verticalScrollIndicatorInsets.top = 9
        replacement.contentOffset.y = -7
        screen.largeTitleScrollView = replacement
        layout(window)
        let expansion = screen.header.expandedTitleHeight
        XCTAssertEqual(replacement.contentInset.top, 7 + expansion, accuracy: 0.5)
        XCTAssertEqual(replacement.verticalScrollIndicatorInsets.top, 9 + expansion, accuracy: 0.5)
        XCTAssertEqual(screen.header.largeTitleCollapseProgress, 0, accuracy: 0.01)

        screen.largeTitleScrollView = nil
        XCTAssertEqual(replacement.contentInset.top, 7, accuracy: 0.5)
        XCTAssertEqual(replacement.verticalScrollIndicatorInsets.top, 9, accuracy: 0.5)
        XCTAssertEqual(replacement.contentOffset.y, -7, accuracy: 0.5)
    }

    func testLargeTitleDisplayModeInheritsForAutomaticAndOverridesForAlwaysAndNever() throws {
        let content = ScrollContentController()
        content.title = "Library"
        content.loadViewIfNeeded()
        let navigation = CustomNavigationController(contentViewController: content)
        let screen = try XCTUnwrap(navigation.topViewController as? CustomNavigationViewController)
        screen.largeTitleScrollView = content.scrollView
        let window = host(navigation)
        defer { window.isHidden = true }

        navigation.prefersLargeTitles = true
        content.navigationItem.largeTitleDisplayMode = .automatic
        screen.reloadNavigationItems()
        layout(window)
        XCTAssertGreaterThan(screen.header.expandedTitleHeight, 0)
        XCTAssertFalse(screen.header.largeTitleControl.isHidden)
        XCTAssertEqual(screen.header.largeTitleControl.accessibilityLabel, "Library")

        navigation.prefersLargeTitles = false
        content.navigationItem.largeTitleDisplayMode = .always
        screen.reloadNavigationItems()
        layout(window)
        XCTAssertEqual(screen.header.expandedTitleHeight, 0, "The navigation-wide preference gates per-item modes, like UIKit.")
        XCTAssertTrue(screen.header.largeTitleControl.isHidden)

        navigation.prefersLargeTitles = true
        content.navigationItem.largeTitleDisplayMode = .never
        screen.reloadNavigationItems()
        layout(window)
        XCTAssertEqual(screen.header.expandedTitleHeight, 0, accuracy: 0.5)
        XCTAssertTrue(screen.header.largeTitleControl.isHidden)
    }

    func testLargeTitleCollapseProgressClampsBounceMidpointAndPastCollapse() throws {
        let content = ScrollContentController()
        content.title = "Library"
        content.loadViewIfNeeded()
        content.navigationItem.largeTitleDisplayMode = .always
        let navigation = CustomNavigationController(contentViewController: content)
        navigation.prefersLargeTitles = true
        let screen = try XCTUnwrap(navigation.topViewController as? CustomNavigationViewController)
        screen.largeTitleScrollView = content.scrollView
        let window = host(navigation)
        defer { window.isHidden = true }
        screen.reloadNavigationItems()
        layout(window)

        let expansion = screen.header.expandedTitleHeight
        XCTAssertGreaterThan(expansion, 0)
        XCTAssertEqual(
            screen.contentLayoutGuide.layoutFrame.minY,
            screen.header.frame.minY + screen.header.customHeight,
            accuracy: 0.5,
            "The content guide stays anchored to the compact header; the scroll inset carries the expansion."
        )
        let top = -content.scrollView.adjustedContentInset.top

        setVerticalOffset(top - 40, on: content.scrollView, in: window)
        XCTAssertEqual(screen.header.largeTitleCollapseProgress, 0, accuracy: 0.01)

        setVerticalOffset(top + expansion / 2, on: content.scrollView, in: window)
        XCTAssertEqual(screen.header.largeTitleCollapseProgress, 0.5, accuracy: 0.05)

        setVerticalOffset(top + expansion + 40, on: content.scrollView, in: window)
        XCTAssertEqual(screen.header.largeTitleCollapseProgress, 1, accuracy: 0.01)
    }

    func testButtonLayoutUsesScreenOverrideAndSanitizesNonfiniteInputs() throws {
        let root = CustomNavigationViewController()
        root.title = "Title"
        let leading = button(title: "Left")
        let trailing = button(title: "Right")
        root.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leading)
        root.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: trailing)
        let navigation = CustomNavigationController(rootViewController: root)
        let window = host(navigation)
        defer { window.isHidden = true }
        root.reloadNavigationItems()
        layout(window)
        let originalLeading = leading.convert(leading.bounds, to: root.header)
        let originalTrailing = trailing.convert(trailing.bounds, to: root.header)
        root.buttonLayoutOverride = NavigationButtonLayout(leadingInset: 24, trailingInset: 10, verticalOffset: 3)
        layout(window)
        let movedLeading = leading.convert(leading.bounds, to: root.header)
        let movedTrailing = trailing.convert(trailing.bounds, to: root.header)
        XCTAssertEqual(movedLeading.minX - originalLeading.minX, 24, accuracy: 0.5)
        XCTAssertEqual(movedTrailing.maxX - originalTrailing.maxX, -10, accuracy: 0.5)
        XCTAssertEqual(movedLeading.midY - originalLeading.midY, 3, accuracy: 0.5)

        root.buttonLayoutOverride = NavigationButtonLayout(
            leadingInset: .nan,
            trailingInset: .infinity,
            verticalOffset: -.infinity
        )
        root.reloadNavigationItems()
        layout(window)

        for value in [
            root.header.backButton.frame.minX,
            root.header.backButton.frame.minY,
            root.header.backButton.frame.width,
            root.header.backButton.frame.height,
            root.header.titleControl.frame.minX,
            root.header.titleControl.frame.width
        ] {
            XCTAssertTrue(value.isFinite)
        }
        XCTAssertGreaterThanOrEqual(root.header.backButton.bounds.width, 44)
        XCTAssertGreaterThanOrEqual(root.header.backButton.bounds.height, 44)
    }

    private func button(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.frame.size = CGSize(width: 64, height: 44)
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }

    private func host(_ root: UIViewController) -> UIWindow {
        let window: UIWindow
        if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
            window = UIWindow(windowScene: scene)
        } else { window = UIWindow() }
        window.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
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

    private func setVerticalOffset(_ y: CGFloat, on scrollView: UIScrollView, in window: UIWindow) {
        scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x, y: y)
        layout(window)
    }
}

@MainActor
private final class ScrollContentController: UIViewController {
    let scrollView = UIScrollView()

    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        scrollView.contentSize = CGSize(width: 390, height: 2_000)
    }
}

@MainActor
private final class ScrollDelegate: NSObject, UIScrollViewDelegate {}
