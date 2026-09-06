import UIKit

/// UIKit's navigation stack and transitions, paired with app-owned headers.
open class CustomNavigationController: UINavigationController, UIGestureRecognizerDelegate {
    public var headerHeight: CGFloat = 66 { didSet { updateHeaders() } }
    public var headerBackgroundColor: UIColor = .systemBackground { didSet { updateHeaders() } }
    public var headerTintColor: UIColor = .label { didSet { updateHeaders() } }
    public var backButtonAccessibilityLabel = "Back" { didSet { updateHeaders() } }
    public var closeButtonAccessibilityLabel = "Close" { didSet { updateHeaders() } }
    public var hidesStatusBar = false { didSet { setNeedsStatusBarAppearanceUpdate() } }
    public var statusBarStyle: UIStatusBarStyle = .default { didSet { setNeedsStatusBarAppearanceUpdate() } }

    /// Start with an existing, unattached content controller. Header-capable screens are reused.
    public convenience init(contentViewController: UIViewController) {
        self.init(rootViewController: Self.screen(for: contentViewController))
    }

    /// Push an existing screen without changing its superclass. Returns the stack's header owner.
    @discardableResult
    public func pushContentViewController(_ content: UIViewController, animated: Bool = true) -> CustomNavigationViewController {
        let screen = Self.screen(for: content)
        pushViewController(screen, animated: animated)
        return screen
    }

    open override var prefersStatusBarHidden: Bool { hidesStatusBar }
    open override var childForStatusBarHidden: UIViewController? { nil }
    open override var preferredStatusBarStyle: UIStatusBarStyle { statusBarStyle }
    open override var childForStatusBarStyle: UIViewController? { nil }

    open override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationBarHidden(true, animated: false)
        // Preserve UIKit's target/action. Only the public admission gate is replaced.
        interactivePopGestureRecognizer?.delegate = self
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNavigationBarHidden(true, animated: false)
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === interactivePopGestureRecognizer else { return true }
        return viewControllers.count > 1 && transitionCoordinator == nil && presentedViewController == nil
    }

    private static func screen(for content: UIViewController) -> CustomNavigationViewController {
        if let screen = content as? CustomNavigationViewController { return screen }
        return CustomNavigationViewController(contentViewController: content)
    }

    private func updateHeaders() {
        for case let screen as CustomNavigationViewController in viewControllers where screen.isViewLoaded {
            screen.updateHeaderAppearance()
        }
    }
}
